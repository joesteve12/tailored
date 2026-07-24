// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderStatusEventImpl _$$OrderStatusEventImplFromJson(
        Map<String, dynamic> json) =>
    _$OrderStatusEventImpl(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      itemId: json['item_id'] as String?,
      itemLabel: json['item_label'] as String?,
      fromStatus: json['from_status'] as String,
      toStatus: json['to_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$OrderStatusEventImplToJson(
        _$OrderStatusEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entity_type': instance.entityType,
      'item_id': instance.itemId,
      'item_label': instance.itemLabel,
      'from_status': instance.fromStatus,
      'to_status': instance.toStatus,
      'created_at': instance.createdAt.toIso8601String(),
    };
