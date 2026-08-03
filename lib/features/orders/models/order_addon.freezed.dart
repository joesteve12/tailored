// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_addon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderAddon _$OrderAddonFromJson(Map<String, dynamic> json) {
  return _OrderAddon.fromJson(json);
}

/// @nodoc
mixin _$OrderAddon {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(fromJson: decimalStringToDouble)
  double get amount => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderAddon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderAddon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderAddonCopyWith<OrderAddon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderAddonCopyWith<$Res> {
  factory $OrderAddonCopyWith(
          OrderAddon value, $Res Function(OrderAddon) then) =
      _$OrderAddonCopyWithImpl<$Res, OrderAddon>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      String label,
      @JsonKey(fromJson: decimalStringToDouble) double amount,
      int quantity,
      String? notes,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$OrderAddonCopyWithImpl<$Res, $Val extends OrderAddon>
    implements $OrderAddonCopyWith<$Res> {
  _$OrderAddonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderAddon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? label = null,
    Object? amount = null,
    Object? quantity = null,
    Object? notes = freezed,
    Object? createdAt = null,
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
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderAddonImplCopyWith<$Res>
    implements $OrderAddonCopyWith<$Res> {
  factory _$$OrderAddonImplCopyWith(
          _$OrderAddonImpl value, $Res Function(_$OrderAddonImpl) then) =
      __$$OrderAddonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_id') String orderId,
      String label,
      @JsonKey(fromJson: decimalStringToDouble) double amount,
      int quantity,
      String? notes,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$OrderAddonImplCopyWithImpl<$Res>
    extends _$OrderAddonCopyWithImpl<$Res, _$OrderAddonImpl>
    implements _$$OrderAddonImplCopyWith<$Res> {
  __$$OrderAddonImplCopyWithImpl(
      _$OrderAddonImpl _value, $Res Function(_$OrderAddonImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderAddon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? label = null,
    Object? amount = null,
    Object? quantity = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$OrderAddonImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderAddonImpl extends _OrderAddon {
  const _$OrderAddonImpl(
      {required this.id,
      @JsonKey(name: 'order_id') required this.orderId,
      required this.label,
      @JsonKey(fromJson: decimalStringToDouble) required this.amount,
      this.quantity = 1,
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt})
      : super._();

  factory _$OrderAddonImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderAddonImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  final String label;
  @override
  @JsonKey(fromJson: decimalStringToDouble)
  final double amount;
  @override
  @JsonKey()
  final int quantity;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'OrderAddon(id: $id, orderId: $orderId, label: $label, amount: $amount, quantity: $quantity, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderAddonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, orderId, label, amount, quantity, notes, createdAt);

  /// Create a copy of OrderAddon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderAddonImplCopyWith<_$OrderAddonImpl> get copyWith =>
      __$$OrderAddonImplCopyWithImpl<_$OrderAddonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderAddonImplToJson(
      this,
    );
  }
}

abstract class _OrderAddon extends OrderAddon {
  const factory _OrderAddon(
      {required final String id,
      @JsonKey(name: 'order_id') required final String orderId,
      required final String label,
      @JsonKey(fromJson: decimalStringToDouble) required final double amount,
      final int quantity,
      final String? notes,
      @JsonKey(name: 'created_at')
      required final DateTime createdAt}) = _$OrderAddonImpl;
  const _OrderAddon._() : super._();

  factory _OrderAddon.fromJson(Map<String, dynamic> json) =
      _$OrderAddonImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  String get label;
  @override
  @JsonKey(fromJson: decimalStringToDouble)
  double get amount;
  @override
  int get quantity;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of OrderAddon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderAddonImplCopyWith<_$OrderAddonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
