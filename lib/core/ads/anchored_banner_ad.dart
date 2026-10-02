import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/billing/state/entitlements_notifier.dart';
import 'ad_config.dart';
import 'ads_service.dart';

/// The persistent anchored **adaptive** banner mounted in the app shell,
/// above the bottom `NavigationBar` / at the bottom of the body column on
/// `NavigationRail` layouts (AD_SYSTEM Phase A2 — see `ADMOB_INTEGRATION.md`
/// §3, §5).
///
/// Gates on [adsEnabledProvider] (server-authoritative, fails **closed**) —
/// collapses to [SizedBox.shrink] for a paid shop, an unresolved snapshot, or
/// web (`google_mobile_ads` has no Flutter web support), so the shell reflows
/// cleanly with no reserved gap. Sized via
/// `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize`, which fits the
/// device's current width.
///
/// **Retries on load failure.** The first ad request right after a cold app
/// start is the one most likely to fail — the native Mobile Ads SDK / Play
/// Services can still be warming up even after `initialize()`'s callback has
/// fired — and Google's own guidance is to retry with backoff rather than
/// give up. A capped exponential backoff (§ [_retryDelay]) drives that; a hot
/// restart "fixing" a blank banner was this widget failing once and never
/// trying again.
class AnchoredBannerAd extends ConsumerStatefulWidget {
  const AnchoredBannerAd({super.key});

  @override
  ConsumerState<AnchoredBannerAd> createState() => _AnchoredBannerAdState();
}

class _AnchoredBannerAdState extends ConsumerState<AnchoredBannerAd> {
  BannerAd? _banner;
  AnchoredAdaptiveBannerAdSize? _adSize;
  int? _loadedWidth;

  // The width we currently want a banner loaded for, set synchronously from
  // every build. A running load loop re-reads this after each attempt (incl.
  // after a retry delay), so a width that changes mid-flight — or simply a
  // build the loop wasn't watching for — is never silently dropped.
  int? _pendingWidth;
  bool _loopRunning = false;
  int _retryAttempt = 0;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  void _resetAd() {
    final old = _banner;
    if (old == null) return;
    setState(() {
      _banner = null;
      _adSize = null;
      _loadedWidth = null;
    });
    old.dispose();
  }

  void _requestLoad(int width) {
    // Already showing a banner sized for this exact width — nothing to do.
    // Without this guard, every rebuild (a banner is a live platform view, so
    // there are many) would spawn a throwaway load-loop; it would issue no ad
    // request, but it's needless churn. Only a genuinely new/changed width or
    // a not-yet-loaded state gets past here.
    if (width == _loadedWidth && _banner != null) return;
    _pendingWidth = width;
    if (_loopRunning) return; // the running loop will pick this width up next
    _loopRunning = true;
    unawaited(_runLoop());
  }

  Future<void> _runLoop() async {
    try {
      while (mounted &&
          ref.read(adsEnabledProvider) &&
          _pendingWidth != null &&
          _pendingWidth != _loadedWidth) {
        final width = _pendingWidth!;
        final ok = await _attemptLoad(width);
        if (!mounted || !ref.read(adsEnabledProvider)) return;
        if (!ok && _pendingWidth == width) {
          // Same width still wanted and the attempt failed (or the SDK
          // wasn't ready yet) — back off before the loop retries it.
          _retryAttempt++;
          await Future<void>.delayed(_retryDelay(_retryAttempt));
        } else if (ok) {
          _retryAttempt = 0;
        }
      }
    } finally {
      _loopRunning = false;
    }
  }

  /// Capped exponential backoff: 2s, 4s, 8s, 16s, 32s, then holds at 60s.
  /// Mirrors Google's own AdMob retry guidance — never hammer a cold SDK.
  Duration _retryDelay(int attempt) {
    final exponent = math.min(attempt - 1, 5);
    final seconds = math.min(2 << exponent, 60); // 2,4,8,16,32,64→capped
    return Duration(seconds: seconds);
  }

  /// One load attempt for [width]. Returns true on success (a banner is now
  /// showing or was superseded before it could show — either way, not a
  /// failure worth retrying), false if it should be retried.
  Future<bool> _attemptLoad(int width) async {
    final service = ref.read(adsServiceProvider);
    // Idempotent — a no-op if AdsController already brought the SDK up.
    await service.ensureInitialized();
    if (!mounted || !ref.read(adsEnabledProvider)) return true;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || !ref.read(adsEnabledProvider)) return true;
    if (size == null) return false; // transient — worth retrying

    final unitId = AdConfig.adaptiveBannerUnitId;
    if (unitId.isEmpty) {
      // No real unit configured yet for this platform/build — fail-safe, no
      // ad, and not worth retrying (won't change until a release).
      return true;
    }

    final completer = Completer<BannerAd?>();
    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: service.buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!completer.isCompleted) completer.complete(loadedAd as BannerAd);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint(
            '[ads] anchored banner failed to load (will retry): $error',
          );
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    await ad.load();
    final loaded = await completer.future;
    if (loaded == null) return false; // failed — retry

    // Loaded, but by the time it arrived either a newer width superseded
    // this one or the shop stopped being eligible — discard rather than show
    // a stale/mis-sized/ineligible ad. Not a failure, so don't retry.
    if (!mounted || !ref.read(adsEnabledProvider) || _pendingWidth != width) {
      loaded.dispose();
      return true;
    }

    final previous = _banner;
    setState(() {
      _banner = loaded;
      _adSize = size;
      _loadedWidth = width;
    });
    previous?.dispose();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final eligible = ref.watch(adsEnabledProvider);

    if (kIsWeb || !eligible) {
      if (_banner != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetAd();
        });
      }
      _pendingWidth = null;
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0) {
      _requestLoad(width);
    }

    if (_banner == null || _loadedWidth != width) {
      // Either nothing has loaded yet (or is retrying), or a resize just
      // invalidated the banner we're about to reload — collapse rather than
      // show a stale or mis-sized ad while the new one loads.
      return const SizedBox.shrink();
    }

    return _bannerBox();
  }

  Widget _bannerBox() {
    return SizedBox(
      width: _adSize!.width.toDouble(),
      height: _adSize!.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
