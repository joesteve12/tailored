// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MeasurementValue _$MeasurementValueFromJson(Map<String, dynamic> json) {
  return _MeasurementValue.fromJson(json);
}

/// @nodoc
mixin _$MeasurementValue {
  @JsonKey(name: 'field_id')
  String get fieldId => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
  double? get valueNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'value_text')
  String? get valueText => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;

  /// Serializes this MeasurementValue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeasurementValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeasurementValueCopyWith<MeasurementValue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeasurementValueCopyWith<$Res> {
  factory $MeasurementValueCopyWith(
          MeasurementValue value, $Res Function(MeasurementValue) then) =
      _$MeasurementValueCopyWithImpl<$Res, MeasurementValue>;
  @useResult
  $Res call(
      {@JsonKey(name: 'field_id') String fieldId,
      String key,
      String label,
      @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
      double? valueNumber,
      @JsonKey(name: 'value_text') String? valueText,
      String? unit});
}

/// @nodoc
class _$MeasurementValueCopyWithImpl<$Res, $Val extends MeasurementValue>
    implements $MeasurementValueCopyWith<$Res> {
  _$MeasurementValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeasurementValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldId = null,
    Object? key = null,
    Object? label = null,
    Object? valueNumber = freezed,
    Object? valueText = freezed,
    Object? unit = freezed,
  }) {
    return _then(_value.copyWith(
      fieldId: null == fieldId
          ? _value.fieldId
          : fieldId // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      valueNumber: freezed == valueNumber
          ? _value.valueNumber
          : valueNumber // ignore: cast_nullable_to_non_nullable
              as double?,
      valueText: freezed == valueText
          ? _value.valueText
          : valueText // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeasurementValueImplCopyWith<$Res>
    implements $MeasurementValueCopyWith<$Res> {
  factory _$$MeasurementValueImplCopyWith(_$MeasurementValueImpl value,
          $Res Function(_$MeasurementValueImpl) then) =
      __$$MeasurementValueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'field_id') String fieldId,
      String key,
      String label,
      @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
      double? valueNumber,
      @JsonKey(name: 'value_text') String? valueText,
      String? unit});
}

/// @nodoc
class __$$MeasurementValueImplCopyWithImpl<$Res>
    extends _$MeasurementValueCopyWithImpl<$Res, _$MeasurementValueImpl>
    implements _$$MeasurementValueImplCopyWith<$Res> {
  __$$MeasurementValueImplCopyWithImpl(_$MeasurementValueImpl _value,
      $Res Function(_$MeasurementValueImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeasurementValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldId = null,
    Object? key = null,
    Object? label = null,
    Object? valueNumber = freezed,
    Object? valueText = freezed,
    Object? unit = freezed,
  }) {
    return _then(_$MeasurementValueImpl(
      fieldId: null == fieldId
          ? _value.fieldId
          : fieldId // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      valueNumber: freezed == valueNumber
          ? _value.valueNumber
          : valueNumber // ignore: cast_nullable_to_non_nullable
              as double?,
      valueText: freezed == valueText
          ? _value.valueText
          : valueText // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeasurementValueImpl extends _MeasurementValue {
  const _$MeasurementValueImpl(
      {@JsonKey(name: 'field_id') required this.fieldId,
      required this.key,
      required this.label,
      @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
      this.valueNumber,
      @JsonKey(name: 'value_text') this.valueText,
      this.unit})
      : super._();

  factory _$MeasurementValueImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeasurementValueImplFromJson(json);

  @override
  @JsonKey(name: 'field_id')
  final String fieldId;
  @override
  final String key;
  @override
  final String label;
  @override
  @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
  final double? valueNumber;
  @override
  @JsonKey(name: 'value_text')
  final String? valueText;
  @override
  final String? unit;

  @override
  String toString() {
    return 'MeasurementValue(fieldId: $fieldId, key: $key, label: $label, valueNumber: $valueNumber, valueText: $valueText, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeasurementValueImpl &&
            (identical(other.fieldId, fieldId) || other.fieldId == fieldId) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.valueNumber, valueNumber) ||
                other.valueNumber == valueNumber) &&
            (identical(other.valueText, valueText) ||
                other.valueText == valueText) &&
            (identical(other.unit, unit) || other.unit == unit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, fieldId, key, label, valueNumber, valueText, unit);

  /// Create a copy of MeasurementValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeasurementValueImplCopyWith<_$MeasurementValueImpl> get copyWith =>
      __$$MeasurementValueImplCopyWithImpl<_$MeasurementValueImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeasurementValueImplToJson(
      this,
    );
  }
}

abstract class _MeasurementValue extends MeasurementValue {
  const factory _MeasurementValue(
      {@JsonKey(name: 'field_id') required final String fieldId,
      required final String key,
      required final String label,
      @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
      final double? valueNumber,
      @JsonKey(name: 'value_text') final String? valueText,
      final String? unit}) = _$MeasurementValueImpl;
  const _MeasurementValue._() : super._();

  factory _MeasurementValue.fromJson(Map<String, dynamic> json) =
      _$MeasurementValueImpl.fromJson;

  @override
  @JsonKey(name: 'field_id')
  String get fieldId;
  @override
  String get key;
  @override
  String get label;
  @override
  @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
  double? get valueNumber;
  @override
  @JsonKey(name: 'value_text')
  String? get valueText;
  @override
  String? get unit;

  /// Create a copy of MeasurementValue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeasurementValueImplCopyWith<_$MeasurementValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MeasurementSet _$MeasurementSetFromJson(Map<String, dynamic> json) {
  return _MeasurementSet.fromJson(json);
}

/// @nodoc
mixin _$MeasurementSet {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String? get clientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'guest_recipient_id')
  String? get guestRecipientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'template_id')
  String? get templateId => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'taken_at')
  DateTime? get takenAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<MeasurementValue> get values => throw _privateConstructorUsedError;

  /// Serializes this MeasurementSet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeasurementSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeasurementSetCopyWith<MeasurementSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeasurementSetCopyWith<$Res> {
  factory $MeasurementSetCopyWith(
          MeasurementSet value, $Res Function(MeasurementSet) then) =
      _$MeasurementSetCopyWithImpl<$Res, MeasurementSet>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
      @JsonKey(name: 'template_id') String? templateId,
      String? label,
      String? notes,
      @JsonKey(name: 'taken_at') DateTime? takenAt,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<MeasurementValue> values});
}

