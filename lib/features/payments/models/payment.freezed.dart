// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;

  /// 'payment' | 'refund'. Defaulted rather than required so a response
  /// from an older build can still be parsed instead of throwing.
  String get kind => throw _privateConstructorUsedError;
  @JsonKey(fromJson: decimalStringToDouble)
  double get amount => throw _privateConstructorUsedError;

  /// A gratuity handed over with this payment.
  ///
  /// Deliberately NOT part of [amount]: a tip never touches the order's
  /// `totalAmount` or `amountPaid` and never moves `paymentStatus`.
  /// Modelling it as an addon would inflate the order and make the invoice
  /// look like the shop billed for its own tip.
  @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
  double get tipAmount => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;

  /// Why money went back out. Required by the backend on refunds, always
  /// null on payments.
  String? get reason => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_at')
  DateTime get paidAt => throw _privateConstructorUsedError;

  /// Allocated once, per shop, when the row was recorded. Null on payments
  /// that predate the money rebuild.
  @JsonKey(name: 'receipt_number')
  String? get receiptNumber => throw _privateConstructorUsedError;

  /// Frozen snapshot of the order's total and running paid figure at the
  /// moment this row was recorded — never recomputed. Both are null on
  /// legacy rows; the historical values aren't recoverable from anything
  /// still in the database, so no backfill was attempted.
  @JsonKey(name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
  double? get orderTotalAtPayment => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
  double? get amountPaidAfter => throw _privateConstructorUsedError;

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      String kind,
      @JsonKey(fromJson: decimalStringToDouble) double amount,
      @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
      double tipAmount,
      String method,
      String? reason,
      String? notes,
      @JsonKey(name: 'paid_at') DateTime paidAt,
      @JsonKey(name: 'receipt_number') String? receiptNumber,
      @JsonKey(
          name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
      double? orderTotalAtPayment,
      @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
      double? amountPaidAfter});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? kind = null,
    Object? amount = null,
    Object? tipAmount = null,
    Object? method = null,
    Object? reason = freezed,
    Object? notes = freezed,
    Object? paidAt = null,
    Object? receiptNumber = freezed,
    Object? orderTotalAtPayment = freezed,
    Object? amountPaidAfter = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      tipAmount: null == tipAmount
          ? _value.tipAmount
          : tipAmount // ignore: cast_nullable_to_non_nullable
              as double,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: null == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      receiptNumber: freezed == receiptNumber
          ? _value.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      orderTotalAtPayment: freezed == orderTotalAtPayment
          ? _value.orderTotalAtPayment
          : orderTotalAtPayment // ignore: cast_nullable_to_non_nullable
              as double?,
      amountPaidAfter: freezed == amountPaidAfter
          ? _value.amountPaidAfter
          : amountPaidAfter // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
          _$PaymentImpl value, $Res Function(_$PaymentImpl) then) =
      __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      String kind,
      @JsonKey(fromJson: decimalStringToDouble) double amount,
      @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
      double tipAmount,
      String method,
      String? reason,
      String? notes,
      @JsonKey(name: 'paid_at') DateTime paidAt,
      @JsonKey(name: 'receipt_number') String? receiptNumber,
      @JsonKey(
          name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
      double? orderTotalAtPayment,
      @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
      double? amountPaidAfter});
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
      _$PaymentImpl _value, $Res Function(_$PaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? kind = null,
    Object? amount = null,
    Object? tipAmount = null,
    Object? method = null,
    Object? reason = freezed,
    Object? notes = freezed,
    Object? paidAt = null,
    Object? receiptNumber = freezed,
    Object? orderTotalAtPayment = freezed,
    Object? amountPaidAfter = freezed,
  }) {
    return _then(_$PaymentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      tipAmount: null == tipAmount
          ? _value.tipAmount
          : tipAmount // ignore: cast_nullable_to_non_nullable
              as double,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      paidAt: null == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      receiptNumber: freezed == receiptNumber
          ? _value.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      orderTotalAtPayment: freezed == orderTotalAtPayment
          ? _value.orderTotalAtPayment
          : orderTotalAtPayment // ignore: cast_nullable_to_non_nullable
              as double?,
      amountPaidAfter: freezed == amountPaidAfter
          ? _value.amountPaidAfter
          : amountPaidAfter // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl extends _Payment {
  const _$PaymentImpl(
      {required this.id,
      @JsonKey(name: 'order_id') required this.orderId,
      this.kind = 'payment',
      @JsonKey(fromJson: decimalStringToDouble) required this.amount,
      @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
      this.tipAmount = 0,
      required this.method,
      this.reason,
      this.notes,
      @JsonKey(name: 'paid_at') required this.paidAt,
      @JsonKey(name: 'receipt_number') this.receiptNumber,
      @JsonKey(
          name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
      this.orderTotalAtPayment,
      @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
      this.amountPaidAfter})
      : super._();

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;

  /// 'payment' | 'refund'. Defaulted rather than required so a response
  /// from an older build can still be parsed instead of throwing.
  @override
  @JsonKey()
  final String kind;
  @override
  @JsonKey(fromJson: decimalStringToDouble)
  final double amount;

  /// A gratuity handed over with this payment.
  ///
  /// Deliberately NOT part of [amount]: a tip never touches the order's
  /// `totalAmount` or `amountPaid` and never moves `paymentStatus`.
  /// Modelling it as an addon would inflate the order and make the invoice
  /// look like the shop billed for its own tip.
  @override
  @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
  final double tipAmount;
  @override
  final String method;

  /// Why money went back out. Required by the backend on refunds, always
  /// null on payments.
  @override
  final String? reason;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'paid_at')
  final DateTime paidAt;

  /// Allocated once, per shop, when the row was recorded. Null on payments
  /// that predate the money rebuild.
  @override
  @JsonKey(name: 'receipt_number')
  final String? receiptNumber;

  /// Frozen snapshot of the order's total and running paid figure at the
  /// moment this row was recorded — never recomputed. Both are null on
  /// legacy rows; the historical values aren't recoverable from anything
  /// still in the database, so no backfill was attempted.
  @override
  @JsonKey(name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
  final double? orderTotalAtPayment;
  @override
  @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
  final double? amountPaidAfter;

  @override
  String toString() {
    return 'Payment(id: $id, orderId: $orderId, kind: $kind, amount: $amount, tipAmount: $tipAmount, method: $method, reason: $reason, notes: $notes, paidAt: $paidAt, receiptNumber: $receiptNumber, orderTotalAtPayment: $orderTotalAtPayment, amountPaidAfter: $amountPaidAfter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.tipAmount, tipAmount) ||
                other.tipAmount == tipAmount) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.orderTotalAtPayment, orderTotalAtPayment) ||
                other.orderTotalAtPayment == orderTotalAtPayment) &&
            (identical(other.amountPaidAfter, amountPaidAfter) ||
                other.amountPaidAfter == amountPaidAfter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      kind,
      amount,
      tipAmount,
      method,
      reason,
      notes,
      paidAt,
      receiptNumber,
      orderTotalAtPayment,
      amountPaidAfter);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(
      this,
    );
  }
}

