import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_summary_counts.freezed.dart';
part 'task_summary_counts.g.dart';

/// Mirrors TaskSummaryCounts — `GET /tasks/summary`, the Home tab's three
/// Production chips. Counts cover open work of BOTH kinds (a to-do due
/// tomorrow is work tomorrow), computed against the client-sent local date
/// and tz offset so the chips agree with the Tasks tab they deep-link to.
@freezed
class TaskSummaryCounts with _$TaskSummaryCounts {
  const TaskSummaryCounts._();

  const factory TaskSummaryCounts({
    required int overdue,
    @JsonKey(name: 'due_today') required int dueToday,
    @JsonKey(name: 'due_tomorrow') required int dueTomorrow,
  }) = _TaskSummaryCounts;

  factory TaskSummaryCounts.fromJson(Map<String, dynamic> json) =>
      _$TaskSummaryCountsFromJson(json);

  bool get isEmpty => overdue == 0 && dueToday == 0 && dueTomorrow == 0;
}
