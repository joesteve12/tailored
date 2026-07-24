// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MeasurementField _$MeasurementFieldFromJson(Map<String, dynamic> json) {
  return _MeasurementField.fromJson(json);
}

/// @nodoc
mixin _$MeasurementField {
  String get id => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'value_type')
  String get valueType => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_archived')
  bool get isArchived => throw _privateConstructorUsedError;

  /// Serializes this MeasurementField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeasurementField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeasurementFieldCopyWith<MeasurementField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeasurementFieldCopyWith<$Res> {
  factory $MeasurementFieldCopyWith(
          MeasurementField value, $Res Function(MeasurementField) then) =
      _$MeasurementFieldCopyWithImpl<$Res, MeasurementField>;
  @useResult
  $Res call(
      {String id,
      String key,
      String label,
      String unit,
      @JsonKey(name: 'value_type') String valueType,
      String? description,
      @JsonKey(name: 'is_archived') bool isArchived});
}

/// @nodoc
class _$MeasurementFieldCopyWithImpl<$Res, $Val extends MeasurementField>
    implements $MeasurementFieldCopyWith<$Res> {
  _$MeasurementFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeasurementField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? label = null,
    Object? unit = null,
    Object? valueType = null,
    Object? description = freezed,
    Object? isArchived = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      valueType: null == valueType
          ? _value.valueType
          : valueType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeasurementFieldImplCopyWith<$Res>
    implements $MeasurementFieldCopyWith<$Res> {
  factory _$$MeasurementFieldImplCopyWith(_$MeasurementFieldImpl value,
          $Res Function(_$MeasurementFieldImpl) then) =
      __$$MeasurementFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String key,
      String label,
      String unit,
      @JsonKey(name: 'value_type') String valueType,
      String? description,
      @JsonKey(name: 'is_archived') bool isArchived});
}

/// @nodoc
class __$$MeasurementFieldImplCopyWithImpl<$Res>
    extends _$MeasurementFieldCopyWithImpl<$Res, _$MeasurementFieldImpl>
    implements _$$MeasurementFieldImplCopyWith<$Res> {
  __$$MeasurementFieldImplCopyWithImpl(_$MeasurementFieldImpl _value,
      $Res Function(_$MeasurementFieldImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeasurementField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? label = null,
    Object? unit = null,
    Object? valueType = null,
    Object? description = freezed,
    Object? isArchived = null,
  }) {
    return _then(_$MeasurementFieldImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      valueType: null == valueType
          ? _value.valueType
          : valueType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeasurementFieldImpl implements _MeasurementField {
  const _$MeasurementFieldImpl(
      {required this.id,
      required this.key,
      required this.label,
      required this.unit,
      @JsonKey(name: 'value_type') required this.valueType,
      this.description,
      @JsonKey(name: 'is_archived') required this.isArchived});

  factory _$MeasurementFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeasurementFieldImplFromJson(json);

  @override
  final String id;
  @override
  final String key;
  @override
  final String label;
  @override
  final String unit;
  @override
  @JsonKey(name: 'value_type')
  final String valueType;
  @override
  final String? description;
  @override
  @JsonKey(name: 'is_archived')
  final bool isArchived;

  @override
  String toString() {
    return 'MeasurementField(id: $id, key: $key, label: $label, unit: $unit, valueType: $valueType, description: $description, isArchived: $isArchived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeasurementFieldImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.valueType, valueType) ||
                other.valueType == valueType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, key, label, unit, valueType, description, isArchived);

  /// Create a copy of MeasurementField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeasurementFieldImplCopyWith<_$MeasurementFieldImpl> get copyWith =>
      __$$MeasurementFieldImplCopyWithImpl<_$MeasurementFieldImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeasurementFieldImplToJson(
      this,
    );
  }
}

abstract class _MeasurementField implements MeasurementField {
  const factory _MeasurementField(
          {required final String id,
          required final String key,
          required final String label,
          required final String unit,
          @JsonKey(name: 'value_type') required final String valueType,
          final String? description,
          @JsonKey(name: 'is_archived') required final bool isArchived}) =
      _$MeasurementFieldImpl;

  factory _MeasurementField.fromJson(Map<String, dynamic> json) =
      _$MeasurementFieldImpl.fromJson;

  @override
  String get id;
  @override
  String get key;
  @override
  String get label;
  @override
  String get unit;
  @override
  @JsonKey(name: 'value_type')
  String get valueType;
  @override
  String? get description;
  @override
  @JsonKey(name: 'is_archived')
  bool get isArchived;

  /// Create a copy of MeasurementField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeasurementFieldImplCopyWith<_$MeasurementFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
