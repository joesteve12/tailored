import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/promotion.dart';

/// The single HTTP surface for house promotions (AD_SYSTEM Phase H3). Talks to
/// the two H2 endpoints:
///
///   GET  /me/promotions?placement=…            → one card, or null
///   POST /me/promotions/{campaign_id}/events   → record a click / dismiss
///
/// Both are **fail-silent** (proposal §9): a promotion is never worth a spinner
/// or an error box, and an interaction ping is fire-and-forget — the same rule
/// BillingBanner already follows. So [fetch] returns null on any error and
/// [recordEvent] swallows failures.
///
/// dioProvider's baseUrl already ends in /api/v1 — paths here are relative to
/// that, matching the other repositories.
class PromotionsRepository {
  PromotionsRepository(this._dio);

  final Dio _dio;

  /// Resolve the one promotion for [placement], or null when nothing matches
  /// (the server returns JSON `null`) or on any transport/parse error. Never
  /// throws — the caller renders nothing on null.
  Future<Promotion?> fetch(String placement) async {
    try {
      final response = await _dio.get(
        '/me/promotions',
        queryParameters: {'placement': placement},
      );
      final data = response.data;
      if (data is! Map) return null; // null body = no match
      return Promotion.fromJson(data.cast<String, dynamic>());
    } catch (_) {
      // Fail silent: a failed/slow promotion fetch renders nothing.
      return null;
    }
  }

  /// Fire-and-forget interaction ping. [kind] is `clicked` or `dismissed`
  /// (`served` is server-only). Errors are swallowed — a dropped ping at worst
  /// costs one cap increment, never a user-visible failure.
  Future<void> recordEvent({
    required String campaignId,
    required String kind,
    required String placement,
  }) async {
    try {
      await _dio.post(
        '/me/promotions/$campaignId/events',
        data: {'kind': kind, 'placement': placement},
      );
    } catch (_) {
      // Intentionally ignored (fire-and-forget).
    }
  }
}

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.watch(dioProvider));
});
