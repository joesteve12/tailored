// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fabric_inventory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FabricInventoryItem _$FabricInventoryItemFromJson(Map<String, dynamic> json) {
  return _FabricInventoryItem.fromJson(json);
}

/// @nodoc
mixin _$FabricInventoryItem {
  String get id => throw _privateConstructorUsedError;
  String get serial => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get quantity => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_item_id')
  String get orderItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String get garmentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_state')
  String get productionState => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_type')
  String get recipientType => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_name')
  String? get recipientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FabricInventoryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FabricInventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FabricInventoryItemCopyWith<FabricInventoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FabricInventoryItemCopyWith<$Res> {
  factory $FabricInventoryItemCopyWith(
          FabricInventoryItem value, $Res Function(FabricInventoryItem) then) =
      _$FabricInventoryItemCopyWithImpl<$Res, FabricInventoryItem>;
  @useResult
  $Res call(
      {String id,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$FabricInventoryItemCopyWithImpl<$Res, $Val extends FabricInventoryItem>
    implements $FabricInventoryItemCopyWith<$Res> {
  _$FabricInventoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FabricInventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? orderItemId = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? recipientType = null,
    Object? recipientName = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FabricInventoryItemImplCopyWith<$Res>
    implements $FabricInventoryItemCopyWith<$Res> {
  factory _$$FabricInventoryItemImplCopyWith(_$FabricInventoryItemImpl value,
          $Res Function(_$FabricInventoryItemImpl) then) =
      __$$FabricInventoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$FabricInventoryItemImplCopyWithImpl<$Res>
    extends _$FabricInventoryItemCopyWithImpl<$Res, _$FabricInventoryItemImpl>
    implements _$$FabricInventoryItemImplCopyWith<$Res> {
  __$$FabricInventoryItemImplCopyWithImpl(_$FabricInventoryItemImpl _value,
      $Res Function(_$FabricInventoryItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of FabricInventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? orderItemId = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? recipientType = null,
    Object? recipientName = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$FabricInventoryItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FabricInventoryItemImpl implements _FabricInventoryItem {
  const _$FabricInventoryItemImpl(
      {required this.id,
      required this.serial,
      this.details,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) this.quantity,
      this.unit,
      @JsonKey(name: 'order_item_id') required this.orderItemId,
      @JsonKey(name: 'order_id') required this.orderId,
      @JsonKey(name: 'order_number') required this.orderNumber,
      @JsonKey(name: 'garment_type') required this.garmentType,
      @JsonKey(name: 'production_state') required this.productionState,
      @JsonKey(name: 'recipient_type') required this.recipientType,
      @JsonKey(name: 'recipient_name') this.recipientName,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$FabricInventoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FabricInventoryItemImplFromJson(json);

  @override
  final String id;
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
  @JsonKey(name: 'order_item_id')
  final String orderItemId;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  @JsonKey(name: 'garment_type')
  final String garmentType;
  @override
  @JsonKey(name: 'production_state')
  final String productionState;
  @override
  @JsonKey(name: 'recipient_type')
  final String recipientType;
  @override
  @JsonKey(name: 'recipient_name')
  final String? recipientName;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'FabricInventoryItem(id: $id, serial: $serial, details: $details, imageUrl: $imageUrl, quantity: $quantity, unit: $unit, orderItemId: $orderItemId, orderId: $orderId, orderNumber: $orderNumber, garmentType: $garmentType, productionState: $productionState, recipientType: $recipientType, recipientName: $recipientName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FabricInventoryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.orderItemId, orderItemId) ||
                other.orderItemId == orderItemId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.productionState, productionState) ||
                other.productionState == productionState) &&
            (identical(other.recipientType, recipientType) ||
                other.recipientType == recipientType) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      serial,
      details,
      imageUrl,
      quantity,
      unit,
      orderItemId,
      orderId,
      orderNumber,
      garmentType,
      productionState,
      recipientType,
      recipientName,
      createdAt);

  /// Create a copy of FabricInventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FabricInventoryItemImplCopyWith<_$FabricInventoryItemImpl> get copyWith =>
      __$$FabricInventoryItemImplCopyWithImpl<_$FabricInventoryItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FabricInventoryItemImplToJson(
      this,
    );
  }
}

abstract class _FabricInventoryItem implements FabricInventoryItem {
  const factory _FabricInventoryItem(
      {required final String id,
      required final String serial,
      final String? details,
      @JsonKey(name: 'image_url') final String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) final double? quantity,
      final String? unit,
      @JsonKey(name: 'order_item_id') required final String orderItemId,
      @JsonKey(name: 'order_id') required final String orderId,
      @JsonKey(name: 'order_number') required final String orderNumber,
      @JsonKey(name: 'garment_type') required final String garmentType,
      @JsonKey(name: 'production_state') required final String productionState,
      @JsonKey(name: 'recipient_type') required final String recipientType,
      @JsonKey(name: 'recipient_name') final String? recipientName,
      @JsonKey(name: 'created_at')
      final DateTime? createdAt}) = _$FabricInventoryItemImpl;

  factory _FabricInventoryItem.fromJson(Map<String, dynamic> json) =
      _$FabricInventoryItemImpl.fromJson;

  @override
  String get id;
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
  @JsonKey(name: 'order_item_id')
  String get orderItemId;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  @JsonKey(name: 'garment_type')
  String get garmentType;
  @override
  @JsonKey(name: 'production_state')
  String get productionState;
  @override
  @JsonKey(name: 'recipient_type')
  String get recipientType;
  @override
  @JsonKey(name: 'recipient_name')
  String? get recipientName;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of FabricInventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FabricInventoryItemImplCopyWith<_$FabricInventoryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FabricInventoryDetail _$FabricInventoryDetailFromJson(
    Map<String, dynamic> json) {
  return _FabricInventoryDetail.fromJson(json);
}

/// @nodoc
mixin _$FabricInventoryDetail {
  String get id => throw _privateConstructorUsedError;
  String get serial => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDecimalToDouble)
  double? get quantity => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_item_id')
  String get orderItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String get garmentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_state')
  String get productionState => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_type')
  String get recipientType => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_name')
  String? get recipientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_status')
  String? get orderStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_phone')
  String? get recipientPhone => throw _privateConstructorUsedError;

  /// Serializes this FabricInventoryDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FabricInventoryDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FabricInventoryDetailCopyWith<FabricInventoryDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FabricInventoryDetailCopyWith<$Res> {
  factory $FabricInventoryDetailCopyWith(FabricInventoryDetail value,
          $Res Function(FabricInventoryDetail) then) =
      _$FabricInventoryDetailCopyWithImpl<$Res, FabricInventoryDetail>;
  @useResult
  $Res call(
      {String id,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'order_status') String? orderStatus,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'recipient_phone') String? recipientPhone});
}

/// @nodoc
class _$FabricInventoryDetailCopyWithImpl<$Res,
        $Val extends FabricInventoryDetail>
    implements $FabricInventoryDetailCopyWith<$Res> {
  _$FabricInventoryDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FabricInventoryDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? orderItemId = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? recipientType = null,
    Object? recipientName = freezed,
    Object? createdAt = freezed,
    Object? orderStatus = freezed,
    Object? dueDate = freezed,
    Object? recipientPhone = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderStatus: freezed == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      recipientPhone: freezed == recipientPhone
          ? _value.recipientPhone
          : recipientPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FabricInventoryDetailImplCopyWith<$Res>
    implements $FabricInventoryDetailCopyWith<$Res> {
  factory _$$FabricInventoryDetailImplCopyWith(
          _$FabricInventoryDetailImpl value,
          $Res Function(_$FabricInventoryDetailImpl) then) =
      __$$FabricInventoryDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String serial,
      String? details,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
      String? unit,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'order_status') String? orderStatus,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'recipient_phone') String? recipientPhone});
}

