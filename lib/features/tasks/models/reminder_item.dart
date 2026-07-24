import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_item.freezed.dart';
part 'reminder_item.g.dart';

/// Mirrors ReminderItem — one row of `GET /tasks/reminders`: everything
/// the device needs to (re)schedule one local notification. `remindAt` is
/// computed SERVER-side (due_at − offset) so every delivery mechanism —
/// local now, FCM later — agrees on the instant; the client never derives
/// it itself. Rows with a past `remindAt` are included on purpose: the
/// reconciler must CANCEL those, and it can only cancel what it can see.
@freezed
class ReminderItem with _$ReminderItem {
  const factory ReminderItem({
    @JsonKey(name: 'task_id') required String taskId,
    required String title,
    @JsonKey(name: 'due_at') required DateTime dueAt,
    @JsonKey(name: 'remind_at') required DateTime remindAt,
  }) = _ReminderItem;

  factory ReminderItem.fromJson(Map<String, dynamic> json) =>
      _$ReminderItemFromJson(json);
}
