import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';
import 'task_event.dart';
import 'task_stage.dart';

part 'task_detail.freezed.dart';
part 'task_detail.g.dart';

/// The handover block on a `finish` response — who the garment goes to
/// next. `nextEmployeeId` null means the next stage has no worker yet and
/// the dialog should prompt to assign instead. Absent entirely after the
/// last stage (the task is complete).
@freezed
class HandoverInfo with _$HandoverInfo {
  const factory HandoverInfo({
    @JsonKey(name: 'next_stage_id') required String nextStageId,
    @JsonKey(name: 'next_stage_name') required String nextStageName,
    @JsonKey(name: 'next_employee_id') String? nextEmployeeId,
    @JsonKey(name: 'next_employee_name') String? nextEmployeeName,
  }) = _HandoverInfo;

  factory HandoverInfo.fromJson(Map<String, dynamic> json) =>
      _$HandoverInfoFromJson(json);
}

/// Mirrors TaskResponse — the task detail, kind-shaped. A production task
/// fills the order/item header context and `stages`; a to-do fills
/// title / dueAt / reminder / completedAt (with the order pair present
/// only when linked, and `recipientName` doubling as the linked client's
/// name). Everything kind-specific is nullable; the getters below are the
/// screen's vocabulary so widgets never poke at raw nullability.
///
/// `unitPrice` follows the Decimal-as-string wire convention (nullable
/// here because to-dos have no price).
@freezed
class TaskDetail with _$TaskDetail {
  const TaskDetail._();

  const factory TaskDetail({
    required String id,
    required String kind,
    @JsonKey(name: 'order_id') String? orderId,
    @JsonKey(name: 'order_number') String? orderNumber,
    @JsonKey(name: 'order_due_date') DateTime? orderDueDate,
    @JsonKey(name: 'order_item_id') String? orderItemId,
    @JsonKey(name: 'item_index') int? itemIndex,
    @JsonKey(name: 'garment_type') String? garmentType,
    @JsonKey(name: 'recipient_name') String? recipientName,
    int? quantity,
    @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
    double? unitPrice,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'expected_completion_date')
    DateTime? expectedCompletionDate,
    // General (to-do) fields.
    String? title,
    String? notes,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'reminder_minutes_before') int? reminderMinutesBefore,
    @JsonKey(name: 'remind_at') DateTime? remindAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'client_id') String? clientId,
    // Derived flags (both kinds).
    @JsonKey(name: 'is_complete') required bool isComplete,
    required bool delayed,
    @JsonKey(name: 'due_today') required bool dueToday,
    @JsonKey(name: 'due_tomorrow') required bool dueTomorrow,
    @Default(<TaskStage>[]) List<TaskStage> stages,
    @Default(<TaskEvent>[]) List<TaskEvent> events,
    HandoverInfo? handover,
  }) = _TaskDetail;

  factory TaskDetail.fromJson(Map<String, dynamic> json) =>
      _$TaskDetailFromJson(json);

  bool get isProduction => kind == 'production';
  bool get isGeneral => kind == 'general';

  /// The single stage that may be started / finished / skipped — the first
  /// unfinished one, matching the server's definition. Null when complete
  /// (and always for a to-do).
  TaskStage? get currentStage {
    for (final s in stages) {
      if (!s.isFinished) return s;
    }
    return null;
  }

  /// The "TQ372-1" header code for a production task.
  String? get codeLabel => (orderNumber != null && itemIndex != null)
      ? '$orderNumber-$itemIndex'
      : orderNumber;
}
