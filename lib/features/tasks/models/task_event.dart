import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_event.freezed.dart';
part 'task_event.g.dart';

/// Mirrors TaskEventResponse — one row of the append-only task audit log,
/// returned newest-first by both `GET /tasks/{id}` (embedded `events`) and
/// `GET /orders/{id}/task-events` (the Activity feed's item-level half).
///
/// `action` is the raw wire enum string (`task_created`, `stage_started`,
/// `stage_sent_back`, `task_completed`, …) mapped to a label at render
/// time. `itemLabel` snapshots the garment type (production) or the to-do
/// title (general) at write time, and `detail` snapshots stage / employee
/// names — so a row still reads sensibly after any rename, and after the
/// task itself is deleted (`task_deleted` rows outlive their task by
/// design: the backend keeps no FK from events to tasks).
@freezed
class TaskEvent with _$TaskEvent {
  const factory TaskEvent({
    required String id,
    @JsonKey(name: 'task_id') required String taskId,
    @JsonKey(name: 'stage_id') String? stageId,
    required String action,
    @JsonKey(name: 'item_label') String? itemLabel,
    String? detail,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TaskEvent;

  factory TaskEvent.fromJson(Map<String, dynamic> json) =>
      _$TaskEventFromJson(json);
}
