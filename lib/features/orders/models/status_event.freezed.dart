// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderStatusEvent _$OrderStatusEventFromJson(Map<String, dynamic> json) {
  return _OrderStatusEvent.fromJson(json);
}

/// @nodoc
mixin _$OrderStatusEvent {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_type')
  String get entityType => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_id')
  String? get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_label')
  String? get itemLabel => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_status')
  String get fromStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_status')
  String get toStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderStatusEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderStatusEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderStatusEventCopyWith<OrderStatusEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderStatusEventCopyWith<$Res> {
  factory $OrderStatusEventCopyWith(
          OrderStatusEvent value, $Res Function(OrderStatusEvent) then) =
      _$OrderStatusEventCopyWithImpl<$Res, OrderStatusEvent>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'entity_type') String entityType,
      @JsonKey(name: 'item_id') String? itemId,
      @JsonKey(name: 'item_label') String? itemLabel,
      @JsonKey(name: 'from_status') String fromStatus,
      @JsonKey(name: 'to_status') String toStatus,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$OrderStatusEventCopyWithImpl<$Res, $Val extends OrderStatusEvent>
    implements $OrderStatusEventCopyWith<$Res> {
  _$OrderStatusEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderStatusEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityType = null,
    Object? itemId = freezed,
    Object? itemLabel = freezed,
    Object? fromStatus = null,
    Object? toStatus = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: freezed == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      itemLabel: freezed == itemLabel
          ? _value.itemLabel
          : itemLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      fromStatus: null == fromStatus
          ? _value.fromStatus
          : fromStatus // ignore: cast_nullable_to_non_nullable
              as String,
      toStatus: null == toStatus
          ? _value.toStatus
          : toStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderStatusEventImplCopyWith<$Res>
    implements $OrderStatusEventCopyWith<$Res> {
  factory _$$OrderStatusEventImplCopyWith(_$OrderStatusEventImpl value,
          $Res Function(_$OrderStatusEventImpl) then) =
      __$$OrderStatusEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'entity_type') String entityType,
      @JsonKey(name: 'item_id') String? itemId,
      @JsonKey(name: 'item_label') String? itemLabel,
      @JsonKey(name: 'from_status') String fromStatus,
      @JsonKey(name: 'to_status') String toStatus,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$OrderStatusEventImplCopyWithImpl<$Res>
    extends _$OrderStatusEventCopyWithImpl<$Res, _$OrderStatusEventImpl>
    implements _$$OrderStatusEventImplCopyWith<$Res> {
  __$$OrderStatusEventImplCopyWithImpl(_$OrderStatusEventImpl _value,
      $Res Function(_$OrderStatusEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderStatusEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entityType = null,
    Object? itemId = freezed,
    Object? itemLabel = freezed,
    Object? fromStatus = null,
    Object? toStatus = null,
    Object? createdAt = null,
  }) {
    return _then(_$OrderStatusEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: freezed == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      itemLabel: freezed == itemLabel
          ? _value.itemLabel
          : itemLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      fromStatus: null == fromStatus
          ? _value.fromStatus
          : fromStatus // ignore: cast_nullable_to_non_nullable
              as String,
      toStatus: null == toStatus
          ? _value.toStatus
          : toStatus // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderStatusEventImpl implements _OrderStatusEvent {
  const _$OrderStatusEventImpl(
      {required this.id,
      @JsonKey(name: 'entity_type') required this.entityType,
      @JsonKey(name: 'item_id') this.itemId,
      @JsonKey(name: 'item_label') this.itemLabel,
      @JsonKey(name: 'from_status') required this.fromStatus,
      @JsonKey(name: 'to_status') required this.toStatus,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$OrderStatusEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderStatusEventImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'entity_type')
  final String entityType;
  @override
  @JsonKey(name: 'item_id')
  final String? itemId;
  @override
  @JsonKey(name: 'item_label')
  final String? itemLabel;
  @override
  @JsonKey(name: 'from_status')
  final String fromStatus;
  @override
  @JsonKey(name: 'to_status')
  final String toStatus;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'OrderStatusEvent(id: $id, entityType: $entityType, itemId: $itemId, itemLabel: $itemLabel, fromStatus: $fromStatus, toStatus: $toStatus, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderStatusEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemLabel, itemLabel) ||
                other.itemLabel == itemLabel) &&
            (identical(other.fromStatus, fromStatus) ||
                other.fromStatus == fromStatus) &&
            (identical(other.toStatus, toStatus) ||
                other.toStatus == toStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, entityType, itemId,
      itemLabel, fromStatus, toStatus, createdAt);

  /// Create a copy of OrderStatusEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderStatusEventImplCopyWith<_$OrderStatusEventImpl> get copyWith =>
      __$$OrderStatusEventImplCopyWithImpl<_$OrderStatusEventImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderStatusEventImplToJson(
      this,
    );
  }
}

abstract class _OrderStatusEvent implements OrderStatusEvent {
  const factory _OrderStatusEvent(
          {required final String id,
          @JsonKey(name: 'entity_type') required final String entityType,
          @JsonKey(name: 'item_id') final String? itemId,
          @JsonKey(name: 'item_label') final String? itemLabel,
          @JsonKey(name: 'from_status') required final String fromStatus,
          @JsonKey(name: 'to_status') required final String toStatus,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$OrderStatusEventImpl;

  factory _OrderStatusEvent.fromJson(Map<String, dynamic> json) =
      _$OrderStatusEventImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'entity_type')
  String get entityType;
  @override
  @JsonKey(name: 'item_id')
  String? get itemId;
  @override
  @JsonKey(name: 'item_label')
  String? get itemLabel;
  @override
  @JsonKey(name: 'from_status')
  String get fromStatus;
  @override
  @JsonKey(name: 'to_status')
  String get toStatus;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of OrderStatusEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderStatusEventImplCopyWith<_$OrderStatusEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
