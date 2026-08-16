import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/calendar_data.dart';

/// Formats a DateTime as "YYYY-MM-DD" — the backend's `from` / `to` / `today`
/// are Pydantic `date`s and reject full ISO datetimes (same reason as the
/// tasks and orders repos).
String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class CalendarRepository {
  CalendarRepository(this._dio);

  final Dio _dio;

  /// GET /calendar — every order deadline, production hand-off, and to-do
  /// whose LOCAL day falls in [from, to] inclusive, in the two card shapes
  /// the app already draws. [today] drives each task card's delayed/due-today
  /// badge (so it matches the Tasks tab); [tzOffsetMinutes] places a to-do's
  /// due TIMESTAMP on the shop's local calendar day.
  Future<CalendarResponse> events({
    required DateTime from,
    required DateTime to,
    required DateTime today,
    required int tzOffsetMinutes,
  }) async {
    final response = await _dio.get('/calendar', queryParameters: {
      'from': _dateOnly(from),
      'to': _dateOnly(to),
      'today': _dateOnly(today),
      'tz_offset_minutes': tzOffsetMinutes,
    });
    return CalendarResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(dioProvider));
});
