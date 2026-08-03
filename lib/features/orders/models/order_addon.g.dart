// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_addon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderAddonImpl _$$OrderAddonImplFromJson(Map<String, dynamic> json) =>
    _$OrderAddonImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      label: json['label'] as String,
      amount: decimalStringToDouble(json['amount']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$OrderAddonImplToJson(_$OrderAddonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'label': instance.label,
      'amount': instance.amount,
      'quantity': instance.quantity,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
