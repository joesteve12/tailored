import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob unit IDs, split by build mode and platform (AD_SYSTEM Phase A1 — see
/// ADMOB_INTEGRATION.md §5).
///
/// **Debug/profile builds serve Google's public TEST unit IDs**; only a release
/// build uses the real account units. This split is deliberate and load-bearing:
///
///  * Requesting REAL ads in a debug build (developers tapping their own ads)
///    is an AdMob policy violation that can get the account struck.
///  * Shipping TEST units to production serves no real ads (zero revenue).
///
/// So we never hardcode one set for both. Unit IDs are not secret (they ship in
/// every APK), so they live in source, not `.env` — but the test/real split is
/// keyed on [kReleaseMode] so it can never be got wrong by forgetting a flag.
///
/// The AdMob **App ID** is a separate thing and lives in the platform manifests
/// (AndroidManifest.xml / iOS Info.plist), not here — see the manifest TODO.
class AdConfig {
  const AdConfig._();

  // ---- Google's public sample TEST unit IDs (safe in debug) ----------------
  // Source: https://developers.google.com/admob/flutter/test-ads.
  // Fixed 320x50 banner demo units — used by the A1 dev scratch banner
  // (AdSize.banner is a fixed size).
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  // Anchored ADAPTIVE banner demo units — A2 mounts an anchored adaptive banner
  // in the shell, which Google serves from a distinct demo unit (not the fixed
  // one above). Ready now so A2 doesn't have to look them up.
  // Source: developers.google.com/admob/{android,ios}/test-ads.
  static const String _testAdaptiveBannerAndroid =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _testAdaptiveBannerIos =
      'ca-app-pub-3940256099942544/2435281174';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  // ---- Real production unit IDs (release only) -----------------------------
  // Real units from the Dinkee AdMob account (app ...~9277364377). Empty ones
  // aren't created yet: a release build requesting an empty unit simply shows
  // nothing — the correct fail-safe until they're filled in.
  // TODO(A3/A4): create the Interstitial + Native advanced units in the AdMob
  // console and paste their IDs below.
  static const String _realBannerAndroid = 'ca-app-pub-6157645724547288/2328707443';
  static const String _realBannerIos = '';
  static const String _realInterstitialAndroid = '';
  static const String _realInterstitialIos = '';
  static const String _realNativeAndroid = '';
  static const String _realNativeIos = '';

  /// The REAL banner unit, regardless of build mode. Use ONLY to verify the real
  /// unit is wired, and ONLY with your device registered as a test device (so it
  /// serves test creatives, not real ones). Empty string if no real unit exists
  /// for this platform yet. See the dev Ads-debug screen.
  static String get realBannerUnitId => _isIos ? _realBannerIos : _realBannerAndroid;

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// Anchored/adaptive banner unit (A2 mounts it in the shell; A1 uses it on
  /// the dev scratch screen to prove the SDK loads a test ad).
  static String get bannerUnitId {
    if (kReleaseMode) return _isIos ? _realBannerIos : _realBannerAndroid;
    return _isIos ? _testBannerIos : _testBannerAndroid;
  }

  /// Anchored ADAPTIVE banner unit (A2, mounted in the shell). In debug this is
  /// the adaptive demo unit; in release it's the real banner unit (a real AdMob
  /// banner unit is not size-locked — it serves fixed and adaptive alike).
  static String get adaptiveBannerUnitId {
    if (kReleaseMode) return _isIos ? _realBannerIos : _realBannerAndroid;
    return _isIos ? _testAdaptiveBannerIos : _testAdaptiveBannerAndroid;
  }

  /// Interstitial unit (A3).
  static String get interstitialUnitId {
    if (kReleaseMode) {
      return _isIos ? _realInterstitialIos : _realInterstitialAndroid;
    }
    return _isIos ? _testInterstitialIos : _testInterstitialAndroid;
  }

  /// Native advanced unit (A4).
  static String get nativeUnitId {
    if (kReleaseMode) return _isIos ? _realNativeIos : _realNativeAndroid;
    return _isIos ? _testNativeIos : _testNativeAndroid;
  }
}
