// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReminderItemImpl _$$ReminderItemImplFromJson(Map<String, dynamic> json) =>
    _$ReminderItemImpl(
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      remindAt: DateTime.parse(json['remind_at'] as String),
    );

Map<String, dynamic> _$$ReminderItemImplToJson(_$ReminderItemImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'title': instance.title,
      'due_at': instance.dueAt.toIso8601String(),
      'remind_at': instance.remindAt.toIso8601String(),
    };
