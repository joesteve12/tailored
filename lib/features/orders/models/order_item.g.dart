// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      id: json['id'] as String,
      garmentType: json['garment_type'] as String,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: decimalStringToDouble(json['unit_price']),
      fabrics: (json['fabrics'] as List<dynamic>?)
              ?.map((e) => Fabric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Fabric>[],
      notes: json['notes'] as String?,
      recipientType: json['recipient_type'] as String,
      recipientClientId: json['recipient_client_id'] as String?,
      guestRecipientId: json['guest_recipient_id'] as String?,
      measurementSetIds: (json['measurement_set_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      production:
          ItemProduction.fromJson(json['production'] as Map<String, dynamic>),
      styleReferences: (json['style_references'] as List<dynamic>?)
              ?.map((e) => StyleReference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StyleReference>[],
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'garment_type': instance.garmentType,
      'description': instance.description,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'fabrics': instance.fabrics,
      'notes': instance.notes,
      'recipient_type': instance.recipientType,
      'recipient_client_id': instance.recipientClientId,
      'guest_recipient_id': instance.guestRecipientId,
      'measurement_set_ids': instance.measurementSetIds,
      'production': instance.production,
      'style_references': instance.styleReferences,
    };
