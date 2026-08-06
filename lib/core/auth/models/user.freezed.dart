// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_name')
  String get businessName =>
      throw _privateConstructorUsedError; // Owner/contact name and address are collected at email/password signup
// but are nullable in the response: Google signups create the account
// before the profile is filled in, so both come back null for those users.
  @JsonKey(name: 'owner_name')
  String? get ownerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_address')
  String? get businessAddress =>
      throw _privateConstructorUsedError; // Clothing specializations. Always present (defaults to [] server-side for
// Google signups and older accounts), so a non-nullable list with a []
// fallback matches reality without risking a null-parse crash.
  @JsonKey(name: 'specializations')
  List<String> get specializations => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'auth_provider')
  String? get authProvider => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'business_name') String businessName,
      @JsonKey(name: 'owner_name') String? ownerName,
      @JsonKey(name: 'business_address') String? businessAddress,
      @JsonKey(name: 'specializations') List<String> specializations,
      String? phone,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'auth_provider') String? authProvider,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? businessName = null,
    Object? ownerName = freezed,
    Object? businessAddress = freezed,
    Object? specializations = null,
    Object? phone = freezed,
    Object? logoUrl = freezed,
    Object? authProvider = freezed,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      businessName: null == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      businessAddress: freezed == businessAddress
          ? _value.businessAddress
          : businessAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      specializations: null == specializations
          ? _value.specializations
          : specializations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      authProvider: freezed == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'business_name') String businessName,
      @JsonKey(name: 'owner_name') String? ownerName,
      @JsonKey(name: 'business_address') String? businessAddress,
      @JsonKey(name: 'specializations') List<String> specializations,
      String? phone,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'auth_provider') String? authProvider,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? businessName = null,
    Object? ownerName = freezed,
    Object? businessAddress = freezed,
    Object? specializations = null,
    Object? phone = freezed,
    Object? logoUrl = freezed,
    Object? authProvider = freezed,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      businessName: null == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      businessAddress: freezed == businessAddress
          ? _value.businessAddress
          : businessAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      specializations: null == specializations
          ? _value._specializations
          : specializations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      authProvider: freezed == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.email,
      @JsonKey(name: 'business_name') required this.businessName,
      @JsonKey(name: 'owner_name') this.ownerName,
      @JsonKey(name: 'business_address') this.businessAddress,
      @JsonKey(name: 'specializations')
      final List<String> specializations = const <String>[],
      this.phone,
      @JsonKey(name: 'logo_url') this.logoUrl,
      @JsonKey(name: 'auth_provider') this.authProvider,
      @JsonKey(name: 'is_active') required this.isActive,
      @JsonKey(name: 'created_at') required this.createdAt})
      : _specializations = specializations;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  @JsonKey(name: 'business_name')
  final String businessName;
// Owner/contact name and address are collected at email/password signup
// but are nullable in the response: Google signups create the account
// before the profile is filled in, so both come back null for those users.
  @override
  @JsonKey(name: 'owner_name')
  final String? ownerName;
  @override
  @JsonKey(name: 'business_address')
  final String? businessAddress;
// Clothing specializations. Always present (defaults to [] server-side for
// Google signups and older accounts), so a non-nullable list with a []
// fallback matches reality without risking a null-parse crash.
  final List<String> _specializations;
// Clothing specializations. Always present (defaults to [] server-side for
// Google signups and older accounts), so a non-nullable list with a []
// fallback matches reality without risking a null-parse crash.
  @override
  @JsonKey(name: 'specializations')
  List<String> get specializations {
    if (_specializations is EqualUnmodifiableListView) return _specializations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specializations);
  }

  @override
  final String? phone;
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @override
  @JsonKey(name: 'auth_provider')
  final String? authProvider;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'User(id: $id, email: $email, businessName: $businessName, ownerName: $ownerName, businessAddress: $businessAddress, specializations: $specializations, phone: $phone, logoUrl: $logoUrl, authProvider: $authProvider, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            (identical(other.businessAddress, businessAddress) ||
                other.businessAddress == businessAddress) &&
            const DeepCollectionEquality()
                .equals(other._specializations, _specializations) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.authProvider, authProvider) ||
                other.authProvider == authProvider) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      businessName,
      ownerName,
      businessAddress,
      const DeepCollectionEquality().hash(_specializations),
      phone,
      logoUrl,
      authProvider,
      isActive,
      createdAt);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
          {required final String id,
          required final String email,
          @JsonKey(name: 'business_name') required final String businessName,
          @JsonKey(name: 'owner_name') final String? ownerName,
          @JsonKey(name: 'business_address') final String? businessAddress,
          @JsonKey(name: 'specializations') final List<String> specializations,
          final String? phone,
          @JsonKey(name: 'logo_url') final String? logoUrl,
          @JsonKey(name: 'auth_provider') final String? authProvider,
          @JsonKey(name: 'is_active') required final bool isActive,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  @JsonKey(name: 'business_name')
  String
      get businessName; // Owner/contact name and address are collected at email/password signup
// but are nullable in the response: Google signups create the account
// before the profile is filled in, so both come back null for those users.
  @override
  @JsonKey(name: 'owner_name')
  String? get ownerName;
  @override
  @JsonKey(name: 'business_address')
  String?
      get businessAddress; // Clothing specializations. Always present (defaults to [] server-side for
// Google signups and older accounts), so a non-nullable list with a []
// fallback matches reality without risking a null-parse crash.
  @override
  @JsonKey(name: 'specializations')
  List<String> get specializations;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @override
  @JsonKey(name: 'auth_provider')
  String? get authProvider;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
