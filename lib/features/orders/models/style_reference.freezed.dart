// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'style_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StyleReference _$StyleReferenceFromJson(Map<String, dynamic> json) {
  return _StyleReference.fromJson(json);
}

/// @nodoc
mixin _$StyleReference {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_url')
  String get fileUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String get fileType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StyleReference to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StyleReference
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StyleReferenceCopyWith<StyleReference> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StyleReferenceCopyWith<$Res> {
  factory $StyleReferenceCopyWith(
          StyleReference value, $Res Function(StyleReference) then) =
      _$StyleReferenceCopyWithImpl<$Res, StyleReference>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_url') String fileUrl,
      @JsonKey(name: 'file_type') String fileType,
      String? notes,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$StyleReferenceCopyWithImpl<$Res, $Val extends StyleReference>
    implements $StyleReferenceCopyWith<$Res> {
  _$StyleReferenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StyleReference
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileUrl = null,
    Object? fileType = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$StyleReferenceImplCopyWith<$Res>
    implements $StyleReferenceCopyWith<$Res> {
  factory _$$StyleReferenceImplCopyWith(_$StyleReferenceImpl value,
          $Res Function(_$StyleReferenceImpl) then) =
      __$$StyleReferenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_url') String fileUrl,
      @JsonKey(name: 'file_type') String fileType,
      String? notes,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$StyleReferenceImplCopyWithImpl<$Res>
    extends _$StyleReferenceCopyWithImpl<$Res, _$StyleReferenceImpl>
    implements _$$StyleReferenceImplCopyWith<$Res> {
  __$$StyleReferenceImplCopyWithImpl(
      _$StyleReferenceImpl _value, $Res Function(_$StyleReferenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of StyleReference
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileUrl = null,
    Object? fileType = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$StyleReferenceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$StyleReferenceImpl implements _StyleReference {
  const _$StyleReferenceImpl(
      {required this.id,
      @JsonKey(name: 'file_url') required this.fileUrl,
      @JsonKey(name: 'file_type') this.fileType = 'image',
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$StyleReferenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$StyleReferenceImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @override
  @JsonKey(name: 'file_type')
  final String fileType;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'StyleReference(id: $id, fileUrl: $fileUrl, fileType: $fileType, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StyleReferenceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, fileUrl, fileType, notes, createdAt);

  /// Create a copy of StyleReference
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StyleReferenceImplCopyWith<_$StyleReferenceImpl> get copyWith =>
      __$$StyleReferenceImplCopyWithImpl<_$StyleReferenceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StyleReferenceImplToJson(
      this,
    );
  }
}

abstract class _StyleReference implements StyleReference {
  const factory _StyleReference(
          {required final String id,
          @JsonKey(name: 'file_url') required final String fileUrl,
          @JsonKey(name: 'file_type') final String fileType,
          final String? notes,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$StyleReferenceImpl;

  factory _StyleReference.fromJson(Map<String, dynamic> json) =
      _$StyleReferenceImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'file_url')
  String get fileUrl;
  @override
  @JsonKey(name: 'file_type')
  String get fileType;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of StyleReference
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StyleReferenceImplCopyWith<_$StyleReferenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
