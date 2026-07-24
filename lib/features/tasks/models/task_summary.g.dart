// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StageBriefImpl _$$StageBriefImplFromJson(Map<String, dynamic> json) =>
    _$StageBriefImpl(
      processName: json['process_name'] as String,
      state: json['state'] as String,
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
    );

Map<String, dynamic> _$$StageBriefImplToJson(_$StageBriefImpl instance) =>
    <String, dynamic>{
      'process_name': instance.processName,
      'state': instance.state,
      'finished_at': instance.finishedAt?.toIso8601String(),
    };

_$TaskSummaryImpl _$$TaskSummaryImplFromJson(Map<String, dynamic> json) =>
    _$TaskSummaryImpl(
      taskId: json['task_id'] as String,
      kind: json['kind'] as String,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      itemIndex: (json['item_index'] as num?)?.toInt(),
      garmentType: json['garment_type'] as String?,
      recipientName: json['recipient_name'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      expectedCompletionDate: json['expected_completion_date'] == null
          ? null
          : DateTime.parse(json['expected_completion_date'] as String),
      title: json['title'] as String?,
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      reminderMinutesBefore: (json['reminder_minutes_before'] as num?)?.toInt(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      isComplete: json['is_complete'] as bool,
      delayed: json['delayed'] as bool,
      dueToday: json['due_today'] as bool,
      dueTomorrow: json['due_tomorrow'] as bool,
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => StageBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StageBrief>[],
    );

Map<String, dynamic> _$$TaskSummaryImplToJson(_$TaskSummaryImpl instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'kind': instance.kind,
      'order_id': instance.orderId,
      'order_number': instance.orderNumber,
      'item_index': instance.itemIndex,
      'garment_type': instance.garmentType,
      'recipient_name': instance.recipientName,
      'thumbnail_url': instance.thumbnailUrl,
      'expected_completion_date':
          instance.expectedCompletionDate?.toIso8601String(),
      'title': instance.title,
      'due_at': instance.dueAt?.toIso8601String(),
      'reminder_minutes_before': instance.reminderMinutesBefore,
      'completed_at': instance.completedAt?.toIso8601String(),
      'is_complete': instance.isComplete,
      'delayed': instance.delayed,
      'due_today': instance.dueToday,
      'due_tomorrow': instance.dueTomorrow,
      'stages': instance.stages,
    };

_$TaskListResponseImpl _$$TaskListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$TaskListResponseImpl(
      total: (json['total'] as num).toInt(),
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TaskSummary>[],
    );

Map<String, dynamic> _$$TaskListResponseImplToJson(
        _$TaskListResponseImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'results': instance.results,
    };
