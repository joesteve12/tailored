import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/billing_responses.dart';
import '../models/entitlements.dart';

/// The single HTTP surface for billing (Phase 6). Talks to the read-only
/// entitlements endpoint and the three billing endpoints from Phase 4/4B:
/// checkout, verify-on-return, and auto-renew opt-out.
///
/// dioProvider's baseUrl already ends in /api/v1 — paths here are relative to
/// that, matching the other repositories.
class BillingRepository {
  BillingRepository(this._dio);

  final Dio _dio;

  /// The shop's resolved plan, limits, usage, and billing-clock state.
  Future<Entitlements> entitlements() async {
    final response = await _dio.get('/me/entitlements');
    return Entitlements.fromJson(response.data as Map<String, dynamic>);
  }

  /// The purchasable plans + their live prices, for the plan-selection UI.
  /// Prices come from the admin-editable plans table, so a change made in the
  /// admin panel is reflected here — the app never hardcodes plan prices.
  Future<List<PlanOption>> fetchPlans() async {
    final response = await _dio.get('/billing/plans');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlanOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Start a Paystack hosted checkout for a plan + interval. Returns the
  /// `authorization_url` the WebView opens plus the `reference` verify uses.
  /// There is no manual/auto choice — the renewal model is decided by the
  /// method the shop actually pays with (card ⇒ auto-renew).
  Future<CheckoutResponse> checkout({
    String planCode = 'studio',
    required String interval, // 'monthly' | 'annual'
  }) async {
    final response = await _dio.post('/billing/checkout', data: {
      'plan_code': planCode,
      'interval': interval,
    });
    return CheckoutResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Confirm a checkout the shop was just redirected back from. Re-verifies with
  /// Paystack server-side and applies the charge idempotently, so confirmation
  /// isn't hostage to webhook delivery. A 400 means the transaction isn't a
  /// usable success (abandoned / still pending); a 403 means the reference
  /// belongs to another account.
  Future<VerifyResponse> verify(String reference) async {
    final response = await _dio.get('/billing/verify/$reference');
    return VerifyResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Turn off auto-renew (switch back to manual renewal). The shop keeps its
  /// current paid period — this is a mode switch, not a cancellation. 400 if
  /// auto-renew isn't enabled.
  Future<void> cancelAutoRenew() async {
    await _dio.post('/billing/auto-renew/cancel');
  }
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.watch(dioProvider));
});

/// Purchasable plans + their live prices, for the plan-selection UI. autoDispose
/// so re-opening the Plan & billing screen refetches — a price changed in the
/// admin panel is picked up on the next visit rather than being cached forever.
final planOptionsProvider = FutureProvider.autoDispose<List<PlanOption>>((ref) {
  return ref.watch(billingRepositoryProvider).fetchPlans();
});