/// @nodoc
class __$$FabricInventoryDetailImplCopyWithImpl<$Res>
    extends _$FabricInventoryDetailCopyWithImpl<$Res,
        _$FabricInventoryDetailImpl>
    implements _$$FabricInventoryDetailImplCopyWith<$Res> {
  __$$FabricInventoryDetailImplCopyWithImpl(_$FabricInventoryDetailImpl _value,
      $Res Function(_$FabricInventoryDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of FabricInventoryDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serial = null,
    Object? details = freezed,
    Object? imageUrl = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? orderItemId = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? recipientType = null,
    Object? recipientName = freezed,
    Object? createdAt = freezed,
    Object? orderStatus = freezed,
    Object? dueDate = freezed,
    Object? recipientPhone = freezed,
  }) {
    return _then(_$FabricInventoryDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderStatus: freezed == orderStatus
          ? _value.orderStatus
          : orderStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      recipientPhone: freezed == recipientPhone
          ? _value.recipientPhone
          : recipientPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FabricInventoryDetailImpl implements _FabricInventoryDetail {
  const _$FabricInventoryDetailImpl(
      {required this.id,
      required this.serial,
      this.details,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) this.quantity,
      this.unit,
      @JsonKey(name: 'order_item_id') required this.orderItemId,
      @JsonKey(name: 'order_id') required this.orderId,
      @JsonKey(name: 'order_number') required this.orderNumber,
      @JsonKey(name: 'garment_type') required this.garmentType,
      @JsonKey(name: 'production_state') required this.productionState,
      @JsonKey(name: 'recipient_type') required this.recipientType,
      @JsonKey(name: 'recipient_name') this.recipientName,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'order_status') this.orderStatus,
      @JsonKey(name: 'due_date') this.dueDate,
      @JsonKey(name: 'recipient_phone') this.recipientPhone});

  factory _$FabricInventoryDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$FabricInventoryDetailImplFromJson(json);

  @override
  final String id;
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
  @JsonKey(name: 'order_item_id')
  final String orderItemId;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  @JsonKey(name: 'garment_type')
  final String garmentType;
  @override
  @JsonKey(name: 'production_state')
  final String productionState;
  @override
  @JsonKey(name: 'recipient_type')
  final String recipientType;
  @override
  @JsonKey(name: 'recipient_name')
  final String? recipientName;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'order_status')
  final String? orderStatus;
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'recipient_phone')
  final String? recipientPhone;

  @override
  String toString() {
    return 'FabricInventoryDetail(id: $id, serial: $serial, details: $details, imageUrl: $imageUrl, quantity: $quantity, unit: $unit, orderItemId: $orderItemId, orderId: $orderId, orderNumber: $orderNumber, garmentType: $garmentType, productionState: $productionState, recipientType: $recipientType, recipientName: $recipientName, createdAt: $createdAt, orderStatus: $orderStatus, dueDate: $dueDate, recipientPhone: $recipientPhone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FabricInventoryDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.orderItemId, orderItemId) ||
                other.orderItemId == orderItemId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.productionState, productionState) ||
                other.productionState == productionState) &&
            (identical(other.recipientType, recipientType) ||
                other.recipientType == recipientType) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.orderStatus, orderStatus) ||
                other.orderStatus == orderStatus) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.recipientPhone, recipientPhone) ||
                other.recipientPhone == recipientPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      serial,
      details,
      imageUrl,
      quantity,
      unit,
      orderItemId,
      orderId,
      orderNumber,
      garmentType,
      productionState,
      recipientType,
      recipientName,
      createdAt,
      orderStatus,
      dueDate,
      recipientPhone);

  /// Create a copy of FabricInventoryDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FabricInventoryDetailImplCopyWith<_$FabricInventoryDetailImpl>
      get copyWith => __$$FabricInventoryDetailImplCopyWithImpl<
          _$FabricInventoryDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FabricInventoryDetailImplToJson(
      this,
    );
  }
}

