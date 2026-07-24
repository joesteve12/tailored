// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'production_process.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProductionProcess _$ProductionProcessFromJson(Map<String, dynamic> json) {
  return _ProductionProcess.fromJson(json);
}

/// @nodoc
mixin _$ProductionProcess {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ProductionProcess to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductionProcess
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductionProcessCopyWith<ProductionProcess> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductionProcessCopyWith<$Res> {
  factory $ProductionProcessCopyWith(
          ProductionProcess value, $Res Function(ProductionProcess) then) =
      _$ProductionProcessCopyWithImpl<$Res, ProductionProcess>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$ProductionProcessCopyWithImpl<$Res, $Val extends ProductionProcess>
    implements $ProductionProcessCopyWith<$Res> {
  _$ProductionProcessCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductionProcess
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductionProcessImplCopyWith<$Res>
    implements $ProductionProcessCopyWith<$Res> {
  factory _$$ProductionProcessImplCopyWith(_$ProductionProcessImpl value,
          $Res Function(_$ProductionProcessImpl) then) =
      __$$ProductionProcessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$ProductionProcessImplCopyWithImpl<$Res>
    extends _$ProductionProcessCopyWithImpl<$Res, _$ProductionProcessImpl>
    implements _$$ProductionProcessImplCopyWith<$Res> {
  __$$ProductionProcessImplCopyWithImpl(_$ProductionProcessImpl _value,
      $Res Function(_$ProductionProcessImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProductionProcess
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? sortOrder = null,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_$ProductionProcessImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductionProcessImpl implements _ProductionProcess {
  const _$ProductionProcessImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'sort_order') required this.sortOrder,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$ProductionProcessImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductionProcessImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ProductionProcess(id: $id, name: $name, sortOrder: $sortOrder, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductionProcessImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, sortOrder, isActive, createdAt);

  /// Create a copy of ProductionProcess
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductionProcessImplCopyWith<_$ProductionProcessImpl> get copyWith =>
      __$$ProductionProcessImplCopyWithImpl<_$ProductionProcessImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductionProcessImplToJson(
      this,
    );
  }
}

abstract class _ProductionProcess implements ProductionProcess {
  const factory _ProductionProcess(
          {required final String id,
          required final String name,
          @JsonKey(name: 'sort_order') required final int sortOrder,
          @JsonKey(name: 'is_active') required final bool isActive,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$ProductionProcessImpl;

  factory _ProductionProcess.fromJson(Map<String, dynamic> json) =
      _$ProductionProcessImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ProductionProcess
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductionProcessImplCopyWith<_$ProductionProcessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
