// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TaskEvent _$TaskEventFromJson(Map<String, dynamic> json) {
  return _TaskEvent.fromJson(json);
}

/// @nodoc
mixin _$TaskEvent {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_id')
  String get taskId => throw _privateConstructorUsedError;
  @JsonKey(name: 'stage_id')
  String? get stageId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_label')
  String? get itemLabel => throw _privateConstructorUsedError;
  String? get detail => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TaskEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskEventCopyWith<TaskEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskEventCopyWith<$Res> {
  factory $TaskEventCopyWith(TaskEvent value, $Res Function(TaskEvent) then) =
      _$TaskEventCopyWithImpl<$Res, TaskEvent>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'task_id') String taskId,
      @JsonKey(name: 'stage_id') String? stageId,
      String action,
      @JsonKey(name: 'item_label') String? itemLabel,
      String? detail,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$TaskEventCopyWithImpl<$Res, $Val extends TaskEvent>
    implements $TaskEventCopyWith<$Res> {
  _$TaskEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? stageId = freezed,
    Object? action = null,
    Object? itemLabel = freezed,
    Object? detail = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      stageId: freezed == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String?,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      itemLabel: freezed == itemLabel
          ? _value.itemLabel
          : itemLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      detail: freezed == detail
          ? _value.detail
          : detail // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskEventImplCopyWith<$Res>
    implements $TaskEventCopyWith<$Res> {
  factory _$$TaskEventImplCopyWith(
          _$TaskEventImpl value, $Res Function(_$TaskEventImpl) then) =
      __$$TaskEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'task_id') String taskId,
      @JsonKey(name: 'stage_id') String? stageId,
      String action,
      @JsonKey(name: 'item_label') String? itemLabel,
      String? detail,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$TaskEventImplCopyWithImpl<$Res>
    extends _$TaskEventCopyWithImpl<$Res, _$TaskEventImpl>
    implements _$$TaskEventImplCopyWith<$Res> {
  __$$TaskEventImplCopyWithImpl(
      _$TaskEventImpl _value, $Res Function(_$TaskEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? stageId = freezed,
    Object? action = null,
    Object? itemLabel = freezed,
    Object? detail = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$TaskEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      stageId: freezed == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String?,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      itemLabel: freezed == itemLabel
          ? _value.itemLabel
          : itemLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      detail: freezed == detail
          ? _value.detail
          : detail // ignore: cast_nullable_to_non_nullable
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
class _$TaskEventImpl implements _TaskEvent {
  const _$TaskEventImpl(
      {required this.id,
      @JsonKey(name: 'task_id') required this.taskId,
      @JsonKey(name: 'stage_id') this.stageId,
      required this.action,
      @JsonKey(name: 'item_label') this.itemLabel,
      this.detail,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$TaskEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskEventImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'task_id')
  final String taskId;
  @override
  @JsonKey(name: 'stage_id')
  final String? stageId;
  @override
  final String action;
  @override
  @JsonKey(name: 'item_label')
  final String? itemLabel;
  @override
  final String? detail;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'TaskEvent(id: $id, taskId: $taskId, stageId: $stageId, action: $action, itemLabel: $itemLabel, detail: $detail, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.itemLabel, itemLabel) ||
                other.itemLabel == itemLabel) &&
            (identical(other.detail, detail) || other.detail == detail) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, taskId, stageId, action, itemLabel, detail, createdAt);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskEventImplCopyWith<_$TaskEventImpl> get copyWith =>
      __$$TaskEventImplCopyWithImpl<_$TaskEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskEventImplToJson(
      this,
    );
  }
}

abstract class _TaskEvent implements TaskEvent {
  const factory _TaskEvent(
          {required final String id,
          @JsonKey(name: 'task_id') required final String taskId,
          @JsonKey(name: 'stage_id') final String? stageId,
          required final String action,
          @JsonKey(name: 'item_label') final String? itemLabel,
          final String? detail,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$TaskEventImpl;

  factory _TaskEvent.fromJson(Map<String, dynamic> json) =
      _$TaskEventImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'task_id')
  String get taskId;
  @override
  @JsonKey(name: 'stage_id')
  String? get stageId;
  @override
  String get action;
  @override
  @JsonKey(name: 'item_label')
  String? get itemLabel;
  @override
  String? get detail;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskEventImplCopyWith<_$TaskEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
