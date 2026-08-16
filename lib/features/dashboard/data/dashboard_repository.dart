import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/dashboard_stats.dart';

/// Data source for the Dashboard screen.
///
/// Both methods hit the live backend:
///   • GET /dashboard/stats                     — range-independent rollups
///   • GET /dashboard/revenue?range=|from=&to=  — the revenue block for a window
///
/// Every response is parsed through the same `fromJson` the models already
/// define, so the JSON contract is the single source of truth shared with the
/// FastAPI backend (see app/schemas/dashboard.py).
class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  /// The range-independent rollups: KPIs, priority, status/garment/pipeline
  /// breakdowns, workload, client + fabric tiles, and both leaderboards.
  ///
  /// [today] and [tzOffsetMinutes] carry the client's local date + UTC offset so
  /// the month-scoped figures (new clients this month, avg order value) land in
  /// the shop's calendar — same semantics as `/home/summary`.
  Future<DashboardStats> stats({
    required DateTime today,
    required int tzOffsetMinutes,
  }) async {
    final response = await _dio.get('/dashboard/stats', queryParameters: {
      'today': dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    });
    return DashboardStats.fromJson(response.data as Map<String, dynamic>);
  }

  /// The revenue block for one window. Named ranges pass `?range=month`; a
  /// custom range passes `?from=…&to=…` (see [RevenueQuery.toQueryParameters]),
  /// which also carries `today` + `tz_offset_minutes` on every call so the
  /// window resolves in the shop's local calendar.
  Future<RevenueSnapshot> revenue(RevenueQuery query) async {
    final response = await _dio.get(
      '/dashboard/revenue',
      queryParameters: query.toQueryParameters(),
    );
    return RevenueSnapshot.fromJson(response.data as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
