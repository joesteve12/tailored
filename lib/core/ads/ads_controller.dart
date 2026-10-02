import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/billing/state/entitlements_notifier.dart';
import 'ads_service.dart';

/// Bridges ad **eligibility** to AdMob **bring-up** (AD_SYSTEM Phase A1).
///
/// Watches [adsEnabledProvider] (server-authoritative, fails CLOSED) and calls
/// [AdsService.ensureInitialized] the first time the shop is confirmed
/// ad-eligible. This is the reason a paying shop never triggers consent, SDK
/// init, or a single ad request: until the snapshot says the shop is a Starter
/// or is trialing, `adsEnabled` is `false` and this controller does nothing.
///
/// Read once from [TailoredApp.build] to pin it alive for the app's lifetime —
/// the same pattern as [reminderReconcilerProvider]. Init runs at most once
/// (the service is idempotent); flipping back to ineligible on an upgrade simply
/// stops future ad *requests* (the ad widgets watch [adsEnabledProvider] and
/// hide), it does not need to "de-initialise" the SDK.
final adsControllerProvider = Provider<AdsController>((ref) {
  final controller = AdsController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class AdsController {
  AdsController(this._ref) {
    _init();
  }

  final Ref _ref;
  ProviderSubscription<bool>? _sub;
  bool _started = false;

  void _init() {
    // google_mobile_ads has no Flutter web support (ADMOB_INTEGRATION.md §5).
    // On web we never listen — the web build shows no ads, by design.
    if (kIsWeb) return;

    _sub = _ref.listen<bool>(
      adsEnabledProvider,
      (_, eligible) {
        if (eligible && !_started) {
          _started = true;
          // Fire-and-forget: the service serialises consent + init internally
          // and is safe to call from here. Errors are handled/logged inside.
          _ref.read(adsServiceProvider).ensureInitialized();
        }
      },
      fireImmediately: true,
    );
  }

  void dispose() {
    _sub?.close();
    _sub = null;
  }
}
