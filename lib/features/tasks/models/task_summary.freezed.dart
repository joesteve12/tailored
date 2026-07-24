// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StageBrief _$StageBriefFromJson(Map<String, dynamic> json) {
  return _StageBrief.fromJson(json);
}

/// @nodoc
mixin _$StageBrief {
  @JsonKey(name: 'process_name')
  String get processName => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt => throw _privateConstructorUsedError;

  /// Serializes this StageBrief to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StageBrief
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageBriefCopyWith<StageBrief> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageBriefCopyWith<$Res> {
  factory $StageBriefCopyWith(
          StageBrief value, $Res Function(StageBrief) then) =
      _$StageBriefCopyWithImpl<$Res, StageBrief>;
  @useResult
  $Res call(
      {@JsonKey(name: 'process_name') String processName,
      String state,
      @JsonKey(name: 'finished_at') DateTime? finishedAt});
}

/// @nodoc
class _$StageBriefCopyWithImpl<$Res, $Val extends StageBrief>
    implements $StageBriefCopyWith<$Res> {
  _$StageBriefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageBrief
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? processName = null,
    Object? state = null,
    Object? finishedAt = freezed,
  }) {
    return _then(_value.copyWith(
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageBriefImplCopyWith<$Res>
    implements $StageBriefCopyWith<$Res> {
  factory _$$StageBriefImplCopyWith(
          _$StageBriefImpl value, $Res Function(_$StageBriefImpl) then) =
      __$$StageBriefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'process_name') String processName,
      String state,
      @JsonKey(name: 'finished_at') DateTime? finishedAt});
}

