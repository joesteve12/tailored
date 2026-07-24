// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String get garmentType => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'fabrics')
  List<Fabric> get fabrics => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_type')
  String get recipientType => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_client_id')
  String? get recipientClientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'guest_recipient_id')
  String? get guestRecipientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'measurement_set_id')
  String? get measurementSetId => throw _privateConstructorUsedError;
  ItemProduction get production => throw _privateConstructorUsedError;
  @JsonKey(name: 'style_references')
  List<StyleReference> get styleReferences =>
      throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'garment_type') String garmentType,
      String? description,
      int quantity,
      @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
      double unitPrice,
      @JsonKey(name: 'fabrics') List<Fabric> fabrics,
      String? notes,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_client_id') String? recipientClientId,
      @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
      @JsonKey(name: 'measurement_set_id') String? measurementSetId,
      ItemProduction production,
      @JsonKey(name: 'style_references') List<StyleReference> styleReferences});

  $ItemProductionCopyWith<$Res> get production;
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? garmentType = null,
    Object? description = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? fabrics = null,
    Object? notes = freezed,
    Object? recipientType = null,
    Object? recipientClientId = freezed,
    Object? guestRecipientId = freezed,
    Object? measurementSetId = freezed,
    Object? production = null,
    Object? styleReferences = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      fabrics: null == fabrics
          ? _value.fabrics
          : fabrics // ignore: cast_nullable_to_non_nullable
              as List<Fabric>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientClientId: freezed == recipientClientId
          ? _value.recipientClientId
          : recipientClientId // ignore: cast_nullable_to_non_nullable
              as String?,
      guestRecipientId: freezed == guestRecipientId
          ? _value.guestRecipientId
          : guestRecipientId // ignore: cast_nullable_to_non_nullable
              as String?,
      measurementSetId: freezed == measurementSetId
          ? _value.measurementSetId
          : measurementSetId // ignore: cast_nullable_to_non_nullable
              as String?,
      production: null == production
          ? _value.production
          : production // ignore: cast_nullable_to_non_nullable
              as ItemProduction,
      styleReferences: null == styleReferences
          ? _value.styleReferences
          : styleReferences // ignore: cast_nullable_to_non_nullable
              as List<StyleReference>,
    ) as $Val);
  }

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ItemProductionCopyWith<$Res> get production {
    return $ItemProductionCopyWith<$Res>(_value.production, (value) {
      return _then(_value.copyWith(production: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
          _$OrderItemImpl value, $Res Function(_$OrderItemImpl) then) =
      __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'garment_type') String garmentType,
      String? description,
      int quantity,
      @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
      double unitPrice,
      @JsonKey(name: 'fabrics') List<Fabric> fabrics,
      String? notes,
      @JsonKey(name: 'recipient_type') String recipientType,
      @JsonKey(name: 'recipient_client_id') String? recipientClientId,
      @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
      @JsonKey(name: 'measurement_set_id') String? measurementSetId,
      ItemProduction production,
      @JsonKey(name: 'style_references') List<StyleReference> styleReferences});

  @override
  $ItemProductionCopyWith<$Res> get production;
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
      _$OrderItemImpl _value, $Res Function(_$OrderItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? garmentType = null,
    Object? description = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? fabrics = null,
    Object? notes = freezed,
    Object? recipientType = null,
    Object? recipientClientId = freezed,
    Object? guestRecipientId = freezed,
    Object? measurementSetId = freezed,
    Object? production = null,
    Object? styleReferences = null,
  }) {
    return _then(_$OrderItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      fabrics: null == fabrics
          ? _value._fabrics
          : fabrics // ignore: cast_nullable_to_non_nullable
              as List<Fabric>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientType: null == recipientType
          ? _value.recipientType
          : recipientType // ignore: cast_nullable_to_non_nullable
              as String,
      recipientClientId: freezed == recipientClientId
          ? _value.recipientClientId
          : recipientClientId // ignore: cast_nullable_to_non_nullable
              as String?,
      guestRecipientId: freezed == guestRecipientId
          ? _value.guestRecipientId
          : guestRecipientId // ignore: cast_nullable_to_non_nullable
              as String?,
      measurementSetId: freezed == measurementSetId
          ? _value.measurementSetId
          : measurementSetId // ignore: cast_nullable_to_non_nullable
              as String?,
      production: null == production
          ? _value.production
          : production // ignore: cast_nullable_to_non_nullable
              as ItemProduction,
      styleReferences: null == styleReferences
          ? _value._styleReferences
          : styleReferences // ignore: cast_nullable_to_non_nullable
              as List<StyleReference>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl extends _OrderItem {
  const _$OrderItemImpl(
      {required this.id,
      @JsonKey(name: 'garment_type') required this.garmentType,
      this.description,
      required this.quantity,
      @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
      required this.unitPrice,
      @JsonKey(name: 'fabrics') final List<Fabric> fabrics = const <Fabric>[],
      this.notes,
      @JsonKey(name: 'recipient_type') required this.recipientType,
      @JsonKey(name: 'recipient_client_id') this.recipientClientId,
      @JsonKey(name: 'guest_recipient_id') this.guestRecipientId,
      @JsonKey(name: 'measurement_set_id') this.measurementSetId,
      required this.production,
      @JsonKey(name: 'style_references')
      final List<StyleReference> styleReferences = const <StyleReference>[]})
      : _fabrics = fabrics,
        _styleReferences = styleReferences,
        super._();

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'garment_type')
  final String garmentType;
  @override
  final String? description;
  @override
  final int quantity;
  @override
  @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
  final double unitPrice;
  final List<Fabric> _fabrics;
  @override
  @JsonKey(name: 'fabrics')
  List<Fabric> get fabrics {
    if (_fabrics is EqualUnmodifiableListView) return _fabrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fabrics);
  }

  @override
  final String? notes;
  @override
  @JsonKey(name: 'recipient_type')
  final String recipientType;
  @override
  @JsonKey(name: 'recipient_client_id')
  final String? recipientClientId;
  @override
  @JsonKey(name: 'guest_recipient_id')
  final String? guestRecipientId;
  @override
  @JsonKey(name: 'measurement_set_id')
  final String? measurementSetId;
  @override
  final ItemProduction production;
  final List<StyleReference> _styleReferences;
  @override
  @JsonKey(name: 'style_references')
  List<StyleReference> get styleReferences {
    if (_styleReferences is EqualUnmodifiableListView) return _styleReferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_styleReferences);
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, garmentType: $garmentType, description: $description, quantity: $quantity, unitPrice: $unitPrice, fabrics: $fabrics, notes: $notes, recipientType: $recipientType, recipientClientId: $recipientClientId, guestRecipientId: $guestRecipientId, measurementSetId: $measurementSetId, production: $production, styleReferences: $styleReferences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            const DeepCollectionEquality().equals(other._fabrics, _fabrics) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.recipientType, recipientType) ||
                other.recipientType == recipientType) &&
            (identical(other.recipientClientId, recipientClientId) ||
                other.recipientClientId == recipientClientId) &&
            (identical(other.guestRecipientId, guestRecipientId) ||
                other.guestRecipientId == guestRecipientId) &&
            (identical(other.measurementSetId, measurementSetId) ||
                other.measurementSetId == measurementSetId) &&
            (identical(other.production, production) ||
                other.production == production) &&
            const DeepCollectionEquality()
                .equals(other._styleReferences, _styleReferences));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      garmentType,
      description,
      quantity,
      unitPrice,
      const DeepCollectionEquality().hash(_fabrics),
      notes,
      recipientType,
      recipientClientId,
      guestRecipientId,
      measurementSetId,
      production,
      const DeepCollectionEquality().hash(_styleReferences));

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(
      this,
    );
  }
}

