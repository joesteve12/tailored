// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalendarOrderImpl _$$CalendarOrderImplFromJson(Map<String, dynamic> json) =>
    _$CalendarOrderImpl(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      clientName: json['client_name'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      priority: json['priority'] as String,
      paymentStatus: json['payment_status'] as String,
    );

Map<String, dynamic> _$$CalendarOrderImplToJson(_$CalendarOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'client_name': instance.clientName,
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'priority': instance.priority,
      'payment_status': instance.paymentStatus,
    };

_$CalendarResponseImpl _$$CalendarResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CalendarResponseImpl(
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => CalendarOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CalendarOrder>[],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TaskSummary>[],
    );

Map<String, dynamic> _$$CalendarResponseImplToJson(
        _$CalendarResponseImpl instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'tasks': instance.tasks,
    };
