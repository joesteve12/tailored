import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_summary.freezed.dart';
part 'task_summary.g.dart';

/// One node of the horizontal mini-timeline on a production task card:
/// name + derived state, with the finish timestamp so completion dates can
/// print under finished nodes.
@freezed
class StageBrief with _$StageBrief {
  const StageBrief._();

  const factory StageBrief({
    @JsonKey(name: 'process_name') required String processName,
    required String state,
    @JsonKey(name: 'finished_at') DateTime? finishedAt,
  }) = _StageBrief;

  factory StageBrief.fromJson(Map<String, dynamic> json) =>
      _$StageBriefFromJson(json);

  bool get isFinished => state == 'done' || state == 'skipped';
}

/// Mirrors TaskSummary — one card on the cross-order Tasks tab. The list
/// is MIXED: `kind` discriminates a production card (order/item context,
/// stages) from a to-do card (title, dueAt, checkbox), and each side's
/// fields are null on the other. Both card widgets read this one model
/// rather than splitting it, because a single wire shape shouldn't fork
/// into two Dart types that then need a sealed wrapper to sit in one list.
@freezed
class TaskSummary with _$TaskSummary {
  const TaskSummary._();

  const factory TaskSummary({
    @JsonKey(name: 'task_id') required String taskId,
    required String kind,
    // Production context — to-dos: only when linked to an order.
    @JsonKey(name: 'order_id') String? orderId,
    @JsonKey(name: 'order_number') String? orderNumber,
    @JsonKey(name: 'item_index') int? itemIndex,
    @JsonKey(name: 'garment_type') String? garmentType,
    /// Item recipient (production) or linked client (to-do).
    @JsonKey(name: 'recipient_name') String? recipientName,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'expected_completion_date')
    DateTime? expectedCompletionDate,
    // General (to-do) fields.
    String? title,
    @JsonKey(name: 'due_at') DateTime? dueAt,
    @JsonKey(name: 'reminder_enabled') bool? reminderEnabled,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    // Derived flags (both kinds). Buckets come from the server — computed
    // against the `today` + tz offset the client sent — so the tabs and
    // the badges can never disagree with the filter that fetched them.
    @JsonKey(name: 'is_complete') required bool isComplete,
    required bool delayed,
    @JsonKey(name: 'due_today') required bool dueToday,
    @JsonKey(name: 'due_tomorrow') required bool dueTomorrow,
    @Default(<StageBrief>[]) List<StageBrief> stages,
  }) = _TaskSummary;

  factory TaskSummary.fromJson(Map<String, dynamic> json) =>
      _$TaskSummaryFromJson(json);

  bool get isProduction => kind == 'production';
  bool get isGeneral => kind == 'general';

  /// The "TQ372-1" code overlaid on a production card's thumbnail.
  String? get codeLabel => (orderNumber != null && itemIndex != null)
      ? '$orderNumber-$itemIndex'
      : orderNumber;
}

/// Envelope of `GET /tasks` — mirrors TaskListResponse. Not paginated (the
/// four live filters keep it bounded); `total` is the result count.
@freezed
class TaskListResponse with _$TaskListResponse {
  const factory TaskListResponse({
    required int total,
    @Default(<TaskSummary>[]) List<TaskSummary> results,
  }) = _TaskListResponse;

  factory TaskListResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskListResponseFromJson(json);
}
