import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/ads/ad_config.dart';
import '../../../core/ads/ads_service.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../../core/ads/native_ad_card.dart';
import '../../../core/ads/native_ad_in_list.dart';
import '../../billing/state/entitlements_notifier.dart';

/// DEV-ONLY scratch screen to verify the AdMob bring-up (AD_SYSTEM Phase A1).
///
/// Not part of the product flow. It surfaces the pieces A1 delivers so a human
/// can confirm them by eye: server ad-eligibility, the UMP consent state, SDK
/// init, and — only when eligible + initialised — an actual **test** banner
/// loading. Reachable at `/dev/ads` (a debug-only tile is added to the More
/// tab). Delete or hide the route before a public release.
class AdsDebugScreen extends ConsumerStatefulWidget {
  const AdsDebugScreen({super.key});

  @override
  ConsumerState<AdsDebugScreen> createState() => _AdsDebugScreenState();
}

class _AdsDebugScreenState extends ConsumerState<AdsDebugScreen> {
  ConsentStatus? _consentStatus;
  bool? _canRequestAds;
  bool _useRealUnit = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final service = ref.read(adsServiceProvider);
    final status = await service.consentStatus();
    final canRequest = await service.canRequestAds();
    if (!mounted) return;
    setState(() {
      _consentStatus = status;
      _canRequestAds = canRequest;
    });
  }

  Future<void> _initNow() async {
    await ref.read(adsServiceProvider).ensureInitialized();
    await _refreshStatus();
  }

  Future<void> _resetConsent() async {
    await ref.read(adsServiceProvider).resetConsentForTesting();
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final adsEligible = ref.watch(adsEnabledProvider);
    final ent = ref.watch(entitlementsProvider).valueOrNull;
    final service = ref.read(adsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ads debug (dev)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusTile(
            label: 'Server ad-eligible (adsEnabledProvider)',
            value: adsEligible.toString(),
            good: adsEligible,
          ),
          _StatusTile(
            label: 'showThirdPartyAds (snapshot)',
            value: ent?.showThirdPartyAds.toString() ?? '— (loading/unknown)',
          ),
          _StatusTile(
            label: 'plan / status',
            value: '${ent?.planCode ?? '—'} / ${ent?.status ?? '—'}',
          ),
          const Divider(height: 32),
          _StatusTile(
            label: 'SDK initialised',
            value: service.isInitialized.toString(),
            good: service.isInitialized,
          ),
          _StatusTile(
            label: 'UMP consent status',
            value: _consentStatus?.name ?? '…',
          ),
          _StatusTile(
            label: 'canRequestAds',
            value: _canRequestAds?.toString() ?? '…',
          ),
          _StatusTile(
            label: 'Test device registered',
            value: service.hasTestDevice
                ? service.testDeviceIds.join(', ')
                : 'no (real-unit test disabled)',
            good: service.hasTestDevice,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _initNow,
                child: const Text('Gather consent + init'),
              ),
              OutlinedButton(
                onPressed: _resetConsent,
                child: const Text('Reset consent (test)'),
              ),
              TextButton(
                onPressed: _refreshStatus,
                child: const Text('Refresh status'),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Test banner', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Toggle: load the REAL banner unit instead of the Google test unit.
          // Only enabled when a test device is registered AND a real unit exists
          // — otherwise loading the real unit would request genuine ads and a
          // stray tap would be invalid traffic. Structurally locked, not a
          // warning you can click past.
          if (_canUseRealUnit(service))
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Load REAL banner unit'),
              subtitle: Text(
                'Serves test creatives via ${AdConfig.realBannerUnitId} '
                '(safe: your device is a registered test device).',
              ),
              value: _useRealUnit,
              onChanged: (v) => setState(() => _useRealUnit = v),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                AdConfig.realBannerUnitId.isEmpty
                    ? 'Real banner unit not configured yet — showing the Google '
                        'test unit.'
                    : 'Register a test device (--dart-define=AD_TEST_DEVICE_ID=…) '
                        'to safely load the REAL unit. Showing the Google test '
                        'unit for now.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          if (!adsEligible)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Not ad-eligible — no ad is requested (fails closed). Paid shops '
                'and not-yet-loaded snapshots land here.',
              ),
            )
          else if (!service.isInitialized)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('SDK not initialised yet — tap "Gather consent + init".'),
            )
          else
            _TestBanner(
              // Keyed by unit id so flipping the toggle rebuilds/reloads.
              key: ValueKey(_bannerUnitId(service)),
              unitId: _bannerUnitId(service),
            ),
          const Divider(height: 32),
          Text(
            'Interstitial (A3)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Real trigger: close a detail screen back to a tab root, past the '
            'caps (≥30s from launch, ≥4 min apart, ≤3/day, ≥3 navigations). '
            'These buttons bypass the caps so you can verify the ad renders.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _StatusTile(
            label: 'Interstitial preloaded',
            value: ref.read(interstitialAdManagerProvider).isAdReady.toString(),
            good: ref.read(interstitialAdManagerProvider).isAdReady,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: adsEligible
                    ? () async {
                        await ref
                            .read(interstitialAdManagerProvider)
                            .debugPreload();
                        if (mounted) setState(() {});
                      }
                    : null,
                child: const Text('Preload interstitial'),
              ),
              FilledButton(
                onPressed: adsEligible
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final shown = await ref
                            .read(interstitialAdManagerProvider)
                            .debugForceShow();
                        if (!mounted) return;
                        if (!shown) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No interstitial ready — tap Preload first.',
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      }
                    : null,
                child: const Text('Force-show interstitial'),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Native advanced (A4)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'DINKEE-themed native card (medium template) — carries the required '
            '"Ad" badge + AdChoices. In a real feed it injects once into a long '
            '(≥$kNativeAdMinItems item) Orders/Customers list and yields to any '
            'house promo. Here it renders directly for eligible shops.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (!adsEligible)
            const Text(
              'Not ad-eligible — no native ad is requested (fails closed).',
            )
          else
            const NativeAdCard(),
        ],
      ),
    );
  }

  bool _canUseRealUnit(AdsService service) =>
      service.hasTestDevice && AdConfig.realBannerUnitId.isNotEmpty;

  String _bannerUnitId(AdsService service) =>
      (_useRealUnit && _canUseRealUnit(service))
          ? AdConfig.realBannerUnitId
          : AdConfig.bannerUnitId;
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value, this.good});

  final String label;
  final String value;
  final bool? good;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = good == null
        ? null
        : (good! ? scheme.primary : scheme.error);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// A minimal fixed-size test banner, just to prove the SDK renders an ad. The
/// real adaptive-anchored banner mounted in the app shell is Phase A2 — this is
/// deliberately a throwaway smoke test, not that widget.
class _TestBanner extends ConsumerStatefulWidget {
  const _TestBanner({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<_TestBanner> createState() => _TestBannerState();
}

class _TestBannerState extends ConsumerState<_TestBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: widget.unitId,
      size: AdSize.banner,
      request: ref.read(adsServiceProvider).buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _error = error.message);
        },
      ),
    );
    _banner = ad;
    ad.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text('Banner failed to load: $_error');
    }
    if (!_loaded || _banner == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Loading test banner…'),
      );
    }
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
