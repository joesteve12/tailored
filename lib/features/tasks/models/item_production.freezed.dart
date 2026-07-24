// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_production.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemProduction _$ItemProductionFromJson(Map<String, dynamic> json) {
  return _ItemProduction.fromJson(json);
}

/// @nodoc
mixin _$ItemProduction {
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_stage_name')
  String? get currentStageName => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_stage_started')
  bool get currentStageStarted => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_id')
  String? get taskId => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_overdue')
  bool get isOverdue => throw _privateConstructorUsedError;

  /// Serializes this ItemProduction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemProduction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemProductionCopyWith<ItemProduction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemProductionCopyWith<$Res> {
  factory $ItemProductionCopyWith(
          ItemProduction value, $Res Function(ItemProduction) then) =
      _$ItemProductionCopyWithImpl<$Res, ItemProduction>;
  @useResult
  $Res call(
      {String state,
      @JsonKey(name: 'current_stage_name') String? currentStageName,
      @JsonKey(name: 'current_stage_started') bool currentStageStarted,
      @JsonKey(name: 'task_id') String? taskId,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      @JsonKey(name: 'is_overdue') bool isOverdue});
}

/// @nodoc
class _$ItemProductionCopyWithImpl<$Res, $Val extends ItemProduction>
    implements $ItemProductionCopyWith<$Res> {
  _$ItemProductionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemProduction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? currentStageName = freezed,
    Object? currentStageStarted = null,
    Object? taskId = freezed,
    Object? expectedCompletionDate = freezed,
    Object? isOverdue = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      currentStageName: freezed == currentStageName
          ? _value.currentStageName
          : currentStageName // ignore: cast_nullable_to_non_nullable
              as String?,
      currentStageStarted: null == currentStageStarted
          ? _value.currentStageStarted
          : currentStageStarted // ignore: cast_nullable_to_non_nullable
              as bool,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedCompletionDate: freezed == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isOverdue: null == isOverdue
          ? _value.isOverdue
          : isOverdue // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemProductionImplCopyWith<$Res>
    implements $ItemProductionCopyWith<$Res> {
  factory _$$ItemProductionImplCopyWith(_$ItemProductionImpl value,
          $Res Function(_$ItemProductionImpl) then) =
      __$$ItemProductionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String state,
      @JsonKey(name: 'current_stage_name') String? currentStageName,
      @JsonKey(name: 'current_stage_started') bool currentStageStarted,
      @JsonKey(name: 'task_id') String? taskId,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      @JsonKey(name: 'is_overdue') bool isOverdue});
}

/// @nodoc
class __$$ItemProductionImplCopyWithImpl<$Res>
    extends _$ItemProductionCopyWithImpl<$Res, _$ItemProductionImpl>
    implements _$$ItemProductionImplCopyWith<$Res> {
  __$$ItemProductionImplCopyWithImpl(
      _$ItemProductionImpl _value, $Res Function(_$ItemProductionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemProduction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? currentStageName = freezed,
    Object? currentStageStarted = null,
    Object? taskId = freezed,
    Object? expectedCompletionDate = freezed,
    Object? isOverdue = null,
  }) {
    return _then(_$ItemProductionImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      currentStageName: freezed == currentStageName
          ? _value.currentStageName
          : currentStageName // ignore: cast_nullable_to_non_nullable
              as String?,
      currentStageStarted: null == currentStageStarted
          ? _value.currentStageStarted
          : currentStageStarted // ignore: cast_nullable_to_non_nullable
              as bool,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedCompletionDate: freezed == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isOverdue: null == isOverdue
          ? _value.isOverdue
          : isOverdue // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemProductionImpl extends _ItemProduction {
  const _$ItemProductionImpl(
      {required this.state,
      @JsonKey(name: 'current_stage_name') this.currentStageName,
      @JsonKey(name: 'current_stage_started') this.currentStageStarted = false,
      @JsonKey(name: 'task_id') this.taskId,
      @JsonKey(name: 'expected_completion_date') this.expectedCompletionDate,
      @JsonKey(name: 'is_overdue') this.isOverdue = false})
      : super._();

  factory _$ItemProductionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemProductionImplFromJson(json);

  @override
  final String state;
  @override
  @JsonKey(name: 'current_stage_name')
  final String? currentStageName;
  @override
  @JsonKey(name: 'current_stage_started')
  final bool currentStageStarted;
  @override
  @JsonKey(name: 'task_id')
  final String? taskId;
  @override
  @JsonKey(name: 'expected_completion_date')
  final DateTime? expectedCompletionDate;
  @override
  @JsonKey(name: 'is_overdue')
  final bool isOverdue;

  @override
  String toString() {
    return 'ItemProduction(state: $state, currentStageName: $currentStageName, currentStageStarted: $currentStageStarted, taskId: $taskId, expectedCompletionDate: $expectedCompletionDate, isOverdue: $isOverdue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemProductionImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.currentStageName, currentStageName) ||
                other.currentStageName == currentStageName) &&
            (identical(other.currentStageStarted, currentStageStarted) ||
                other.currentStageStarted == currentStageStarted) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.expectedCompletionDate, expectedCompletionDate) ||
                other.expectedCompletionDate == expectedCompletionDate) &&
            (identical(other.isOverdue, isOverdue) ||
                other.isOverdue == isOverdue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, currentStageName,
      currentStageStarted, taskId, expectedCompletionDate, isOverdue);

  /// Create a copy of ItemProduction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemProductionImplCopyWith<_$ItemProductionImpl> get copyWith =>
      __$$ItemProductionImplCopyWithImpl<_$ItemProductionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemProductionImplToJson(
      this,
    );
  }
}

abstract class _ItemProduction extends ItemProduction {
  const factory _ItemProduction(
      {required final String state,
      @JsonKey(name: 'current_stage_name') final String? currentStageName,
      @JsonKey(name: 'current_stage_started') final bool currentStageStarted,
      @JsonKey(name: 'task_id') final String? taskId,
      @JsonKey(name: 'expected_completion_date')
      final DateTime? expectedCompletionDate,
      @JsonKey(name: 'is_overdue')
      final bool isOverdue}) = _$ItemProductionImpl;
  const _ItemProduction._() : super._();

  factory _ItemProduction.fromJson(Map<String, dynamic> json) =
      _$ItemProductionImpl.fromJson;

  @override
  String get state;
  @override
  @JsonKey(name: 'current_stage_name')
  String? get currentStageName;
  @override
  @JsonKey(name: 'current_stage_started')
  bool get currentStageStarted;
  @override
  @JsonKey(name: 'task_id')
  String? get taskId;
  @override
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate;
  @override
  @JsonKey(name: 'is_overdue')
  bool get isOverdue;

  /// Create a copy of ItemProduction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemProductionImplCopyWith<_$ItemProductionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
