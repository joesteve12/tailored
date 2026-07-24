// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderMedia _$OrderMediaFromJson(Map<String, dynamic> json) {
  return _OrderMedia.fromJson(json);
}

/// @nodoc
mixin _$OrderMedia {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_url')
  String get fileUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String get fileType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderMedia to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderMediaCopyWith<OrderMedia> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderMediaCopyWith<$Res> {
  factory $OrderMediaCopyWith(
          OrderMedia value, $Res Function(OrderMedia) then) =
      _$OrderMediaCopyWithImpl<$Res, OrderMedia>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_url') String fileUrl,
      @JsonKey(name: 'file_type') String fileType,
      String? notes,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$OrderMediaCopyWithImpl<$Res, $Val extends OrderMedia>
    implements $OrderMediaCopyWith<$Res> {
  _$OrderMediaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderMedia
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
abstract class _$$OrderMediaImplCopyWith<$Res>
    implements $OrderMediaCopyWith<$Res> {
  factory _$$OrderMediaImplCopyWith(
          _$OrderMediaImpl value, $Res Function(_$OrderMediaImpl) then) =
      __$$OrderMediaImplCopyWithImpl<$Res>;
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
class __$$OrderMediaImplCopyWithImpl<$Res>
    extends _$OrderMediaCopyWithImpl<$Res, _$OrderMediaImpl>
    implements _$$OrderMediaImplCopyWith<$Res> {
  __$$OrderMediaImplCopyWithImpl(
      _$OrderMediaImpl _value, $Res Function(_$OrderMediaImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderMedia
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
    return _then(_$OrderMediaImpl(
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
class _$OrderMediaImpl implements _OrderMedia {
  const _$OrderMediaImpl(
      {required this.id,
      @JsonKey(name: 'file_url') required this.fileUrl,
      @JsonKey(name: 'file_type') this.fileType = 'image',
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$OrderMediaImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderMediaImplFromJson(json);

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
    return 'OrderMedia(id: $id, fileUrl: $fileUrl, fileType: $fileType, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderMediaImpl &&
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

  /// Create a copy of OrderMedia
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderMediaImplCopyWith<_$OrderMediaImpl> get copyWith =>
      __$$OrderMediaImplCopyWithImpl<_$OrderMediaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderMediaImplToJson(
      this,
    );
  }
}

abstract class _OrderMedia implements OrderMedia {
  const factory _OrderMedia(
          {required final String id,
          @JsonKey(name: 'file_url') required final String fileUrl,
          @JsonKey(name: 'file_type') final String fileType,
          final String? notes,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$OrderMediaImpl;

  factory _OrderMedia.fromJson(Map<String, dynamic> json) =
      _$OrderMediaImpl.fromJson;

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

  /// Create a copy of OrderMedia
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderMediaImplCopyWith<_$OrderMediaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
