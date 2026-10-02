import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../data/billing_repository.dart';
import '../models/entitlements.dart';

/// The shop's entitlements snapshot, shared across the billing banner, the
/// manage-plan screen, and the create-button gates.
///
/// An [AsyncNotifier] with a `refresh()` like the rest of the app's notifiers,
/// so any screen can re-pull after a checkout, a create, or a pull-to-refresh.
/// Registered in [AuthStateNotifier]'s per-tenant cache clear so one shop's plan
/// state can never leak onto the next login (same discipline as the client /
/// order caches).
class EntitlementsNotifier extends AsyncNotifier<Entitlements> {
  @override
  Future<Entitlements> build() async {
    // Await the auth check via authStateProvider.future rather than sampling it
    // non-reactively. On a COLD START with a restored session the auth check is
    // async (it reads secure storage), so a plain `ref.read(...).valueOrNull`
    // here often sees a still-loading (null) auth and caches the logged-out
    // _starterFallback() for the whole session — which silently disabled the ad
    // system (both `promos_enabled` and `show_third_party_ads` derive from this
    // snapshot) until a manual refresh on the billing screen forced a refetch.
    // Watching `.future` waits for the resolved user and rebuilds if the
    // signed-in user changes. This is NOT a dependency cycle: AuthStateNotifier
    // never watches this provider — it only invalidates it imperatively in
    // _clearPerTenantCaches (login/register/logout), which is an imperative
    // rebuild trigger, not a dependency edge.
    final userId = (await ref.watch(authStateProvider.future))?.id;
    if (userId == null) {
      // No tenant — resolve to the free-Starter shape rather than throwing, so a
      // transient logged-out frame doesn't surface an error banner.
      return _starterFallback();
    }
    return ref.read(billingRepositoryProvider).entitlements();
  }

  /// Re-fetch. Call after a successful checkout/verify, or when a create may
  /// have moved a usage count.
  Future<void> refresh() async {
    state = const AsyncLoading<Entitlements>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).entitlements(),
    );
  }

  static Entitlements _starterFallback() => const Entitlements(
        planCode: 'starter',
        status: null,
        limits: PlanLimits(
          activeOrders: 30,
          clients: 50,
          employees: 1,
          customProcesses: false,
          customTemplates: false,
          analytics: false,
          documents: 'watermarked',
          workflowAssignment: false,
          video: false,
        ),
        usage: EntitlementUsage(activeOrders: 0, clients: 0, employees: 0),
        trialEnd: null,
        currentPeriodEnd: null,
        autoRenew: false,
        cardLast4: null,
        // Logged-out fallback fails CLOSED for both systems (AD_SYSTEM Phase 0):
        // no AdMob and no house ask until a real snapshot says otherwise.
        showThirdPartyAds: false,
        promosEnabled: false,
      );
}

final entitlementsProvider =
    AsyncNotifierProvider<EntitlementsNotifier, Entitlements>(
  EntitlementsNotifier.new,
);

/// The single AdMob switch every ad widget watches (AD_SYSTEM — Phase 0).
///
/// **Fails CLOSED**: while the entitlements snapshot is loading, unknown, or
/// errored, this resolves to `false`, so no AdMob is ever requested or shown
/// until the server has confirmed the shop is ad-eligible. Briefly withholding a
/// free-tier impression is far cheaper than flashing an ad at a shop that might
/// be paying. (This is the opposite of the quota gate, which fails OPEN so a
/// paying shop is never trapped.)
final adsEnabledProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).valueOrNull;
  return ent?.showThirdPartyAds ?? false;
});

/// Whether to ask `/me/promotions` for house promotions at all (AD_SYSTEM —
/// Phase 0). This is ONLY the global on/off — it deliberately does NOT filter by
/// plan or status. A paid shop still asks; the server decides per-campaign
/// whether one targets it (a house campaign's audience may include paid tiers,
/// e.g. an announcement). Defaults `false` on unknown/loading so a disabled or
/// not-yet-loaded snapshot simply doesn't ask.
final promosEnabledProvider = Provider<bool>((ref) {
  final ent = ref.watch(entitlementsProvider).valueOrNull;
  return ent?.promosEnabled ?? false;
});