/// @nodoc
class __$$StageBriefImplCopyWithImpl<$Res>
    extends _$StageBriefCopyWithImpl<$Res, _$StageBriefImpl>
    implements _$$StageBriefImplCopyWith<$Res> {
  __$$StageBriefImplCopyWithImpl(
      _$StageBriefImpl _value, $Res Function(_$StageBriefImpl) _then)
      : super(_value, _then);

  /// Create a copy of StageBrief
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? processName = null,
    Object? state = null,
    Object? finishedAt = freezed,
  }) {
    return _then(_$StageBriefImpl(
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageBriefImpl extends _StageBrief {
  const _$StageBriefImpl(
      {@JsonKey(name: 'process_name') required this.processName,
      required this.state,
      @JsonKey(name: 'finished_at') this.finishedAt})
      : super._();

  factory _$StageBriefImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageBriefImplFromJson(json);

  @override
  @JsonKey(name: 'process_name')
  final String processName;
  @override
  final String state;
  @override
  @JsonKey(name: 'finished_at')
  final DateTime? finishedAt;

  @override
  String toString() {
    return 'StageBrief(processName: $processName, state: $state, finishedAt: $finishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageBriefImpl &&
            (identical(other.processName, processName) ||
                other.processName == processName) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, processName, state, finishedAt);

  /// Create a copy of StageBrief
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageBriefImplCopyWith<_$StageBriefImpl> get copyWith =>
      __$$StageBriefImplCopyWithImpl<_$StageBriefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageBriefImplToJson(
      this,
    );
  }
}

abstract class _StageBrief extends StageBrief {
  const factory _StageBrief(
          {@JsonKey(name: 'process_name') required final String processName,
          required final String state,
          @JsonKey(name: 'finished_at') final DateTime? finishedAt}) =
      _$StageBriefImpl;
  const _StageBrief._() : super._();

  factory _StageBrief.fromJson(Map<String, dynamic> json) =
      _$StageBriefImpl.fromJson;

  @override
  @JsonKey(name: 'process_name')
  String get processName;
  @override
  String get state;
  @override
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt;

  /// Create a copy of StageBrief
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageBriefImplCopyWith<_$StageBriefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaskSummary _$TaskSummaryFromJson(Map<String, dynamic> json) {
  return _TaskSummary.fromJson(json);
}

/// @nodoc
mixin _$TaskSummary {
  @JsonKey(name: 'task_id')
  String get taskId => throw _privateConstructorUsedError;
  String get kind =>
      throw _privateConstructorUsedError; // Production context — to-dos: only when linked to an order.
  @JsonKey(name: 'order_id')
  String? get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String? get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_index')
  int? get itemIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String? get garmentType => throw _privateConstructorUsedError;

  /// Item recipient (production) or linked client (to-do).
  @JsonKey(name: 'recipient_name')
  String? get recipientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate =>
      throw _privateConstructorUsedError; // General (to-do) fields.
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_at')
  DateTime? get dueAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_minutes_before')
  int? get reminderMinutesBefore => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt =>
      throw _privateConstructorUsedError; // Derived flags (both kinds). Buckets come from the server — computed
// against the `today` + tz offset the client sent — so the tabs and
// the badges can never disagree with the filter that fetched them.
  @JsonKey(name: 'is_complete')
  bool get isComplete => throw _privateConstructorUsedError;
  bool get delayed => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_today')
  bool get dueToday => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_tomorrow')
  bool get dueTomorrow => throw _privateConstructorUsedError;
  List<StageBrief> get stages => throw _privateConstructorUsedError;

  /// Serializes this TaskSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskSummaryCopyWith<TaskSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskSummaryCopyWith<$Res> {
  factory $TaskSummaryCopyWith(
          TaskSummary value, $Res Function(TaskSummary) then) =
      _$TaskSummaryCopyWithImpl<$Res, TaskSummary>;
  @useResult
  $Res call(
      {@JsonKey(name: 'task_id') String taskId,
      String kind,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'order_number') String? orderNumber,
      @JsonKey(name: 'item_index') int? itemIndex,
      @JsonKey(name: 'garment_type') String? garmentType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      String? title,
      @JsonKey(name: 'due_at') DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before') int? reminderMinutesBefore,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'is_complete') bool isComplete,
      bool delayed,
      @JsonKey(name: 'due_today') bool dueToday,
      @JsonKey(name: 'due_tomorrow') bool dueTomorrow,
      List<StageBrief> stages});
}

/// @nodoc
class _$TaskSummaryCopyWithImpl<$Res, $Val extends TaskSummary>
    implements $TaskSummaryCopyWith<$Res> {
  _$TaskSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? kind = null,
    Object? orderId = freezed,
    Object? orderNumber = freezed,
    Object? itemIndex = freezed,
    Object? garmentType = freezed,
    Object? recipientName = freezed,
    Object? thumbnailUrl = freezed,
    Object? expectedCompletionDate = freezed,
    Object? title = freezed,
    Object? dueAt = freezed,
    Object? reminderMinutesBefore = freezed,
    Object? completedAt = freezed,
    Object? isComplete = null,
    Object? delayed = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
    Object? stages = null,
  }) {
    return _then(_value.copyWith(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: freezed == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      itemIndex: freezed == itemIndex
          ? _value.itemIndex
          : itemIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      garmentType: freezed == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedCompletionDate: freezed == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderMinutesBefore: freezed == reminderMinutesBefore
          ? _value.reminderMinutesBefore
          : reminderMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      delayed: null == delayed
          ? _value.delayed
          : delayed // ignore: cast_nullable_to_non_nullable
              as bool,
      dueToday: null == dueToday
          ? _value.dueToday
          : dueToday // ignore: cast_nullable_to_non_nullable
              as bool,
      dueTomorrow: null == dueTomorrow
          ? _value.dueTomorrow
          : dueTomorrow // ignore: cast_nullable_to_non_nullable
              as bool,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageBrief>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskSummaryImplCopyWith<$Res>
    implements $TaskSummaryCopyWith<$Res> {
  factory _$$TaskSummaryImplCopyWith(
          _$TaskSummaryImpl value, $Res Function(_$TaskSummaryImpl) then) =
      __$$TaskSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'task_id') String taskId,
      String kind,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'order_number') String? orderNumber,
      @JsonKey(name: 'item_index') int? itemIndex,
      @JsonKey(name: 'garment_type') String? garmentType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      String? title,
      @JsonKey(name: 'due_at') DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before') int? reminderMinutesBefore,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'is_complete') bool isComplete,
      bool delayed,
      @JsonKey(name: 'due_today') bool dueToday,
      @JsonKey(name: 'due_tomorrow') bool dueTomorrow,
      List<StageBrief> stages});
}