abstract class _FabricInventoryDetail implements FabricInventoryDetail {
  const factory _FabricInventoryDetail(
      {required final String id,
      required final String serial,
      final String? details,
      @JsonKey(name: 'image_url') final String? imageUrl,
      @JsonKey(fromJson: nullableDecimalToDouble) final double? quantity,
      final String? unit,
      @JsonKey(name: 'order_item_id') required final String orderItemId,
      @JsonKey(name: 'order_id') required final String orderId,
      @JsonKey(name: 'order_number') required final String orderNumber,
      @JsonKey(name: 'garment_type') required final String garmentType,
      @JsonKey(name: 'production_state') required final String productionState,
      @JsonKey(name: 'recipient_type') required final String recipientType,
      @JsonKey(name: 'recipient_name') final String? recipientName,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'order_status') final String? orderStatus,
      @JsonKey(name: 'due_date') final DateTime? dueDate,
      @JsonKey(name: 'recipient_phone')
      final String? recipientPhone}) = _$FabricInventoryDetailImpl;

  factory _FabricInventoryDetail.fromJson(Map<String, dynamic> json) =
      _$FabricInventoryDetailImpl.fromJson;

  @override
  String get id;
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
  @JsonKey(name: 'order_item_id')
  String get orderItemId;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  @JsonKey(name: 'garment_type')
  String get garmentType;
  @override
  @JsonKey(name: 'production_state')
  String get productionState;
  @override
  @JsonKey(name: 'recipient_type')
  String get recipientType;
  @override
  @JsonKey(name: 'recipient_name')
  String? get recipientName;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'order_status')
  String? get orderStatus;
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'recipient_phone')
  String? get recipientPhone;

  /// Create a copy of FabricInventoryDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FabricInventoryDetailImplCopyWith<_$FabricInventoryDetailImpl>
      get copyWith => throw _privateConstructorUsedError;
}
