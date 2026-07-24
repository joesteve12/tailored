import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_workload_item.freezed.dart';
part 'employee_workload_item.g.dart';

/// Mirrors the backend EmployeeWorkloadItem — one line in an employee's
/// workload, returned by GET /employees/{id}/workload. The assignment
/// table is gone; each row is now one task STAGE assigned to them, with
/// the stage's derived state (`stageState`: untouched / in_progress /
/// done / skipped) and the parent item's derived production state
/// (`productionState`: in_progress / done — a task exists by definition).
/// Includes finished stages (it's a history view too); screens filter by
/// `stageState` if they only want open work. `dueDate` is the parent
/// order's date-only due date; `expectedCompletionDate` is the task's.
@freezed
class EmployeeWorkloadItem with _$EmployeeWorkloadItem {
  const EmployeeWorkloadItem._();

  const factory EmployeeWorkloadItem({
    @JsonKey(name: 'stage_id') required String stageId,
    @JsonKey(name: 'task_id') required String taskId,
    @JsonKey(name: 'process_name') required String processName,
    required int sequence,
    @JsonKey(name: 'stage_state') required String stageState,
    @JsonKey(name: 'order_item_id') required String orderItemId,
    @JsonKey(name: 'garment_type') required String garmentType,
    @JsonKey(name: 'production_state') required String productionState,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'expected_completion_date')
    required DateTime expectedCompletionDate,
  }) = _EmployeeWorkloadItem;

  factory EmployeeWorkloadItem.fromJson(Map<String, dynamic> json) =>
      _$EmployeeWorkloadItemFromJson(json);

  bool get isOpen => stageState == 'untouched' || stageState == 'in_progress';
}