/// @nodoc
class _$MeasurementSetCopyWithImpl<$Res, $Val extends MeasurementSet>
    implements $MeasurementSetCopyWith<$Res> {
  _$MeasurementSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeasurementSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = freezed,
    Object? guestRecipientId = freezed,
    Object? templateId = freezed,
    Object? label = freezed,
    Object? notes = freezed,
    Object? takenAt = freezed,
    Object? createdAt = null,
    Object? values = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
      guestRecipientId: freezed == guestRecipientId
          ? _value.guestRecipientId
          : guestRecipientId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      takenAt: freezed == takenAt
          ? _value.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<MeasurementValue>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeasurementSetImplCopyWith<$Res>
    implements $MeasurementSetCopyWith<$Res> {
  factory _$$MeasurementSetImplCopyWith(_$MeasurementSetImpl value,
          $Res Function(_$MeasurementSetImpl) then) =
      __$$MeasurementSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
      @JsonKey(name: 'template_id') String? templateId,
      String? label,
      String? notes,
      @JsonKey(name: 'taken_at') DateTime? takenAt,
      @JsonKey(name: 'created_at') DateTime createdAt,
      List<MeasurementValue> values});
}

/// @nodoc
class __$$MeasurementSetImplCopyWithImpl<$Res>
    extends _$MeasurementSetCopyWithImpl<$Res, _$MeasurementSetImpl>
    implements _$$MeasurementSetImplCopyWith<$Res> {
  __$$MeasurementSetImplCopyWithImpl(
      _$MeasurementSetImpl _value, $Res Function(_$MeasurementSetImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeasurementSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = freezed,
    Object? guestRecipientId = freezed,
    Object? templateId = freezed,
    Object? label = freezed,
    Object? notes = freezed,
    Object? takenAt = freezed,
    Object? createdAt = null,
    Object? values = null,
  }) {
    return _then(_$MeasurementSetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
      guestRecipientId: freezed == guestRecipientId
          ? _value.guestRecipientId
          : guestRecipientId // ignore: cast_nullable_to_non_nullable
              as String?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      takenAt: freezed == takenAt
          ? _value.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<MeasurementValue>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeasurementSetImpl implements _MeasurementSet {
  const _$MeasurementSetImpl(
      {required this.id,
      @JsonKey(name: 'client_id') this.clientId,
      @JsonKey(name: 'guest_recipient_id') this.guestRecipientId,
      @JsonKey(name: 'template_id') this.templateId,
      this.label,
      this.notes,
      @JsonKey(name: 'taken_at') this.takenAt,
      @JsonKey(name: 'created_at') required this.createdAt,
      final List<MeasurementValue> values = const <MeasurementValue>[]})
      : _values = values;

  factory _$MeasurementSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeasurementSetImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String? clientId;
  @override
  @JsonKey(name: 'guest_recipient_id')
  final String? guestRecipientId;
  @override
  @JsonKey(name: 'template_id')
  final String? templateId;
  @override
  final String? label;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'taken_at')
  final DateTime? takenAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<MeasurementValue> _values;
  @override
  @JsonKey()
  List<MeasurementValue> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  @override
  String toString() {
    return 'MeasurementSet(id: $id, clientId: $clientId, guestRecipientId: $guestRecipientId, templateId: $templateId, label: $label, notes: $notes, takenAt: $takenAt, createdAt: $createdAt, values: $values)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeasurementSetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.guestRecipientId, guestRecipientId) ||
                other.guestRecipientId == guestRecipientId) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._values, _values));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      clientId,
      guestRecipientId,
      templateId,
      label,
      notes,
      takenAt,
      createdAt,
      const DeepCollectionEquality().hash(_values));

  /// Create a copy of MeasurementSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeasurementSetImplCopyWith<_$MeasurementSetImpl> get copyWith =>
      __$$MeasurementSetImplCopyWithImpl<_$MeasurementSetImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeasurementSetImplToJson(
      this,
    );
  }
}

abstract class _MeasurementSet implements MeasurementSet {
  const factory _MeasurementSet(
      {required final String id,
      @JsonKey(name: 'client_id') final String? clientId,
      @JsonKey(name: 'guest_recipient_id') final String? guestRecipientId,
      @JsonKey(name: 'template_id') final String? templateId,
      final String? label,
      final String? notes,
      @JsonKey(name: 'taken_at') final DateTime? takenAt,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      final List<MeasurementValue> values}) = _$MeasurementSetImpl;

  factory _MeasurementSet.fromJson(Map<String, dynamic> json) =
      _$MeasurementSetImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String? get clientId;
  @override
  @JsonKey(name: 'guest_recipient_id')
  String? get guestRecipientId;
  @override
  @JsonKey(name: 'template_id')
  String? get templateId;
  @override
  String? get label;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'taken_at')
  DateTime? get takenAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  List<MeasurementValue> get values;

  /// Create a copy of MeasurementSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeasurementSetImplCopyWith<_$MeasurementSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
