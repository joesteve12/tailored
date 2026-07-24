// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskEventImpl _$$TaskEventImplFromJson(Map<String, dynamic> json) =>
    _$TaskEventImpl(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      stageId: json['stage_id'] as String?,
      action: json['action'] as String,
      itemLabel: json['item_label'] as String?,
      detail: json['detail'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TaskEventImplToJson(_$TaskEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'task_id': instance.taskId,
      'stage_id': instance.stageId,
      'action': instance.action,
      'item_label': instance.itemLabel,
      'detail': instance.detail,
      'created_at': instance.createdAt.toIso8601String(),
    };
