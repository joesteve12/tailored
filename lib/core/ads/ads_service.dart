import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Owns the one-time AdMob bring-up: gather user consent via the UMP SDK, then
/// initialise the Google Mobile Ads SDK (AD_SYSTEM Phase A1 — see
/// ADMOB_INTEGRATION.md §5, §6).
///
/// **Consent BEFORE initialise** is the load-bearing order: the app stores
/// tailors' client PII, so we gather a consent decision (UMP) first and only
/// then call `MobileAds.instance.initialize()`. Ad requests default to
/// **non-personalized** ([buildAdRequest]) — the privacy-preserving posture §6
/// recommends for a PII-heavy business tool.
///
/// This service does NOT decide *eligibility* — that's [adsEnabledProvider]
/// (fails closed). [AdsController] only ever calls [ensureInitialized] once the
/// server has confirmed the shop is ad-eligible, so a paying shop never triggers
/// consent, initialisation, or a single ad request.
class AdsService {
  AdsService();

  // Idempotency: [ensureInitialized] can be called from several places (the
  // controller on eligibility, the dev screen's button); it must do the real
  // work exactly once and every caller awaits the same future.
  Future<void>? _bringUp;
  bool _initialized = false;

  /// True once `MobileAds.instance.initialize()` has completed.
  bool get isInitialized => _initialized;

  /// Consent + init, run at most once. Safe to call repeatedly; later calls
  /// return the same in-flight/settled future.
  Future<void> ensureInitialized() => _bringUp ??= _bringUpOnce();

  /// Comma-separated hashed device ids passed at build time via
  /// `--dart-define=AD_TEST_DEVICE_ID=<hash>[,<hash>...]`. A registered device
  /// ALWAYS receives test creatives — even from real ad-unit IDs — so this is
  /// the safe way to verify real units without risking invalid-traffic strikes.
  static const String _testDeviceRaw = String.fromEnvironment('AD_TEST_DEVICE_ID');

  List<String> get testDeviceIds => _testDeviceRaw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  /// Whether at least one test device is registered — gates the dev screen's
  /// "load REAL unit" affordance so a real unit is never requested unprotected.
  bool get hasTestDevice => testDeviceIds.isNotEmpty;

  Future<void> _bringUpOnce() async {
    // Register test devices BEFORE any ad request so real units serve test ads
    // to us. Applied in debug and release alike (it's your own device you're
    // protecting). No-op when the dart-define is absent.
    if (hasTestDevice) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }

    try {
      await _gatherConsent();
    } catch (e) {
      // Consent is best-effort: a UMP failure (offline, form load error) must
      // not block ads for a shop that already had a valid prior consent, nor
      // crash the app. Fail-silent, exactly like the rest of the ad stack.
      debugPrint('[ads] consent gather failed (continuing): $e');
    }

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[ads] MobileAds initialize failed: $e');
      // Leave _bringUp set so we don't hammer a broken SDK on every rebuild;
      // _initialized stays false so no widget will request an ad.
    }
  }

  /// Run the UMP flow: refresh consent info, then show the consent form if the
  /// user's jurisdiction requires one. Bridges UMP's callback API to a Future.
  Future<void> _gatherConsent() {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      _consentParams(),
      () {
        // Info refreshed — show the form if (and only if) it's required.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) {
            debugPrint('[ads] consent form error: ${error.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        // Info refresh failed (e.g. offline). Don't block — a prior consent may
        // still allow ads; if not, canRequestAds() stays false and no ad loads.
        debugPrint('[ads] consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// In DEBUG builds, force the EEA consent geography so the UMP prompt actually
  /// appears while testing (outside the EEA, no form is required and none would
  /// show). Emulators/simulators are automatically test devices; a physical
  /// device must be registered by passing its hashed id via
  /// `--dart-define=UMP_TEST_DEVICE_ID=<hash>` (the SDK prints the hash to the
  /// device log on first run). Release builds pass plain parameters — real
  /// geography, real requirements.
  ConsentRequestParameters _consentParams() {
    if (kReleaseMode) return ConsentRequestParameters();

    const testDeviceId = String.fromEnvironment('UMP_TEST_DEVICE_ID');
    return ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: testDeviceId.isEmpty ? const [] : [testDeviceId],
      ),
    );
  }

  /// The privacy-preserving ad request every surface should use. Defaults to
  /// **non-personalized** ads given the sensitive-data context (§6): it costs
  /// some eCPM but avoids sending behavioural signals from a PII-heavy app.
  AdRequest buildAdRequest() => const AdRequest(nonPersonalizedAds: true);

  // ---- Introspection for the dev/debug screen ------------------------------

  /// Whether the SDK is allowed to request ads given the current consent state.
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  /// Current UMP consent status (unknown / required / notRequired / obtained).
  Future<ConsentStatus> consentStatus() =>
      ConsentInformation.instance.getConsentStatus();

  /// Wipe the stored consent decision so the UMP form can be re-tested. Debug
  /// affordance only — never call this in production flows.
  Future<void> resetConsentForTesting() async {
    ConsentInformation.instance.reset();
  }
}

/// The app's single [AdsService]. Non-autodispose so init state persists for the
/// app's lifetime.
final adsServiceProvider = Provider<AdsService>((ref) => AdsService());
