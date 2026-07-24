import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_stage.freezed.dart';
part 'task_stage.g.dart';

/// Mirrors TaskStageResponse — one process instance inside a production
/// task's pipeline.
///
/// `state` is the server-derived value — `untouched` / `in_progress` /
/// `done` / `skipped` — kept a plain string per house convention (wire
/// values mapped to labels at the view layer, see `stageStateLabel`).
/// The client NEVER derives state from the timestamps itself; the server
/// already did, and two derivations is how they drift. The timestamps are
/// carried only for display ("Started On …" / "Completed On …").
@freezed
class TaskStage with _$TaskStage {
  const TaskStage._();

  const factory TaskStage({
    required String id,
    @JsonKey(name: 'process_id') required String processId,
    @JsonKey(name: 'process_name') required String processName,
    required int sequence,
    @JsonKey(name: 'assigned_employee_id') String? assignedEmployeeId,
    @JsonKey(name: 'assigned_employee_name') String? assignedEmployeeName,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'finished_at') DateTime? finishedAt,
    required String state,
  }) = _TaskStage;

  factory TaskStage.fromJson(Map<String, dynamic> json) =>
      _$TaskStageFromJson(json);

  bool get isUntouched => state == 'untouched';
  bool get isInProgress => state == 'in_progress';

  /// Finished in either sense — worked ('done') or skipped. Drives the
  /// check-mark node and the "may not be edited/reordered" rules.
  bool get isFinished => state == 'done' || state == 'skipped';
}