abstract class _OrderItem extends OrderItem {
  const factory _OrderItem(
      {required final String id,
      @JsonKey(name: 'garment_type') required final String garmentType,
      final String? description,
      required final int quantity,
      @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
      required final double unitPrice,
      @JsonKey(name: 'fabrics') final List<Fabric> fabrics,
      final String? notes,
      @JsonKey(name: 'recipient_type') required final String recipientType,
      @JsonKey(name: 'recipient_client_id') final String? recipientClientId,
      @JsonKey(name: 'guest_recipient_id') final String? guestRecipientId,
      @JsonKey(name: 'measurement_set_id') final String? measurementSetId,
      required final ItemProduction production,
      @JsonKey(name: 'style_references')
      final List<StyleReference> styleReferences}) = _$OrderItemImpl;
  const _OrderItem._() : super._();

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'garment_type')
  String get garmentType;
  @override
  String? get description;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
  double get unitPrice;
  @override
  @JsonKey(name: 'fabrics')
  List<Fabric> get fabrics;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'recipient_type')
  String get recipientType;
  @override
  @JsonKey(name: 'recipient_client_id')
  String? get recipientClientId;
  @override
  @JsonKey(name: 'guest_recipient_id')
  String? get guestRecipientId;
  @override
  @JsonKey(name: 'measurement_set_id')
  String? get measurementSetId;
  @override
  ItemProduction get production;
  @override
  @JsonKey(name: 'style_references')
  List<StyleReference> get styleReferences;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
