// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_issue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DocumentIssue _$DocumentIssueFromJson(Map<String, dynamic> json) {
  return _DocumentIssue.fromJson(json);
}

/// @nodoc
mixin _$DocumentIssue {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String? get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_id')
  String? get paymentId => throw _privateConstructorUsedError;

  /// 'invoice' | 'receipt' | 'work_order'.
  String get kind => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_number')
  String? get documentNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_name')
  String? get clientName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
  double? get balanceAfter => throw _privateConstructorUsedError;
  @JsonKey(name: 'generated_at')
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Serializes this DocumentIssue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DocumentIssue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentIssueCopyWith<DocumentIssue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentIssueCopyWith<$Res> {
  factory $DocumentIssueCopyWith(
          DocumentIssue value, $Res Function(DocumentIssue) then) =
      _$DocumentIssueCopyWithImpl<$Res, DocumentIssue>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'payment_id') String? paymentId,
      String kind,
      @JsonKey(name: 'document_number') String? documentNumber,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'client_name') String? clientName,
      @JsonKey(fromJson: nullableDecimalToDouble) double? amount,
      @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
      double? balanceAfter,
      @JsonKey(name: 'generated_at') DateTime generatedAt});
}

/// @nodoc
class _$DocumentIssueCopyWithImpl<$Res, $Val extends DocumentIssue>
    implements $DocumentIssueCopyWith<$Res> {
  _$DocumentIssueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DocumentIssue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? paymentId = freezed,
    Object? kind = null,
    Object? documentNumber = freezed,
    Object? orderNumber = null,
    Object? clientName = freezed,
    Object? amount = freezed,
    Object? balanceAfter = freezed,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      documentNumber: freezed == documentNumber
          ? _value.documentNumber
          : documentNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      balanceAfter: freezed == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as double?,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DocumentIssueImplCopyWith<$Res>
    implements $DocumentIssueCopyWith<$Res> {
  factory _$$DocumentIssueImplCopyWith(
          _$DocumentIssueImpl value, $Res Function(_$DocumentIssueImpl) then) =
      __$$DocumentIssueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'payment_id') String? paymentId,
      String kind,
      @JsonKey(name: 'document_number') String? documentNumber,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'client_name') String? clientName,
      @JsonKey(fromJson: nullableDecimalToDouble) double? amount,
      @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
      double? balanceAfter,
      @JsonKey(name: 'generated_at') DateTime generatedAt});
}

/// @nodoc
class __$$DocumentIssueImplCopyWithImpl<$Res>
    extends _$DocumentIssueCopyWithImpl<$Res, _$DocumentIssueImpl>
    implements _$$DocumentIssueImplCopyWith<$Res> {
  __$$DocumentIssueImplCopyWithImpl(
      _$DocumentIssueImpl _value, $Res Function(_$DocumentIssueImpl) _then)
      : super(_value, _then);

  /// Create a copy of DocumentIssue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? paymentId = freezed,
    Object? kind = null,
    Object? documentNumber = freezed,
    Object? orderNumber = null,
    Object? clientName = freezed,
    Object? amount = freezed,
    Object? balanceAfter = freezed,
    Object? generatedAt = null,
  }) {
    return _then(_$DocumentIssueImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      documentNumber: freezed == documentNumber
          ? _value.documentNumber
          : documentNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      balanceAfter: freezed == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as double?,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DocumentIssueImpl extends _DocumentIssue {
  const _$DocumentIssueImpl(
      {required this.id,
      @JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'payment_id') this.paymentId,
      required this.kind,
      @JsonKey(name: 'document_number') this.documentNumber,
      @JsonKey(name: 'order_number') required this.orderNumber,
      @JsonKey(name: 'client_name') this.clientName,
      @JsonKey(fromJson: nullableDecimalToDouble) this.amount,
      @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
      this.balanceAfter,
      @JsonKey(name: 'generated_at') required this.generatedAt})
      : super._();

  factory _$DocumentIssueImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocumentIssueImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'order_id')
  final String? orderId;
  @override
  @JsonKey(name: 'payment_id')
  final String? paymentId;

  /// 'invoice' | 'receipt' | 'work_order'.
  @override
  final String kind;
  @override
  @JsonKey(name: 'document_number')
  final String? documentNumber;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  @JsonKey(name: 'client_name')
  final String? clientName;
  @override
  @JsonKey(fromJson: nullableDecimalToDouble)
  final double? amount;
  @override
  @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
  final double? balanceAfter;
  @override
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;

  @override
  String toString() {
    return 'DocumentIssue(id: $id, orderId: $orderId, paymentId: $paymentId, kind: $kind, documentNumber: $documentNumber, orderNumber: $orderNumber, clientName: $clientName, amount: $amount, balanceAfter: $balanceAfter, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentIssueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.documentNumber, documentNumber) ||
                other.documentNumber == documentNumber) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.balanceAfter, balanceAfter) ||
                other.balanceAfter == balanceAfter) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      orderId,
      paymentId,
      kind,
      documentNumber,
      orderNumber,
      clientName,
      amount,
      balanceAfter,
      generatedAt);

  /// Create a copy of DocumentIssue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentIssueImplCopyWith<_$DocumentIssueImpl> get copyWith =>
      __$$DocumentIssueImplCopyWithImpl<_$DocumentIssueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DocumentIssueImplToJson(
      this,
    );
  }
}

abstract class _DocumentIssue extends DocumentIssue {
  const factory _DocumentIssue(
          {required final String id,
          @JsonKey(name: 'order_id') final String? orderId,
          @JsonKey(name: 'payment_id') final String? paymentId,
          required final String kind,
          @JsonKey(name: 'document_number') final String? documentNumber,
          @JsonKey(name: 'order_number') required final String orderNumber,
          @JsonKey(name: 'client_name') final String? clientName,
          @JsonKey(fromJson: nullableDecimalToDouble) final double? amount,
          @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
          final double? balanceAfter,
          @JsonKey(name: 'generated_at') required final DateTime generatedAt}) =
      _$DocumentIssueImpl;
  const _DocumentIssue._() : super._();

  factory _DocumentIssue.fromJson(Map<String, dynamic> json) =
      _$DocumentIssueImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'order_id')
  String? get orderId;
  @override
  @JsonKey(name: 'payment_id')
  String? get paymentId;

  /// 'invoice' | 'receipt' | 'work_order'.
  @override
  String get kind;
  @override
  @JsonKey(name: 'document_number')
  String? get documentNumber;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  @JsonKey(name: 'client_name')
  String? get clientName;
  @override
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get amount;
  @override
  @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
  double? get balanceAfter;
  @override
  @JsonKey(name: 'generated_at')
  DateTime get generatedAt;

  /// Create a copy of DocumentIssue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentIssueImplCopyWith<_$DocumentIssueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
