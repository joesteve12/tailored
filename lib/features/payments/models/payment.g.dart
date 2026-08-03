// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      kind: json['kind'] as String? ?? 'payment',
      amount: decimalStringToDouble(json['amount']),
      tipAmount: json['tip_amount'] == null
          ? 0
          : decimalStringToDouble(json['tip_amount']),
      method: json['method'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String),
      receiptNumber: json['receipt_number'] as String?,
      orderTotalAtPayment:
          nullableDecimalToDouble(json['order_total_at_payment']),
      amountPaidAfter: nullableDecimalToDouble(json['amount_paid_after']),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'kind': instance.kind,
      'amount': instance.amount,
      'tip_amount': instance.tipAmount,
      'method': instance.method,
      'reason': instance.reason,
      'notes': instance.notes,
      'paid_at': instance.paidAt.toIso8601String(),
      'receipt_number': instance.receiptNumber,
      'order_total_at_payment': instance.orderTotalAtPayment,
      'amount_paid_after': instance.amountPaidAfter,
    };
