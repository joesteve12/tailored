// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_workload_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmployeeWorkloadItemImpl _$$EmployeeWorkloadItemImplFromJson(
        Map<String, dynamic> json) =>
    _$EmployeeWorkloadItemImpl(
      stageId: json['stage_id'] as String,
      taskId: json['task_id'] as String,
      processName: json['process_name'] as String,
      sequence: (json['sequence'] as num).toInt(),
      stageState: json['stage_state'] as String,
      orderItemId: json['order_item_id'] as String,
      garmentType: json['garment_type'] as String,
      productionState: json['production_state'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      expectedCompletionDate:
          DateTime.parse(json['expected_completion_date'] as String),
    );

Map<String, dynamic> _$$EmployeeWorkloadItemImplToJson(
        _$EmployeeWorkloadItemImpl instance) =>
    <String, dynamic>{
      'stage_id': instance.stageId,
      'task_id': instance.taskId,
      'process_name': instance.processName,
      'sequence': instance.sequence,
      'stage_state': instance.stageState,
      'order_item_id': instance.orderItemId,
      'garment_type': instance.garmentType,
      'production_state': instance.productionState,
      'order_id': instance.orderId,
      'order_number': instance.orderNumber,
      'due_date': instance.dueDate?.toIso8601String(),
      'expected_completion_date':
          instance.expectedCompletionDate.toIso8601String(),
    };
