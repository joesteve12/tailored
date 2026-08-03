// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentIssueImpl _$$DocumentIssueImplFromJson(Map<String, dynamic> json) =>
    _$DocumentIssueImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      paymentId: json['payment_id'] as String?,
      kind: json['kind'] as String,
      documentNumber: json['document_number'] as String?,
      orderNumber: json['order_number'] as String,
      clientName: json['client_name'] as String?,
      amount: nullableDecimalToDouble(json['amount']),
      balanceAfter: nullableDecimalToDouble(json['balance_after']),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );

Map<String, dynamic> _$$DocumentIssueImplToJson(_$DocumentIssueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'payment_id': instance.paymentId,
      'kind': instance.kind,
      'document_number': instance.documentNumber,
      'order_number': instance.orderNumber,
      'client_name': instance.clientName,
      'amount': instance.amount,
      'balance_after': instance.balanceAfter,
      'generated_at': instance.generatedAt.toIso8601String(),
    };
