// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandoverInfoImpl _$$HandoverInfoImplFromJson(Map<String, dynamic> json) =>
    _$HandoverInfoImpl(
      nextStageId: json['next_stage_id'] as String,
      nextStageName: json['next_stage_name'] as String,
      nextEmployeeId: json['next_employee_id'] as String?,
      nextEmployeeName: json['next_employee_name'] as String?,
    );

Map<String, dynamic> _$$HandoverInfoImplToJson(_$HandoverInfoImpl instance) =>
    <String, dynamic>{
      'next_stage_id': instance.nextStageId,
      'next_stage_name': instance.nextStageName,
      'next_employee_id': instance.nextEmployeeId,
      'next_employee_name': instance.nextEmployeeName,
    };

_$TaskDetailImpl _$$TaskDetailImplFromJson(Map<String, dynamic> json) =>
    _$TaskDetailImpl(
      id: json['id'] as String,
      kind: json['kind'] as String,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      orderDueDate: json['order_due_date'] == null
          ? null
          : DateTime.parse(json['order_due_date'] as String),
      orderItemId: json['order_item_id'] as String?,
      itemIndex: (json['item_index'] as num?)?.toInt(),
      garmentType: json['garment_type'] as String?,
      recipientName: json['recipient_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitPrice: nullableDecimalToDouble(json['unit_price']),
      thumbnailUrl: json['thumbnail_url'] as String?,
      expectedCompletionDate: json['expected_completion_date'] == null
          ? null
          : DateTime.parse(json['expected_completion_date'] as String),
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      reminderMinutesBefore: (json['reminder_minutes_before'] as num?)?.toInt(),
      remindAt: json['remind_at'] == null
          ? null
          : DateTime.parse(json['remind_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      clientId: json['client_id'] as String?,
      isComplete: json['is_complete'] as bool,
      delayed: json['delayed'] as bool,
      dueToday: json['due_today'] as bool,
      dueTomorrow: json['due_tomorrow'] as bool,
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => TaskStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TaskStage>[],
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => TaskEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TaskEvent>[],
      handover: json['handover'] == null
          ? null
          : HandoverInfo.fromJson(json['handover'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TaskDetailImplToJson(_$TaskDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'order_id': instance.orderId,
      'order_number': instance.orderNumber,
      'order_due_date': instance.orderDueDate?.toIso8601String(),
      'order_item_id': instance.orderItemId,
      'item_index': instance.itemIndex,
      'garment_type': instance.garmentType,
      'recipient_name': instance.recipientName,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'thumbnail_url': instance.thumbnailUrl,
      'expected_completion_date':
          instance.expectedCompletionDate?.toIso8601String(),
      'title': instance.title,
      'notes': instance.notes,
      'due_at': instance.dueAt?.toIso8601String(),
      'reminder_minutes_before': instance.reminderMinutesBefore,
      'remind_at': instance.remindAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'client_id': instance.clientId,
      'is_complete': instance.isComplete,
      'delayed': instance.delayed,
      'due_today': instance.dueToday,
      'due_tomorrow': instance.dueTomorrow,
      'stages': instance.stages,
      'events': instance.events,
      'handover': instance.handover,
    };
