import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/billing/state/entitlements_notifier.dart';
import '../theme/app_tokens.dart';
import 'ad_config.dart';
import 'ads_service.dart';

/// A DINKEE-themed AdMob **native advanced** card, for injection into long
/// scrollable feeds (AD_SYSTEM Phase A4 — see `ADMOB_INTEGRATION.md` §3, §5).
///
/// Gates on [adsEnabledProvider] (server-authoritative, fails **closed**) — a
/// paid shop, an unresolved snapshot, or web (`google_mobile_ads` has no Flutter
/// web support) all collapse to [SizedBox.shrink], so an injected row takes zero
/// space until (and unless) a real ad loads. No layout gap is ever reserved for
/// a promo that isn't there.
///
/// **Rendered via a Flutter native template** ([NativeTemplateStyle], not a
/// registered platform `NativeAdFactory`), so — like the rest of Track A — this
/// needs no Kotlin/Swift. The template is themed to the app's tokens
/// (`context.appTokens` + the color scheme): terracotta call-to-action, card
/// surface background, [AppTokens.radiusLg] corners. The template renders the
/// mandatory **"Ad" badge + AdChoices** attribution itself (AdMob policy — §6);
/// that chrome is not ours to remove.
///
/// The one thing a template cannot theme is the font *family* (Fraunces): the
/// SDK exposes only weight/italic on template text, so the card uses the
/// device's default face for the ad's own copy. That is an accepted limitation
/// of the no-native-code template path vs. a full custom factory.
///
/// **Retries on load failure** with capped exponential backoff, mirroring
/// [AnchoredBannerAd] (A2): the first request right after a cold start is the
/// one most likely to miss while Play Services is still warming, and Google's
/// guidance is to retry rather than give up. Colors depend on the active theme,
/// which the template bakes in at load time, so a light/dark switch reloads the
/// card at the new palette.
class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key, this.height = 340});

  /// Fixed height the loaded medium template occupies. The template's own
  /// intrinsic layout drives its content; this bounds the platform view in the
  /// list. Tunable if the template clips on a given device.
  final double height;

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _ad;
  bool _loading = false;
  int _retryAttempt = 0;
  Brightness? _loadedBrightness;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loadedBrightness = null;
  }

  void _requestLoad(NativeTemplateStyle style, Brightness brightness) {
    // Already showing a card built for this exact theme — nothing to do. A
    // native ad is a live platform view (many rebuilds); without this guard
    // each would spawn a throwaway load loop.
    if (_ad != null && _loadedBrightness == brightness) return;
    if (_loading) return; // a running loop will re-check the theme when it ends
    _loading = true;
    _retryAttempt = 0;
    unawaited(_runLoop(style, brightness));
  }

  Future<void> _runLoop(NativeTemplateStyle style, Brightness brightness) async {
    try {
      while (mounted && ref.read(adsEnabledProvider)) {
        final ok = await _attemptLoad(style, brightness);
        if (!mounted || !ref.read(adsEnabledProvider)) return;
        if (ok) {
          _retryAttempt = 0;
          return; // loaded, or a fail-safe no-op — either way, stop.
        }
        _retryAttempt++;
        await Future<void>.delayed(_retryDelay(_retryAttempt));
      }
    } finally {
      _loading = false;
    }
  }

  /// Capped exponential backoff: 2s, 4s, 8s, 16s, 32s, then holds at 60s —
  /// the same posture as the anchored banner. Never hammer a cold SDK.
  Duration _retryDelay(int attempt) {
    final exponent = math.min(attempt - 1, 5);
    return Duration(seconds: math.min(2 << exponent, 60));
  }

  /// One load attempt. Returns true when there is nothing left to retry (a card
  /// is showing, the shop became ineligible, or no unit is configured), false
  /// when the request failed and is worth retrying.
  Future<bool> _attemptLoad(
    NativeTemplateStyle style,
    Brightness brightness,
  ) async {
    final service = ref.read(adsServiceProvider);
    // Idempotent — a no-op if AdsController already brought the SDK up.
    await service.ensureInitialized();
    if (!mounted || !ref.read(adsEnabledProvider)) return true;

    final unitId = AdConfig.nativeUnitId;
    if (unitId.isEmpty) {
      // No real unit configured for this platform/build yet — fail-safe, no
      // request, and not worth retrying (won't change until a release).
      return true;
    }

    final completer = Completer<NativeAd?>();
    final ad = NativeAd(
      adUnitId: unitId,
      request: service.buildAdRequest(),
      nativeTemplateStyle: style,
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!completer.isCompleted) completer.complete(loadedAd as NativeAd);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint('[ads] native ad failed to load (will retry): $error');
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    await ad.load();
    final loaded = await completer.future;
    if (loaded == null) return false; // failed — retry

    // Loaded, but the shop may have upgraded (or the theme changed) while it
    // was in flight — discard rather than show an ineligible/stale-theme card.
    // Not a failure, so don't retry here; a theme change reloads via build().
    if (!mounted ||
        !ref.read(adsEnabledProvider) ||
        Theme.of(context).brightness != brightness) {
      loaded.dispose();
      return true;
    }

    final previous = _ad;
    setState(() {
      _ad = loaded;
      _loadedBrightness = brightness;
    });
    previous?.dispose();
    return true;
  }

  /// Theme the native template to the DINKEE tokens (§3). Colors come from the
  /// active scheme so the card reads as part of the app in both light and dark;
  /// the terracotta primary drives the call-to-action.
  NativeTemplateStyle _buildStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: scheme.surfaceContainerLow,
      cornerRadius: tokens.radiusLg,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface,
        style: NativeTemplateFontStyle.bold,
        size: 16,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: tokens.mutedForeground,
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: tokens.mutedForeground,
        size: 12,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligible = ref.watch(adsEnabledProvider);

    if (kIsWeb || !eligible) {
      if (_ad != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_disposeAd);
        });
      }
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    _requestLoad(_buildStyle(context), brightness);

    if (_ad == null || _loadedBrightness != brightness) {
      // Nothing loaded yet (or retrying / reloading for a new theme) — collapse
      // rather than reserve an empty gap in the feed.
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AdWidget(ad: _ad!),
    );
  }
}