/// @nodoc
class __$$TaskSummaryImplCopyWithImpl<$Res>
    extends _$TaskSummaryCopyWithImpl<$Res, _$TaskSummaryImpl>
    implements _$$TaskSummaryImplCopyWith<$Res> {
  __$$TaskSummaryImplCopyWithImpl(
      _$TaskSummaryImpl _value, $Res Function(_$TaskSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskId = null,
    Object? kind = null,
    Object? orderId = freezed,
    Object? orderNumber = freezed,
    Object? itemIndex = freezed,
    Object? garmentType = freezed,
    Object? recipientName = freezed,
    Object? thumbnailUrl = freezed,
    Object? expectedCompletionDate = freezed,
    Object? title = freezed,
    Object? dueAt = freezed,
    Object? reminderMinutesBefore = freezed,
    Object? completedAt = freezed,
    Object? isComplete = null,
    Object? delayed = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
    Object? stages = null,
  }) {
    return _then(_$TaskSummaryImpl(
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNumber: freezed == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      itemIndex: freezed == itemIndex
          ? _value.itemIndex
          : itemIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      garmentType: freezed == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedCompletionDate: freezed == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderMinutesBefore: freezed == reminderMinutesBefore
          ? _value.reminderMinutesBefore
          : reminderMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      delayed: null == delayed
          ? _value.delayed
          : delayed // ignore: cast_nullable_to_non_nullable
              as bool,
      dueToday: null == dueToday
          ? _value.dueToday
          : dueToday // ignore: cast_nullable_to_non_nullable
              as bool,
      dueTomorrow: null == dueTomorrow
          ? _value.dueTomorrow
          : dueTomorrow // ignore: cast_nullable_to_non_nullable
              as bool,
      stages: null == stages
          ? _value._stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageBrief>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskSummaryImpl extends _TaskSummary {
  const _$TaskSummaryImpl(
      {@JsonKey(name: 'task_id') required this.taskId,
      required this.kind,
      @JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'order_number') this.orderNumber,
      @JsonKey(name: 'item_index') this.itemIndex,
      @JsonKey(name: 'garment_type') this.garmentType,
      @JsonKey(name: 'recipient_name') this.recipientName,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      @JsonKey(name: 'expected_completion_date') this.expectedCompletionDate,
      this.title,
      @JsonKey(name: 'due_at') this.dueAt,
      @JsonKey(name: 'reminder_minutes_before') this.reminderMinutesBefore,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'is_complete') required this.isComplete,
      required this.delayed,
      @JsonKey(name: 'due_today') required this.dueToday,
      @JsonKey(name: 'due_tomorrow') required this.dueTomorrow,
      final List<StageBrief> stages = const <StageBrief>[]})
      : _stages = stages,
        super._();

  factory _$TaskSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskSummaryImplFromJson(json);

  @override
  @JsonKey(name: 'task_id')
  final String taskId;
  @override
  final String kind;
// Production context — to-dos: only when linked to an order.
  @override
  @JsonKey(name: 'order_id')
  final String? orderId;
  @override
  @JsonKey(name: 'order_number')
  final String? orderNumber;
  @override
  @JsonKey(name: 'item_index')
  final int? itemIndex;
  @override
  @JsonKey(name: 'garment_type')
  final String? garmentType;

  /// Item recipient (production) or linked client (to-do).
  @override
  @JsonKey(name: 'recipient_name')
  final String? recipientName;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @override
  @JsonKey(name: 'expected_completion_date')
  final DateTime? expectedCompletionDate;
// General (to-do) fields.
  @override
  final String? title;
  @override
  @JsonKey(name: 'due_at')
  final DateTime? dueAt;
  @override
  @JsonKey(name: 'reminder_minutes_before')
  final int? reminderMinutesBefore;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
// Derived flags (both kinds). Buckets come from the server — computed
// against the `today` + tz offset the client sent — so the tabs and
// the badges can never disagree with the filter that fetched them.
  @override
  @JsonKey(name: 'is_complete')
  final bool isComplete;
  @override
  final bool delayed;
  @override
  @JsonKey(name: 'due_today')
  final bool dueToday;
  @override
  @JsonKey(name: 'due_tomorrow')
  final bool dueTomorrow;
  final List<StageBrief> _stages;
  @override
  @JsonKey()
  List<StageBrief> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  @override
  String toString() {
    return 'TaskSummary(taskId: $taskId, kind: $kind, orderId: $orderId, orderNumber: $orderNumber, itemIndex: $itemIndex, garmentType: $garmentType, recipientName: $recipientName, thumbnailUrl: $thumbnailUrl, expectedCompletionDate: $expectedCompletionDate, title: $title, dueAt: $dueAt, reminderMinutesBefore: $reminderMinutesBefore, completedAt: $completedAt, isComplete: $isComplete, delayed: $delayed, dueToday: $dueToday, dueTomorrow: $dueTomorrow, stages: $stages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskSummaryImpl &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.itemIndex, itemIndex) ||
                other.itemIndex == itemIndex) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.expectedCompletionDate, expectedCompletionDate) ||
                other.expectedCompletionDate == expectedCompletionDate) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dueAt, dueAt) || other.dueAt == dueAt) &&
            (identical(other.reminderMinutesBefore, reminderMinutesBefore) ||
                other.reminderMinutesBefore == reminderMinutesBefore) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.delayed, delayed) || other.delayed == delayed) &&
            (identical(other.dueToday, dueToday) ||
                other.dueToday == dueToday) &&
            (identical(other.dueTomorrow, dueTomorrow) ||
                other.dueTomorrow == dueTomorrow) &&
            const DeepCollectionEquality().equals(other._stages, _stages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskId,
      kind,
      orderId,
      orderNumber,
      itemIndex,
      garmentType,
      recipientName,
      thumbnailUrl,
      expectedCompletionDate,
      title,
      dueAt,
      reminderMinutesBefore,
      completedAt,
      isComplete,
      delayed,
      dueToday,
      dueTomorrow,
      const DeepCollectionEquality().hash(_stages));

  /// Create a copy of TaskSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskSummaryImplCopyWith<_$TaskSummaryImpl> get copyWith =>
      __$$TaskSummaryImplCopyWithImpl<_$TaskSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskSummaryImplToJson(
      this,
    );
  }
}

