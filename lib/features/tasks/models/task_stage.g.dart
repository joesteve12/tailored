// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_stage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskStageImpl _$$TaskStageImplFromJson(Map<String, dynamic> json) =>
    _$TaskStageImpl(
      id: json['id'] as String,
      processId: json['process_id'] as String,
      processName: json['process_name'] as String,
      sequence: (json['sequence'] as num).toInt(),
      assignedEmployeeId: json['assigned_employee_id'] as String?,
      assignedEmployeeName: json['assigned_employee_name'] as String?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      state: json['state'] as String,
    );

Map<String, dynamic> _$$TaskStageImplToJson(_$TaskStageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'process_id': instance.processId,
      'process_name': instance.processName,
      'sequence': instance.sequence,
      'assigned_employee_id': instance.assignedEmployeeId,
      'assigned_employee_name': instance.assignedEmployeeName,
      'started_at': instance.startedAt?.toIso8601String(),
      'finished_at': instance.finishedAt?.toIso8601String(),
      'state': instance.state,
    };
