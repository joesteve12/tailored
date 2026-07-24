// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReminderItem _$ReminderItemFromJson(Map<String, dynamic> json) {
  return _ReminderItem.fromJson(json);
}

/// @nodoc
mixin _$ReminderItem {
  @JsonKey(name: 'task_id')
  String get taskId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_at')
  DateTime get dueAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'remind_at')
  DateTime get remindAt => throw _privateConstructorUsedError;

  /// Serializes this ReminderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReminderItemCopyWith<ReminderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderItemCopyWith<$Res> {
  factory $ReminderItemCopyWith(
          ReminderItem value, $Res Function(ReminderItem) then) =
      _$ReminderItemCopyWithImpl<$Res, ReminderItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'task_id') String taskId,
      String title,
      @JsonKey(name: 'due_at') DateTime dueAt,
      @JsonKey(name: 'remind_at') DateTime remindAt});
}

/// @nodoc
class _$ReminderItemCopyWithImpl<$Res, $Val extends ReminderItem>
    implements $ReminderItemCopyWith<$Res> {
  _$ReminderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? title = null,
    Object? dueAt = null,
    Object? remindAt = null,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dueAt: null == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      remindAt: null == remindAt
          ? _value.remindAt
          : remindAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReminderItemImplCopyWith<$Res>
    implements $ReminderItemCopyWith<$Res> {
  factory _$$ReminderItemImplCopyWith(
          _$ReminderItemImpl value, $Res Function(_$ReminderItemImpl) then) =
      __$$ReminderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'task_id') String taskId,
      String title,
      @JsonKey(name: 'due_at') DateTime dueAt,
      @JsonKey(name: 'remind_at') DateTime remindAt});
}

/// @nodoc
class __$$ReminderItemImplCopyWithImpl<$Res>
    extends _$ReminderItemCopyWithImpl<$Res, _$ReminderItemImpl>
    implements _$$ReminderItemImplCopyWith<$Res> {
  __$$ReminderItemImplCopyWithImpl(
      _$ReminderItemImpl _value, $Res Function(_$ReminderItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? title = null,
    Object? dueAt = null,
    Object? remindAt = null,
  }) {
    return _then(_$ReminderItemImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dueAt: null == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      remindAt: null == remindAt
          ? _value.remindAt
          : remindAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReminderItemImpl implements _ReminderItem {
  const _$ReminderItemImpl(
      {@JsonKey(name: 'task_id') required this.taskId,
      required this.title,
      @JsonKey(name: 'due_at') required this.dueAt,
      @JsonKey(name: 'remind_at') required this.remindAt});

  factory _$ReminderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReminderItemImplFromJson(json);

  @override
  @JsonKey(name: 'task_id')
  final String taskId;
  @override
  final String title;
  @override
  @JsonKey(name: 'due_at')
  final DateTime dueAt;
  @override
  @JsonKey(name: 'remind_at')
  final DateTime remindAt;

  @override
  String toString() {
    return 'ReminderItem(taskId: $taskId, title: $title, dueAt: $dueAt, remindAt: $remindAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReminderItemImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dueAt, dueAt) || other.dueAt == dueAt) &&
            (identical(other.remindAt, remindAt) ||
                other.remindAt == remindAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, taskId, title, dueAt, remindAt);

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReminderItemImplCopyWith<_$ReminderItemImpl> get copyWith =>
      __$$ReminderItemImplCopyWithImpl<_$ReminderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReminderItemImplToJson(
      this,
    );
  }
}

abstract class _ReminderItem implements ReminderItem {
  const factory _ReminderItem(
          {@JsonKey(name: 'task_id') required final String taskId,
          required final String title,
          @JsonKey(name: 'due_at') required final DateTime dueAt,
          @JsonKey(name: 'remind_at') required final DateTime remindAt}) =
      _$ReminderItemImpl;

  factory _ReminderItem.fromJson(Map<String, dynamic> json) =
      _$ReminderItemImpl.fromJson;

  @override
  @JsonKey(name: 'task_id')
  String get taskId;
  @override
  String get title;
  @override
  @JsonKey(name: 'due_at')
  DateTime get dueAt;
  @override
  @JsonKey(name: 'remind_at')
  DateTime get remindAt;

  /// Create a copy of ReminderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReminderItemImplCopyWith<_$ReminderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