abstract class _Payment extends Payment {
  const factory _Payment(
      {required final String id,
      @JsonKey(name: 'order_id') required final String orderId,
      final String kind,
      @JsonKey(fromJson: decimalStringToDouble) required final double amount,
      @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
      final double tipAmount,
      required final String method,
      final String? reason,
      final String? notes,
      @JsonKey(name: 'paid_at') required final DateTime paidAt,
      @JsonKey(name: 'receipt_number') final String? receiptNumber,
      @JsonKey(
          name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
      final double? orderTotalAtPayment,
      @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
      final double? amountPaidAfter}) = _$PaymentImpl;
  const _Payment._() : super._();

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;

  /// 'payment' | 'refund'. Defaulted rather than required so a response
  /// from an older build can still be parsed instead of throwing.
  @override
  String get kind;
  @override
  @JsonKey(fromJson: decimalStringToDouble)
  double get amount;

  /// A gratuity handed over with this payment.
  ///
  /// Deliberately NOT part of [amount]: a tip never touches the order's
  /// `totalAmount` or `amountPaid` and never moves `paymentStatus`.
  /// Modelling it as an addon would inflate the order and make the invoice
  /// look like the shop billed for its own tip.
  @override
  @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
  double get tipAmount;
  @override
  String get method;

  /// Why money went back out. Required by the backend on refunds, always
  /// null on payments.
  @override
  String? get reason;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'paid_at')
  DateTime get paidAt;

  /// Allocated once, per shop, when the row was recorded. Null on payments
  /// that predate the money rebuild.
  @override
  @JsonKey(name: 'receipt_number')
  String? get receiptNumber;

  /// Frozen snapshot of the order's total and running paid figure at the
  /// moment this row was recorded — never recomputed. Both are null on
  /// legacy rows; the historical values aren't recoverable from anything
  /// still in the database, so no backfill was attempted.
  @override
  @JsonKey(name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
  double? get orderTotalAtPayment;
  @override
  @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
  double? get amountPaidAfter;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
