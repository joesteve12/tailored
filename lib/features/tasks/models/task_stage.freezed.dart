// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TaskStage _$TaskStageFromJson(Map<String, dynamic> json) {
  return _TaskStage.fromJson(json);
}

/// @nodoc
mixin _$TaskStage {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'process_id')
  String get processId => throw _privateConstructorUsedError;
  @JsonKey(name: 'process_name')
  String get processName => throw _privateConstructorUsedError;
  int get sequence => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_employee_id')
  String? get assignedEmployeeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_employee_name')
  String? get assignedEmployeeName => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  DateTime? get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;

  /// Serializes this TaskStage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskStage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskStageCopyWith<TaskStage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskStageCopyWith<$Res> {
  factory $TaskStageCopyWith(TaskStage value, $Res Function(TaskStage) then) =
      _$TaskStageCopyWithImpl<$Res, TaskStage>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'process_id') String processId,
      @JsonKey(name: 'process_name') String processName,
      int sequence,
      @JsonKey(name: 'assigned_employee_id') String? assignedEmployeeId,
      @JsonKey(name: 'assigned_employee_name') String? assignedEmployeeName,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'finished_at') DateTime? finishedAt,
      String state});
}

/// @nodoc
class _$TaskStageCopyWithImpl<$Res, $Val extends TaskStage>
    implements $TaskStageCopyWith<$Res> {
  _$TaskStageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskStage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? processId = null,
    Object? processName = null,
    Object? sequence = null,
    Object? assignedEmployeeId = freezed,
    Object? assignedEmployeeName = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? state = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      processId: null == processId
          ? _value.processId
          : processId // ignore: cast_nullable_to_non_nullable
              as String,
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      sequence: null == sequence
          ? _value.sequence
          : sequence // ignore: cast_nullable_to_non_nullable
              as int,
      assignedEmployeeId: freezed == assignedEmployeeId
          ? _value.assignedEmployeeId
          : assignedEmployeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedEmployeeName: freezed == assignedEmployeeName
          ? _value.assignedEmployeeName
          : assignedEmployeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskStageImplCopyWith<$Res>
    implements $TaskStageCopyWith<$Res> {
  factory _$$TaskStageImplCopyWith(
          _$TaskStageImpl value, $Res Function(_$TaskStageImpl) then) =
      __$$TaskStageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'process_id') String processId,
      @JsonKey(name: 'process_name') String processName,
      int sequence,
      @JsonKey(name: 'assigned_employee_id') String? assignedEmployeeId,
      @JsonKey(name: 'assigned_employee_name') String? assignedEmployeeName,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'finished_at') DateTime? finishedAt,
      String state});
}

/// @nodoc
class __$$TaskStageImplCopyWithImpl<$Res>
    extends _$TaskStageCopyWithImpl<$Res, _$TaskStageImpl>
    implements _$$TaskStageImplCopyWith<$Res> {
  __$$TaskStageImplCopyWithImpl(
      _$TaskStageImpl _value, $Res Function(_$TaskStageImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskStage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? processId = null,
    Object? processName = null,
    Object? sequence = null,
    Object? assignedEmployeeId = freezed,
    Object? assignedEmployeeName = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? state = null,
  }) {
    return _then(_$TaskStageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      processId: null == processId
          ? _value.processId
          : processId // ignore: cast_nullable_to_non_nullable
              as String,
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      sequence: null == sequence
          ? _value.sequence
          : sequence // ignore: cast_nullable_to_non_nullable
              as int,
      assignedEmployeeId: freezed == assignedEmployeeId
          ? _value.assignedEmployeeId
          : assignedEmployeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedEmployeeName: freezed == assignedEmployeeName
          ? _value.assignedEmployeeName
          : assignedEmployeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskStageImpl extends _TaskStage {
  const _$TaskStageImpl(
      {required this.id,
      @JsonKey(name: 'process_id') required this.processId,
      @JsonKey(name: 'process_name') required this.processName,
      required this.sequence,
      @JsonKey(name: 'assigned_employee_id') this.assignedEmployeeId,
      @JsonKey(name: 'assigned_employee_name') this.assignedEmployeeName,
      @JsonKey(name: 'started_at') this.startedAt,
      @JsonKey(name: 'finished_at') this.finishedAt,
      required this.state})
      : super._();

  factory _$TaskStageImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskStageImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'process_id')
  final String processId;
  @override
  @JsonKey(name: 'process_name')
  final String processName;
  @override
  final int sequence;
  @override
  @JsonKey(name: 'assigned_employee_id')
  final String? assignedEmployeeId;
  @override
  @JsonKey(name: 'assigned_employee_name')
  final String? assignedEmployeeName;
  @override
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @override
  @JsonKey(name: 'finished_at')
  final DateTime? finishedAt;
  @override
  final String state;

  @override
  String toString() {
    return 'TaskStage(id: $id, processId: $processId, processName: $processName, sequence: $sequence, assignedEmployeeId: $assignedEmployeeId, assignedEmployeeName: $assignedEmployeeName, startedAt: $startedAt, finishedAt: $finishedAt, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskStageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.processId, processId) ||
                other.processId == processId) &&
            (identical(other.processName, processName) ||
                other.processName == processName) &&
            (identical(other.sequence, sequence) ||
                other.sequence == sequence) &&
            (identical(other.assignedEmployeeId, assignedEmployeeId) ||
                other.assignedEmployeeId == assignedEmployeeId) &&
            (identical(other.assignedEmployeeName, assignedEmployeeName) ||
                other.assignedEmployeeName == assignedEmployeeName) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      processId,
      processName,
      sequence,
      assignedEmployeeId,
      assignedEmployeeName,
      startedAt,
      finishedAt,
      state);

  /// Create a copy of TaskStage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskStageImplCopyWith<_$TaskStageImpl> get copyWith =>
      __$$TaskStageImplCopyWithImpl<_$TaskStageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskStageImplToJson(
      this,
    );
  }
}

abstract class _TaskStage extends TaskStage {
  const factory _TaskStage(
      {required final String id,
      @JsonKey(name: 'process_id') required final String processId,
      @JsonKey(name: 'process_name') required final String processName,
      required final int sequence,
      @JsonKey(name: 'assigned_employee_id') final String? assignedEmployeeId,
      @JsonKey(name: 'assigned_employee_name')
      final String? assignedEmployeeName,
      @JsonKey(name: 'started_at') final DateTime? startedAt,
      @JsonKey(name: 'finished_at') final DateTime? finishedAt,
      required final String state}) = _$TaskStageImpl;
  const _TaskStage._() : super._();

  factory _TaskStage.fromJson(Map<String, dynamic> json) =
      _$TaskStageImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'process_id')
  String get processId;
  @override
  @JsonKey(name: 'process_name')
  String get processName;
  @override
  int get sequence;
  @override
  @JsonKey(name: 'assigned_employee_id')
  String? get assignedEmployeeId;
  @override
  @JsonKey(name: 'assigned_employee_name')
  String? get assignedEmployeeName;
  @override
  @JsonKey(name: 'started_at')
  DateTime? get startedAt;
  @override
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt;
  @override
  String get state;

  /// Create a copy of TaskStage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskStageImplCopyWith<_$TaskStageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
