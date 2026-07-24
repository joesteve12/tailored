// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fabric.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FabricImpl _$$FabricImplFromJson(Map<String, dynamic> json) => _$FabricImpl(
      id: json['id'] as String,
      orderItemId: json['order_item_id'] as String,
      serial: json['serial'] as String,
      details: json['details'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: nullableDecimalToDouble(json['quantity']),
      unit: json['unit'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FabricImplToJson(_$FabricImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_item_id': instance.orderItemId,
      'serial': instance.serial,
      'details': instance.details,
      'image_url': instance.imageUrl,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'created_at': instance.createdAt.toIso8601String(),
    };
