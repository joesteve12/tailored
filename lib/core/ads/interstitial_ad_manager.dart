import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/billing/state/entitlements_notifier.dart';
import '../../features/tasks/tasks_paths.dart';
import 'ad_config.dart';
import 'ads_service.dart';

/// The five bottom-nav tab roots. Interstitials only ever show when the user
/// lands back on one of these — never on a detail/form/checkout/document
/// screen (those are top-level routes pushed *over* the shell, so their
/// `matchedLocation` is never in this set). That's the structural "never
/// mid-task" guarantee: there is no code path that shows an interstitial while
/// a create/checkout/document flow is on screen.
const Set<String> _tabRootPaths = {
  '/home',
  '/orders',
  tasksTabPath, // '/tasks'
  '/clients',
  '/settings',
};

/// Owns the preloaded interstitial and the frequency-cap bookkeeping
/// (AD_SYSTEM Phase A3 — see `ADMOB_INTEGRATION.md` §3, §4).
///
/// **Triggers (all "natural stops", all subject to the same caps below):**
///  * the user closing a detail screen and landing back on a tab root
///    (router-location listener — tab *switches* root→root don't count, and
///    mid-task screens never qualify);
///  * an explicit "task complete" event via [notifyTaskComplete] — e.g. right
///    after successfully creating an order/client/guest/task/employee, called
///    *after* the success navigation so it never overlays the form;
///  * app foreground after a cool-down ([_resumeCooldown]) — a warm resume,
///    never a cold start.
///
/// A defensive [_isForbiddenNow] guard means even an explicit trigger refuses
/// to show while the current screen is a form/checkout/auth surface.
///
/// **Caps (all must pass):**
///  * ≥ [_minSinceLaunch] since cold start (no ad the instant the app opens),
///  * ≥ [_minGapBetweenAds] since the last interstitial,
///  * ≤ [_maxPerDay] shown per calendar day,
///  * ≥ [_minNavsBetweenAds] screen navigations since the last one,
///  * a preloaded ad is ready (a slow full-screen ad is worse than none — if
///    none is ready we preload for *next* time instead of blocking now).
///
/// The daily count and last-shown timestamp persist in [SharedPreferences] so
/// the caps survive an app restart; the navigation counter is per-session
/// (the launch cap covers a fresh process). Gated on [adsEnabledProvider]
/// (server-authoritative, fails **closed**) at every decision point, so a paid
/// shop — or an unresolved snapshot — never loads or shows an interstitial.
class InterstitialAdManager with WidgetsBindingObserver {
  InterstitialAdManager(this._ref) {
    _appStart = DateTime.now();
    // Web has no google_mobile_ads support; never listen or load there.
    if (kIsWeb) return;
    // Preload as soon as the shop is confirmed ad-eligible; drop the ad the
    // moment it stops being eligible (e.g. an upgrade mid-session).
    _eligibilitySub = _ref.listen<bool>(
      adsEnabledProvider,
      (_, eligible) {
        if (eligible) {
          _ensureLoaded();
        } else {
          _disposeAd();
        }
      },
      fireImmediately: true,
    );
    // Observe app lifecycle for the "foreground after a cool-down" trigger
    // (ADMOB_INTEGRATION.md §3).
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  late final DateTime _appStart;
  ProviderSubscription<bool>? _eligibilitySub;

  GoRouter? _router;
  VoidCallback? _routerListener;
  String? _lastLocation;

  InterstitialAd? _ad;
  bool _loading = false;
  int _navCount = 0;
  int _navCountAtLastAd = 0;

  // Warm-resume trigger: only offer an ad on foreground if the app was in the
  // background at least this long (a genuine "came back later", not a quick
  // app-switch). Cold start is excluded because _backgroundedAt starts null.
  DateTime? _backgroundedAt;

  // ---- Cap constants (ADMOB_INTEGRATION.md §4) -----------------------------
  static const Duration _minSinceLaunch = Duration(seconds: 30);
  static const Duration _minGapBetweenAds = Duration(minutes: 4);
  static const int _maxPerDay = 3;
  static const int _minNavsBetweenAds = 3;
  // How long the app must have been backgrounded before a resume can show an
  // interstitial (the "cool-down"). The 4-min inter-ad gap + 3/day cap still
  // apply on top, so this only shapes *when* a resume qualifies at all.
  static const Duration _resumeCooldown = Duration(minutes: 1);

  static const String _kLastShownMs = 'interstitial_last_shown_ms';
  static const String _kCountDay = 'interstitial_count_day';
  static const String _kCountValue = 'interstitial_count_value';

  /// Wire the manager to the router so it can detect "returned to a tab root".
  /// Called once from the router provider after the [GoRouter] is built.
  void attachRouter(GoRouter router) {
    if (kIsWeb || _router != null) return;
    _router = router;
    void listener() => _onRouterChanged();
    _routerListener = listener;
    router.routerDelegate.addListener(listener);
    // The router may not have resolved its initial route yet at attach time;
    // reading state then can throw. Leave _lastLocation null — the first
    // notification seeds it, and the launch cap prevents any early show.
    _lastLocation = _currentLocation();
  }

  String? _currentLocation() {
    try {
      return _router?.state.matchedLocation;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    final listener = _routerListener;
    if (listener != null) {
      _router?.routerDelegate.removeListener(listener);
    }
    _routerListener = null;
    _eligibilitySub?.close();
    _eligibilitySub = null;
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    _disposeAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      // Only a genuine "came back after a while" resume qualifies — never a
      // cold start (since == null) or a momentary app-switch. _maybeShow then
      // applies all the usual caps + the forbidden-screen guard on top.
      if (since != null &&
          DateTime.now().difference(since) >= _resumeCooldown) {
        _maybeShow();
      }
    }
  }

  void _onRouterChanged() {
    final loc = _currentLocation();
    if (loc == null) return;
    final was = _lastLocation;
    if (loc == was) return;
    _lastLocation = loc;
    _navCount++;
    // A tab root reached from something that wasn't a tab root = the user
    // closed a detail screen and landed home. Tab→tab switches don't qualify.
    if (_isTabRoot(loc) && (was == null || !_isTabRoot(was))) {
      _maybeShow();
    }
  }

  bool _isTabRoot(String location) => _tabRootPaths.contains(location);

  /// Offer an interstitial at an explicit "task complete" natural stop — e.g.
  /// right after a shop successfully creates an order (AD_SYSTEM Phase A3).
  ///
  /// Subject to the exact same eligibility + frequency caps as the automatic
  /// tab-root trigger, so it can be called freely; it self-suppresses when a
  /// cap or eligibility says no. **Call it AFTER the success navigation** (the
  /// pop that closes the form) so the ad overlays a stable, non-task screen —
  /// never the form itself. As a defensive backstop the manager also refuses
  /// to show while the current screen looks like a form/checkout/auth surface
  /// ([_isForbiddenNow]).
  void notifyTaskComplete() => _maybeShow();

  /// Screens an interstitial must NEVER overlay, even via an explicit trigger
  /// (LOCKED guardrail: no ads on create/edit forms, checkout, or auth). A
  /// defensive check on the *current* location; the primary guarantee is that
  /// callers only fire this after navigating off such a screen.
  bool _isForbiddenNow() {
    final loc = _currentLocation();
    if (loc == null) return true; // unknown → fail closed
    if (loc == '/login' || loc == '/register' || loc == '/complete-profile') {
      return true;
    }
    if (loc.contains('/checkout')) return true;
    if (loc.endsWith('/new') || loc.endsWith('/edit')) return true;
    return false;
  }

  Future<void> _maybeShow() async {
    if (kIsWeb || !_ref.read(adsEnabledProvider)) return; // fail closed
    if (_isForbiddenNow()) return; // never over a form/checkout/auth screen
    if (DateTime.now().difference(_appStart) < _minSinceLaunch) return;

    // Not preloaded yet — get one ready for the *next* natural stop rather
    // than making the user wait on a full-screen load now.
    if (_ad == null) {
      _ensureLoaded();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Re-check after the async gap.
    if (!_eligible || _ad == null) return;
    final now = DateTime.now();

    final lastShownMs = prefs.getInt(_kLastShownMs);
    if (lastShownMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs)) <
            _minGapBetweenAds) {
      return;
    }

    final today = _dayKey(now);
    final storedDay = prefs.getString(_kCountDay);
    final shownToday =
        storedDay == today ? (prefs.getInt(_kCountValue) ?? 0) : 0;
    if (shownToday >= _maxPerDay) return;

    if (_navCount - _navCountAtLastAd < _minNavsBetweenAds) return;

    await _show(prefs, now, today, shownToday);
  }

