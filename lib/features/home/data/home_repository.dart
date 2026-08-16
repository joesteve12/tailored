import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../state/home_dashboard_providers.dart';

/// Formats a DateTime as "YYYY-MM-DD" — the backend's `today` is a Pydantic
/// `date` and rejects a full ISO datetime, same as the tasks repo.
String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class HomeRepository {
  HomeRepository(this._dio);

  final Dio _dio;

  /// GET /home/summary — the Home tab's production hero and revenue card in
  /// one round trip. [today] and [tzOffsetMinutes] carry the CLIENT's local
  /// date and UTC offset so the revenue month is the shop's month, not the
  /// server's — the same date semantics the Tasks endpoints use.
  Future<HomeSummary> summary({
    required DateTime today,
    required int tzOffsetMinutes,
  }) async {
    final response = await _dio.get('/home/summary', queryParameters: {
      'today': _dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    });
    return HomeSummary.fromJson(response.data as Map<String, dynamic>);
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});
