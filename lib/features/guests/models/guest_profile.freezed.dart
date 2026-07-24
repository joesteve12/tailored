// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guest_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GuestProfile _$GuestProfileFromJson(Map<String, dynamic> json) {
  return _GuestProfile.fromJson(json);
}

/// @nodoc
mixin _$GuestProfile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String get clientId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get relation => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_url')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this GuestProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GuestProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuestProfileCopyWith<GuestProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuestProfileCopyWith<$Res> {
  factory $GuestProfileCopyWith(
          GuestProfile value, $Res Function(GuestProfile) then) =
      _$GuestProfileCopyWithImpl<$Res, GuestProfile>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String clientId,
      String name,
      String? relation,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$GuestProfileCopyWithImpl<$Res, $Val extends GuestProfile>
    implements $GuestProfileCopyWith<$Res> {
  _$GuestProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuestProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? name = null,
    Object? relation = freezed,
    Object? photoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relation: freezed == relation
          ? _value.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GuestProfileImplCopyWith<$Res>
    implements $GuestProfileCopyWith<$Res> {
  factory _$$GuestProfileImplCopyWith(
          _$GuestProfileImpl value, $Res Function(_$GuestProfileImpl) then) =
      __$$GuestProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String clientId,
      String name,
      String? relation,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$GuestProfileImplCopyWithImpl<$Res>
    extends _$GuestProfileCopyWithImpl<$Res, _$GuestProfileImpl>
    implements _$$GuestProfileImplCopyWith<$Res> {
  __$$GuestProfileImplCopyWithImpl(
      _$GuestProfileImpl _value, $Res Function(_$GuestProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of GuestProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? name = null,
    Object? relation = freezed,
    Object? photoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$GuestProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relation: freezed == relation
          ? _value.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
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
class _$GuestProfileImpl implements _GuestProfile {
  const _$GuestProfileImpl(
      {required this.id,
      @JsonKey(name: 'client_id') required this.clientId,
      required this.name,
      this.relation,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$GuestProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$GuestProfileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  final String name;
  @override
  final String? relation;
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'GuestProfile(id: $id, clientId: $clientId, name: $name, relation: $relation, photoUrl: $photoUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuestProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relation, relation) ||
                other.relation == relation) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, clientId, name, relation, photoUrl, createdAt);

  /// Create a copy of GuestProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuestProfileImplCopyWith<_$GuestProfileImpl> get copyWith =>
      __$$GuestProfileImplCopyWithImpl<_$GuestProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GuestProfileImplToJson(
      this,
    );
  }
}

abstract class _GuestProfile implements GuestProfile {
  const factory _GuestProfile(
          {required final String id,
          @JsonKey(name: 'client_id') required final String clientId,
          required final String name,
          final String? relation,
          @JsonKey(name: 'photo_url') final String? photoUrl,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$GuestProfileImpl;

  factory _GuestProfile.fromJson(Map<String, dynamic> json) =
      _$GuestProfileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String get clientId;
  @override
  String get name;
  @override
  String? get relation;
  @override
  @JsonKey(name: 'photo_url')
  String? get photoUrl;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of GuestProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuestProfileImplCopyWith<_$GuestProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
