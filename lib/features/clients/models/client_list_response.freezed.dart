// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClientListResponse _$ClientListResponseFromJson(Map<String, dynamic> json) {
  return _ClientListResponse.fromJson(json);
}

/// @nodoc
mixin _$ClientListResponse {
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_size')
  int get pageSize => throw _privateConstructorUsedError;
  List<Client> get results => throw _privateConstructorUsedError;

  /// Serializes this ClientListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientListResponseCopyWith<ClientListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientListResponseCopyWith<$Res> {
  factory $ClientListResponseCopyWith(
          ClientListResponse value, $Res Function(ClientListResponse) then) =
      _$ClientListResponseCopyWithImpl<$Res, ClientListResponse>;
  @useResult
  $Res call(
      {int total,
      int page,
      @JsonKey(name: 'page_size') int pageSize,
      List<Client> results});
}

/// @nodoc
class _$ClientListResponseCopyWithImpl<$Res, $Val extends ClientListResponse>
    implements $ClientListResponseCopyWith<$Res> {
  _$ClientListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
    Object? results = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<Client>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientListResponseImplCopyWith<$Res>
    implements $ClientListResponseCopyWith<$Res> {
  factory _$$ClientListResponseImplCopyWith(_$ClientListResponseImpl value,
          $Res Function(_$ClientListResponseImpl) then) =
      __$$ClientListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int total,
      int page,
      @JsonKey(name: 'page_size') int pageSize,
      List<Client> results});
}

/// @nodoc
class __$$ClientListResponseImplCopyWithImpl<$Res>
    extends _$ClientListResponseCopyWithImpl<$Res, _$ClientListResponseImpl>
    implements _$$ClientListResponseImplCopyWith<$Res> {
  __$$ClientListResponseImplCopyWithImpl(_$ClientListResponseImpl _value,
      $Res Function(_$ClientListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
    Object? results = null,
  }) {
    return _then(_$ClientListResponseImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<Client>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientListResponseImpl implements _ClientListResponse {
  const _$ClientListResponseImpl(
      {required this.total,
      required this.page,
      @JsonKey(name: 'page_size') required this.pageSize,
      required final List<Client> results})
      : _results = results;

  factory _$ClientListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientListResponseImplFromJson(json);

  @override
  final int total;
  @override
  final int page;
  @override
  @JsonKey(name: 'page_size')
  final int pageSize;
  final List<Client> _results;
  @override
  List<Client> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'ClientListResponse(total: $total, page: $page, pageSize: $pageSize, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientListResponseImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, total, page, pageSize,
      const DeepCollectionEquality().hash(_results));

  /// Create a copy of ClientListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientListResponseImplCopyWith<_$ClientListResponseImpl> get copyWith =>
      __$$ClientListResponseImplCopyWithImpl<_$ClientListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientListResponseImplToJson(
      this,
    );
  }
}

abstract class _ClientListResponse implements ClientListResponse {
  const factory _ClientListResponse(
      {required final int total,
      required final int page,
      @JsonKey(name: 'page_size') required final int pageSize,
      required final List<Client> results}) = _$ClientListResponseImpl;

  factory _ClientListResponse.fromJson(Map<String, dynamic> json) =
      _$ClientListResponseImpl.fromJson;

  @override
  int get total;
  @override
  int get page;
  @override
  @JsonKey(name: 'page_size')
  int get pageSize;
  @override
  List<Client> get results;

  /// Create a copy of ClientListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientListResponseImplCopyWith<_$ClientListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
