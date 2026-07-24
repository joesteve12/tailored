// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'normal',
      dueDate: DateTime.parse(json['due_date'] as String),
      subtotal: json['subtotal'] == null
          ? 0
          : decimalStringToDouble(json['subtotal']),
      discountType: json['discount_type'] as String? ?? 'none',
      discountValue: json['discount_value'] == null
          ? 0
          : decimalStringToDouble(json['discount_value']),
      discountAmount: json['discount_amount'] == null
          ? 0
          : decimalStringToDouble(json['discount_amount']),
      totalAmount: decimalStringToDouble(json['total_amount']),
      amountPaid: decimalStringToDouble(json['amount_paid']),
      paymentStatus: json['payment_status'] as String,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderItem>[],
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => OrderMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderMedia>[],
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'order_number': instance.orderNumber,
      'status': instance.status,
      'priority': instance.priority,
      'due_date': instance.dueDate.toIso8601String(),
      'subtotal': instance.subtotal,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'discount_amount': instance.discountAmount,
      'total_amount': instance.totalAmount,
      'amount_paid': instance.amountPaid,
      'payment_status': instance.paymentStatus,
      'notes': instance.notes,
      'items': instance.items,
      'media': instance.media,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$OrderListResponseImpl _$$OrderListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$OrderListResponseImpl(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OrderListResponseImplToJson(
        _$OrderListResponseImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'results': instance.results,
    };
