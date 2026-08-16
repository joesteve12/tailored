import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tasks/models/task_summary.dart';

part 'calendar_data.freezed.dart';
part 'calendar_data.g.dart';

/// An order deadline on the calendar — mirrors CalendarOrder on the backend.
/// Deliberately lean: exactly the fields [OrderCard] renders, so the same
/// card the Orders tab uses drives a calendar deadline with no adaptor.
/// [day] is the local bucket day the grid and agenda group on.
@freezed
class CalendarOrder with _$CalendarOrder {
  const CalendarOrder._();

  const factory CalendarOrder({
    required String id,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'client_name') String? clientName,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    required String status,
    required String priority,
    @JsonKey(name: 'payment_status') required String paymentStatus,
  }) = _CalendarOrder;

  factory CalendarOrder.fromJson(Map<String, dynamic> json) =>
      _$CalendarOrderFromJson(json);

  DateTime get day => DateTime(dueDate.year, dueDate.month, dueDate.day);
}

/// Envelope of `GET /calendar` — mirrors CalendarResponse. Two shapes the app
/// already draws: `orders` (order-list cards) and `tasks` (the exact Tasks-tab
/// [TaskSummary], production + to-do). The screen buckets each by its own day.
@freezed
class CalendarResponse with _$CalendarResponse {
  const factory CalendarResponse({
    @Default(<CalendarOrder>[]) List<CalendarOrder> orders,
    @Default(<TaskSummary>[]) List<TaskSummary> tasks,
  }) = _CalendarResponse;

  factory CalendarResponse.fromJson(Map<String, dynamic> json) =>
      _$CalendarResponseFromJson(json);
}