abstract class _TaskSummary extends TaskSummary {
  const factory _TaskSummary(
      {@JsonKey(name: 'task_id') required final String taskId,
      required final String kind,
      @JsonKey(name: 'order_id') final String? orderId,
      @JsonKey(name: 'order_number') final String? orderNumber,
      @JsonKey(name: 'item_index') final int? itemIndex,
      @JsonKey(name: 'garment_type') final String? garmentType,
      @JsonKey(name: 'recipient_name') final String? recipientName,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      final DateTime? expectedCompletionDate,
      final String? title,
      @JsonKey(name: 'due_at') final DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before')
      final int? reminderMinutesBefore,
      @JsonKey(name: 'completed_at') final DateTime? completedAt,
      @JsonKey(name: 'is_complete') required final bool isComplete,
      required final bool delayed,
      @JsonKey(name: 'due_today') required final bool dueToday,
      @JsonKey(name: 'due_tomorrow') required final bool dueTomorrow,
      final List<StageBrief> stages}) = _$TaskSummaryImpl;
  const _TaskSummary._() : super._();

  factory _TaskSummary.fromJson(Map<String, dynamic> json) =
      _$TaskSummaryImpl.fromJson;

  @override
  @JsonKey(name: 'task_id')
  String get taskId;
  @override
  String get kind; // Production context — to-dos: only when linked to an order.
  @override
  @JsonKey(name: 'order_id')
  String? get orderId;
  @override
  @JsonKey(name: 'order_number')
  String? get orderNumber;
  @override
  @JsonKey(name: 'item_index')
  int? get itemIndex;
  @override
  @JsonKey(name: 'garment_type')
  String? get garmentType;

