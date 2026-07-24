import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_production.freezed.dart';
part 'item_production.g.dart';

/// Mirrors the `production` block embedded on every OrderItemResponse —
/// the server-derived, read-only replacement for the old stored `status`
/// column. Never edited client-side; every change goes through the task
/// endpoints and this block simply reflects the result on the next read.
///
/// `state` is `not_started` (no task yet) / `in_progress` / `done`.
/// When in progress, `currentStageName` + `currentStageStarted` describe
/// the single active stage ("Cutting — in progress" vs "Cutting — up
/// next"). `isOverdue` is computed server-side against the UTC date —
/// near-midnight imprecision for non-UTC shops is accepted here; the
/// Tasks tab (which takes the client's date + offset) is the exact view.
@freezed
class ItemProduction with _$ItemProduction {
  const ItemProduction._();

  const factory ItemProduction({
    required String state,
    @JsonKey(name: 'current_stage_name') String? currentStageName,
    @JsonKey(name: 'current_stage_started')
    @Default(false)
    bool currentStageStarted,
    @JsonKey(name: 'task_id') String? taskId,
    @JsonKey(name: 'expected_completion_date')
    DateTime? expectedCompletionDate,
    @JsonKey(name: 'is_overdue') @Default(false) bool isOverdue,
  }) = _ItemProduction;

  factory ItemProduction.fromJson(Map<String, dynamic> json) =>
      _$ItemProductionFromJson(json);

  bool get notStarted => state == 'not_started';
  bool get inProgress => state == 'in_progress';
  bool get done => state == 'done';

  /// Whether the item has a task at all — gates "Create task" vs "open the
  /// task detail" on the order's items list.
  bool get hasTask => taskId != null;

  /// The chip/dialog label: "Not started" / "Done" / "<Stage> — up next" /
  /// "<Stage> — in progress" — the same composite the work-order PDF
  /// prints, built in one place.
  String get label {
    switch (state) {
      case 'not_started':
        return 'Not started';
      case 'done':
        return 'Done';
      default:
        final name = currentStageName ?? 'In progress';
        return currentStageStarted ? '$name — in progress' : '$name — up next';
    }
  }
}
