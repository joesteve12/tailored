// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: decimalStringToDouble(json['amount']),
      method: json['method'] as String,
      notes: json['notes'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String),
      voidedAt: json['voided_at'] == null
          ? null
          : DateTime.parse(json['voided_at'] as String),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'amount': instance.amount,
      'method': instance.method,
      'notes': instance.notes,
      'paid_at': instance.paidAt.toIso8601String(),
      'voided_at': instance.voidedAt?.toIso8601String(),
    };
