// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fabric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Fabric _$FabricFromJson(Map<String, dynamic> json) {
  return _Fabric.fromJson(json);
}

/// @nodoc
mixin _$Fabric {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_item_id')
  String get orderItemId => throw _privateConstructorUsedError;
  String get serial => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get quantity => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Fabric to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Fabric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FabricCopyWith<Fabric> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FabricCopyWith<$Res> {
  factory $FabricCopyWith(Fabric value, $Res Function(Fabric) then) =
      _$FabricCopyWithImpl<$Res, Fabric>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_item_id') String orderItemId,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$FabricCopyWithImpl<$Res, $Val extends Fabric>
    implements $FabricCopyWith<$Res> {
  _$FabricCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Fabric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderItemId = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FabricImplCopyWith<$Res> implements $FabricCopyWith<$Res> {
  factory _$$FabricImplCopyWith(
          _$FabricImpl value, $Res Function(_$FabricImpl) then) =
      __$$FabricImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_item_id') String orderItemId,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$FabricImplCopyWithImpl<$Res>
    extends _$FabricCopyWithImpl<$Res, _$FabricImpl>
    implements _$$FabricImplCopyWith<$Res> {
  __$$FabricImplCopyWithImpl(
      _$FabricImpl _value, $Res Function(_$FabricImpl) _then)
      : super(_value, _then);

  /// Create a copy of Fabric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderItemId = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$FabricImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      serial: null == serial
          ? _value.serial
          : serial // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
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
class _$FabricImpl implements _Fabric {
  const _$FabricImpl(
      {required this.id,
      @JsonKey(name: 'order_item_id') required this.orderItemId,
      required this.serial,
      this.details,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) this.quantity,
      this.unit,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$FabricImpl.fromJson(Map<String, dynamic> json) =>
      _$$FabricImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'order_item_id')
  final String orderItemId;
  @override
  final String serial;
  @override
  final String? details;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(fromJson: nullableDecimalToDouble)
  final double? quantity;
  @override
  final String? unit;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'Fabric(id: $id, orderItemId: $orderItemId, serial: $serial, details: $details, imageUrl: $imageUrl, quantity: $quantity, unit: $unit, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FabricImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderItemId, orderItemId) ||
                other.orderItemId == orderItemId) &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, orderItemId, serial, details,
      imageUrl, quantity, unit, createdAt);

  /// Create a copy of Fabric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FabricImplCopyWith<_$FabricImpl> get copyWith =>
      __$$FabricImplCopyWithImpl<_$FabricImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FabricImplToJson(
      this,
    );
  }
}

abstract class _Fabric implements Fabric {
  const factory _Fabric(
          {required final String id,
          @JsonKey(name: 'order_item_id') required final String orderItemId,
          required final String serial,
          final String? details,
          @JsonKey(name: 'image_url') final String? imageUrl,
          @JsonKey(fromJson: nullableDecimalToDouble) final double? quantity,
          final String? unit,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$FabricImpl;

  factory _Fabric.fromJson(Map<String, dynamic> json) = _$FabricImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'order_item_id')
  String get orderItemId;
  @override
  String get serial;
  @override
  String? get details;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get quantity;
  @override
  String? get unit;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of Fabric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FabricImplCopyWith<_$FabricImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
