// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_production.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemProductionImpl _$$ItemProductionImplFromJson(Map<String, dynamic> json) =>
    _$ItemProductionImpl(
      state: json['state'] as String,
      currentStageName: json['current_stage_name'] as String?,
      currentStageStarted: json['current_stage_started'] as bool? ?? false,
      taskId: json['task_id'] as String?,
      expectedCompletionDate: json['expected_completion_date'] == null
          ? null
          : DateTime.parse(json['expected_completion_date'] as String),
      isOverdue: json['is_overdue'] as bool? ?? false,
    );

Map<String, dynamic> _$$ItemProductionImplToJson(
        _$ItemProductionImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
      'current_stage_name': instance.currentStageName,
      'current_stage_started': instance.currentStageStarted,
      'task_id': instance.taskId,
      'expected_completion_date':
          instance.expectedCompletionDate?.toIso8601String(),
      'is_overdue': instance.isOverdue,
    };