  bool get _eligible => !kIsWeb && _ref.read(adsEnabledProvider);

  Future<void> _show(
    SharedPreferences prefs,
    DateTime now,
    String today,
    int shownToday,
  ) async {
    final ad = _ad;
    if (ad == null || !_eligible) return;
    _ad = null; // hand ownership to the show flow

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ensureLoaded(); // preload the next one immediately
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[ads] interstitial failed to show: $error');
        ad.dispose();
        _ensureLoaded();
      },
    );

    // Record the cap state BEFORE show() — an interstitial that's begun
    // presenting counts, even if the app is backgrounded during it.
    _navCountAtLastAd = _navCount;
    await prefs.setInt(_kLastShownMs, now.millisecondsSinceEpoch);
    await prefs.setString(_kCountDay, today);
    await prefs.setInt(_kCountValue, shownToday + 1);

    await ad.show();
  }

  Future<void> _ensureLoaded() async {
    if (kIsWeb || _loading || _ad != null) return;
    if (!_ref.read(adsEnabledProvider)) return;

    final unitId = AdConfig.interstitialUnitId;
    if (unitId.isEmpty) return; // no real unit yet (release) → fail-safe, no ad

    _loading = true;
    final service = _ref.read(adsServiceProvider);
    await service.ensureInitialized(); // idempotent
    if (!_ref.read(adsEnabledProvider)) {
      _loading = false;
      return;
    }

    await InterstitialAd.load(
      adUnitId: unitId,
      request: service.buildAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          // Eligibility may have flipped off while loading — discard.
          if (kIsWeb || !_ref.read(adsEnabledProvider)) {
            ad.dispose();
            return;
          }
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          // No tight retry loop — the next tab-root return re-requests.
          debugPrint('[ads] interstitial failed to load: $error');
        },
      ),
    );
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
  }

  // ---- Dev/debug affordances (used only by the dev Ads screen) -------------

  /// True when an interstitial is preloaded and ready to show.
  bool get isAdReady => _ad != null;

  /// Kick a preload on demand (the dev screen's "Preload" button). No-op if
  /// ineligible, already loading, or already loaded.
  Future<void> debugPreload() => _ensureLoaded();

  /// Show the preloaded interstitial **ignoring the frequency caps** — for the
  /// dev screen only, so a human can verify the ad renders without waiting out
  /// the 30s/4-min/3-nav gates. Still honors eligibility and only shows a
  /// genuinely loaded ad; still records the cap state so real gating resumes
  /// afterward. Returns false if nothing was shown.
  Future<bool> debugForceShow() async {
    if (!_eligible || _ad == null) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!_eligible || _ad == null) return false;
    final now = DateTime.now();
    final today = _dayKey(now);
    final storedDay = prefs.getString(_kCountDay);
    final shownToday =
        storedDay == today ? (prefs.getInt(_kCountValue) ?? 0) : 0;
    await _show(prefs, now, today, shownToday);
    return true;
  }

  String _dayKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// The app's single [InterstitialAdManager]. Pinned alive for the app lifetime
/// (watched once in `main.dart`, like [adsControllerProvider]); the router
/// provider calls [InterstitialAdManager.attachRouter] on it once the router
/// exists.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager(ref);
  ref.onDispose(manager.dispose);
  return manager;
});
