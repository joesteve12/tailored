// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_summary_counts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TaskSummaryCounts _$TaskSummaryCountsFromJson(Map<String, dynamic> json) {
  return _TaskSummaryCounts.fromJson(json);
}

/// @nodoc
mixin _$TaskSummaryCounts {
  int get overdue => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_today')
  int get dueToday => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_tomorrow')
  int get dueTomorrow => throw _privateConstructorUsedError;

  /// Serializes this TaskSummaryCounts to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskSummaryCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskSummaryCountsCopyWith<TaskSummaryCounts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskSummaryCountsCopyWith<$Res> {
  factory $TaskSummaryCountsCopyWith(
          TaskSummaryCounts value, $Res Function(TaskSummaryCounts) then) =
      _$TaskSummaryCountsCopyWithImpl<$Res, TaskSummaryCounts>;
  @useResult
  $Res call(
      {int overdue,
      @JsonKey(name: 'due_today') int dueToday,
      @JsonKey(name: 'due_tomorrow') int dueTomorrow});
}

/// @nodoc
class _$TaskSummaryCountsCopyWithImpl<$Res, $Val extends TaskSummaryCounts>
    implements $TaskSummaryCountsCopyWith<$Res> {
  _$TaskSummaryCountsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskSummaryCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overdue = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
  }) {
    return _then(_value.copyWith(
      overdue: null == overdue
          ? _value.overdue
          : overdue // ignore: cast_nullable_to_non_nullable
              as int,
      dueToday: null == dueToday
          ? _value.dueToday
          : dueToday // ignore: cast_nullable_to_non_nullable
              as int,
      dueTomorrow: null == dueTomorrow
          ? _value.dueTomorrow
          : dueTomorrow // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskSummaryCountsImplCopyWith<$Res>
    implements $TaskSummaryCountsCopyWith<$Res> {
  factory _$$TaskSummaryCountsImplCopyWith(_$TaskSummaryCountsImpl value,
          $Res Function(_$TaskSummaryCountsImpl) then) =
      __$$TaskSummaryCountsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int overdue,
      @JsonKey(name: 'due_today') int dueToday,
      @JsonKey(name: 'due_tomorrow') int dueTomorrow});
}

/// @nodoc
class __$$TaskSummaryCountsImplCopyWithImpl<$Res>
    extends _$TaskSummaryCountsCopyWithImpl<$Res, _$TaskSummaryCountsImpl>
    implements _$$TaskSummaryCountsImplCopyWith<$Res> {
  __$$TaskSummaryCountsImplCopyWithImpl(_$TaskSummaryCountsImpl _value,
      $Res Function(_$TaskSummaryCountsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskSummaryCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overdue = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
  }) {
    return _then(_$TaskSummaryCountsImpl(
      overdue: null == overdue
          ? _value.overdue
          : overdue // ignore: cast_nullable_to_non_nullable
              as int,
      dueToday: null == dueToday
          ? _value.dueToday
          : dueToday // ignore: cast_nullable_to_non_nullable
              as int,
      dueTomorrow: null == dueTomorrow
          ? _value.dueTomorrow
          : dueTomorrow // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskSummaryCountsImpl extends _TaskSummaryCounts {
  const _$TaskSummaryCountsImpl(
      {required this.overdue,
      @JsonKey(name: 'due_today') required this.dueToday,
      @JsonKey(name: 'due_tomorrow') required this.dueTomorrow})
      : super._();

  factory _$TaskSummaryCountsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskSummaryCountsImplFromJson(json);

  @override
  final int overdue;
  @override
  @JsonKey(name: 'due_today')
  final int dueToday;
  @override
  @JsonKey(name: 'due_tomorrow')
  final int dueTomorrow;

  @override
  String toString() {
    return 'TaskSummaryCounts(overdue: $overdue, dueToday: $dueToday, dueTomorrow: $dueTomorrow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskSummaryCountsImpl &&
            (identical(other.overdue, overdue) || other.overdue == overdue) &&
            (identical(other.dueToday, dueToday) ||
                other.dueToday == dueToday) &&
            (identical(other.dueTomorrow, dueTomorrow) ||
                other.dueTomorrow == dueTomorrow));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, overdue, dueToday, dueTomorrow);

  /// Create a copy of TaskSummaryCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskSummaryCountsImplCopyWith<_$TaskSummaryCountsImpl> get copyWith =>
      __$$TaskSummaryCountsImplCopyWithImpl<_$TaskSummaryCountsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskSummaryCountsImplToJson(
      this,
    );
  }
}

abstract class _TaskSummaryCounts extends TaskSummaryCounts {
  const factory _TaskSummaryCounts(
          {required final int overdue,
          @JsonKey(name: 'due_today') required final int dueToday,
          @JsonKey(name: 'due_tomorrow') required final int dueTomorrow}) =
      _$TaskSummaryCountsImpl;
  const _TaskSummaryCounts._() : super._();

  factory _TaskSummaryCounts.fromJson(Map<String, dynamic> json) =
      _$TaskSummaryCountsImpl.fromJson;

  @override
  int get overdue;
  @override
  @JsonKey(name: 'due_today')
  int get dueToday;
  @override
  @JsonKey(name: 'due_tomorrow')
  int get dueTomorrow;

  /// Create a copy of TaskSummaryCounts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskSummaryCountsImplCopyWith<_$TaskSummaryCountsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