  /// Item recipient (production) or linked client (to-do).
  @override
  @JsonKey(name: 'recipient_name')
  String? get recipientName;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate; // General (to-do) fields.
  @override
  String? get title;
  @override
  @JsonKey(name: 'due_at')
  DateTime? get dueAt;
  @override
  @JsonKey(name: 'reminder_minutes_before')
  int? get reminderMinutesBefore;
  @override
  @JsonKey(name: 'completed_at')
  DateTime?
      get completedAt; // Derived flags (both kinds). Buckets come from the server — computed
// against the `today` + tz offset the client sent — so the tabs and
// the badges can never disagree with the filter that fetched them.
  @override
  @JsonKey(name: 'is_complete')
  bool get isComplete;
  @override
  bool get delayed;
  @override
  @JsonKey(name: 'due_today')
  bool get dueToday;
  @override
  @JsonKey(name: 'due_tomorrow')
  bool get dueTomorrow;
  @override
  List<StageBrief> get stages;

  /// Create a copy of TaskSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskSummaryImplCopyWith<_$TaskSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaskListResponse _$TaskListResponseFromJson(Map<String, dynamic> json) {
  return _TaskListResponse.fromJson(json);
}

/// @nodoc
mixin _$TaskListResponse {
  int get total => throw _privateConstructorUsedError;
  List<TaskSummary> get results => throw _privateConstructorUsedError;

  /// Serializes this TaskListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskListResponseCopyWith<TaskListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskListResponseCopyWith<$Res> {
  factory $TaskListResponseCopyWith(
          TaskListResponse value, $Res Function(TaskListResponse) then) =
      _$TaskListResponseCopyWithImpl<$Res, TaskListResponse>;
  @useResult
  $Res call({int total, List<TaskSummary> results});
}

/// @nodoc
class _$TaskListResponseCopyWithImpl<$Res, $Val extends TaskListResponse>
    implements $TaskListResponseCopyWith<$Res> {
  _$TaskListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? results = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<TaskSummary>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskListResponseImplCopyWith<$Res>
    implements $TaskListResponseCopyWith<$Res> {
  factory _$$TaskListResponseImplCopyWith(_$TaskListResponseImpl value,
          $Res Function(_$TaskListResponseImpl) then) =
      __$$TaskListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, List<TaskSummary> results});
}

/// @nodoc
class __$$TaskListResponseImplCopyWithImpl<$Res>
    extends _$TaskListResponseCopyWithImpl<$Res, _$TaskListResponseImpl>
    implements _$$TaskListResponseImplCopyWith<$Res> {
  __$$TaskListResponseImplCopyWithImpl(_$TaskListResponseImpl _value,
      $Res Function(_$TaskListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? results = null,
  }) {
    return _then(_$TaskListResponseImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<TaskSummary>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskListResponseImpl implements _TaskListResponse {
  const _$TaskListResponseImpl(
      {required this.total,
      final List<TaskSummary> results = const <TaskSummary>[]})
      : _results = results;

  factory _$TaskListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskListResponseImplFromJson(json);

  @override
  final int total;
  final List<TaskSummary> _results;
  @override
  @JsonKey()
  List<TaskSummary> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'TaskListResponse(total: $total, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskListResponseImpl &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(other._results, _results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, total, const DeepCollectionEquality().hash(_results));

  /// Create a copy of TaskListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskListResponseImplCopyWith<_$TaskListResponseImpl> get copyWith =>
      __$$TaskListResponseImplCopyWithImpl<_$TaskListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskListResponseImplToJson(
      this,
    );
  }
}

abstract class _TaskListResponse implements TaskListResponse {
  const factory _TaskListResponse(
      {required final int total,
      final List<TaskSummary> results}) = _$TaskListResponseImpl;

  factory _TaskListResponse.fromJson(Map<String, dynamic> json) =
      _$TaskListResponseImpl.fromJson;

  @override
  int get total;
  @override
  List<TaskSummary> get results;

  /// Create a copy of TaskListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskListResponseImplCopyWith<_$TaskListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
