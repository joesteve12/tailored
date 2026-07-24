// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fabric_inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FabricInventoryItemImpl _$$FabricInventoryItemImplFromJson(
        Map<String, dynamic> json) =>
    _$FabricInventoryItemImpl(
      id: json['id'] as String,
      serial: json['serial'] as String,
      details: json['details'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: nullableDecimalToDouble(json['quantity']),
      unit: json['unit'] as String?,
      orderItemId: json['order_item_id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String,
      garmentType: json['garment_type'] as String,
      productionState: json['production_state'] as String,
      recipientType: json['recipient_type'] as String,
      recipientName: json['recipient_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FabricInventoryItemImplToJson(
        _$FabricInventoryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serial': instance.serial,
      'details': instance.details,
      'image_url': instance.imageUrl,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'order_item_id': instance.orderItemId,
      'order_id': instance.orderId,
      'order_number': instance.orderNumber,
      'garment_type': instance.garmentType,
      'production_state': instance.productionState,
      'recipient_type': instance.recipientType,
      'recipient_name': instance.recipientName,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$FabricInventoryDetailImpl _$$FabricInventoryDetailImplFromJson(
        Map<String, dynamic> json) =>
    _$FabricInventoryDetailImpl(
      id: json['id'] as String,
      serial: json['serial'] as String,
      details: json['details'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: nullableDecimalToDouble(json['quantity']),
      unit: json['unit'] as String?,
      orderItemId: json['order_item_id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String,
      garmentType: json['garment_type'] as String,
      productionState: json['production_state'] as String,
      recipientType: json['recipient_type'] as String,
      recipientName: json['recipient_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      orderStatus: json['order_status'] as String?,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      recipientPhone: json['recipient_phone'] as String?,
    );

Map<String, dynamic> _$$FabricInventoryDetailImplToJson(
        _$FabricInventoryDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serial': instance.serial,
      'details': instance.details,
      'image_url': instance.imageUrl,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'order_item_id': instance.orderItemId,
      'order_id': instance.orderId,
      'order_number': instance.orderNumber,
      'garment_type': instance.garmentType,
      'production_state': instance.productionState,
      'recipient_type': instance.recipientType,
      'recipient_name': instance.recipientName,
      'created_at': instance.createdAt?.toIso8601String(),
      'order_status': instance.orderStatus,
      'due_date': instance.dueDate?.toIso8601String(),
      'recipient_phone': instance.recipientPhone,
    };
