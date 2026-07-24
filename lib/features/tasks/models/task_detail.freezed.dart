// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HandoverInfo _$HandoverInfoFromJson(Map<String, dynamic> json) {
  return _HandoverInfo.fromJson(json);
}

/// @nodoc
mixin _$HandoverInfo {
  @JsonKey(name: 'next_stage_id')
  String get nextStageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_stage_name')
  String get nextStageName => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_employee_id')
  String? get nextEmployeeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_employee_name')
  String? get nextEmployeeName => throw _privateConstructorUsedError;

  /// Serializes this HandoverInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HandoverInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandoverInfoCopyWith<HandoverInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandoverInfoCopyWith<$Res> {
  factory $HandoverInfoCopyWith(
          HandoverInfo value, $Res Function(HandoverInfo) then) =
      _$HandoverInfoCopyWithImpl<$Res, HandoverInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'next_stage_id') String nextStageId,
      @JsonKey(name: 'next_stage_name') String nextStageName,
      @JsonKey(name: 'next_employee_id') String? nextEmployeeId,
      @JsonKey(name: 'next_employee_name') String? nextEmployeeName});
}

/// @nodoc
class _$HandoverInfoCopyWithImpl<$Res, $Val extends HandoverInfo>
    implements $HandoverInfoCopyWith<$Res> {
  _$HandoverInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HandoverInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nextStageId = null,
    Object? nextStageName = null,
    Object? nextEmployeeId = freezed,
    Object? nextEmployeeName = freezed,
  }) {
    return _then(_value.copyWith(
      nextStageId: null == nextStageId
          ? _value.nextStageId
          : nextStageId // ignore: cast_nullable_to_non_nullable
              as String,
      nextStageName: null == nextStageName
          ? _value.nextStageName
          : nextStageName // ignore: cast_nullable_to_non_nullable
              as String,
      nextEmployeeId: freezed == nextEmployeeId
          ? _value.nextEmployeeId
          : nextEmployeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextEmployeeName: freezed == nextEmployeeName
          ? _value.nextEmployeeName
          : nextEmployeeName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HandoverInfoImplCopyWith<$Res>
    implements $HandoverInfoCopyWith<$Res> {
  factory _$$HandoverInfoImplCopyWith(
          _$HandoverInfoImpl value, $Res Function(_$HandoverInfoImpl) then) =
      __$$HandoverInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'next_stage_id') String nextStageId,
      @JsonKey(name: 'next_stage_name') String nextStageName,
      @JsonKey(name: 'next_employee_id') String? nextEmployeeId,
      @JsonKey(name: 'next_employee_name') String? nextEmployeeName});
}

/// @nodoc
class __$$HandoverInfoImplCopyWithImpl<$Res>
    extends _$HandoverInfoCopyWithImpl<$Res, _$HandoverInfoImpl>
    implements _$$HandoverInfoImplCopyWith<$Res> {
  __$$HandoverInfoImplCopyWithImpl(
      _$HandoverInfoImpl _value, $Res Function(_$HandoverInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of HandoverInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nextStageId = null,
    Object? nextStageName = null,
    Object? nextEmployeeId = freezed,
    Object? nextEmployeeName = freezed,
  }) {
    return _then(_$HandoverInfoImpl(
      nextStageId: null == nextStageId
          ? _value.nextStageId
          : nextStageId // ignore: cast_nullable_to_non_nullable
              as String,
      nextStageName: null == nextStageName
          ? _value.nextStageName
          : nextStageName // ignore: cast_nullable_to_non_nullable
              as String,
      nextEmployeeId: freezed == nextEmployeeId
          ? _value.nextEmployeeId
          : nextEmployeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      nextEmployeeName: freezed == nextEmployeeName
          ? _value.nextEmployeeName
          : nextEmployeeName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HandoverInfoImpl implements _HandoverInfo {
  const _$HandoverInfoImpl(
      {@JsonKey(name: 'next_stage_id') required this.nextStageId,
      @JsonKey(name: 'next_stage_name') required this.nextStageName,
      @JsonKey(name: 'next_employee_id') this.nextEmployeeId,
      @JsonKey(name: 'next_employee_name') this.nextEmployeeName});

  factory _$HandoverInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandoverInfoImplFromJson(json);

  @override
  @JsonKey(name: 'next_stage_id')
  final String nextStageId;
  @override
  @JsonKey(name: 'next_stage_name')
  final String nextStageName;
  @override
  @JsonKey(name: 'next_employee_id')
  final String? nextEmployeeId;
  @override
  @JsonKey(name: 'next_employee_name')
  final String? nextEmployeeName;

  @override
  String toString() {
    return 'HandoverInfo(nextStageId: $nextStageId, nextStageName: $nextStageName, nextEmployeeId: $nextEmployeeId, nextEmployeeName: $nextEmployeeName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandoverInfoImpl &&
            (identical(other.nextStageId, nextStageId) ||
                other.nextStageId == nextStageId) &&
            (identical(other.nextStageName, nextStageName) ||
                other.nextStageName == nextStageName) &&
            (identical(other.nextEmployeeId, nextEmployeeId) ||
                other.nextEmployeeId == nextEmployeeId) &&
            (identical(other.nextEmployeeName, nextEmployeeName) ||
                other.nextEmployeeName == nextEmployeeName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, nextStageId, nextStageName,
      nextEmployeeId, nextEmployeeName);

  /// Create a copy of HandoverInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandoverInfoImplCopyWith<_$HandoverInfoImpl> get copyWith =>
      __$$HandoverInfoImplCopyWithImpl<_$HandoverInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HandoverInfoImplToJson(
      this,
    );
  }
}

abstract class _HandoverInfo implements HandoverInfo {
  const factory _HandoverInfo(
      {@JsonKey(name: 'next_stage_id') required final String nextStageId,
      @JsonKey(name: 'next_stage_name') required final String nextStageName,
      @JsonKey(name: 'next_employee_id') final String? nextEmployeeId,
      @JsonKey(name: 'next_employee_name')
      final String? nextEmployeeName}) = _$HandoverInfoImpl;

  factory _HandoverInfo.fromJson(Map<String, dynamic> json) =
      _$HandoverInfoImpl.fromJson;

  @override
  @JsonKey(name: 'next_stage_id')
  String get nextStageId;
  @override
  @JsonKey(name: 'next_stage_name')
  String get nextStageName;
  @override
  @JsonKey(name: 'next_employee_id')
  String? get nextEmployeeId;
  @override
  @JsonKey(name: 'next_employee_name')
  String? get nextEmployeeName;

  /// Create a copy of HandoverInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandoverInfoImplCopyWith<_$HandoverInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaskDetail _$TaskDetailFromJson(Map<String, dynamic> json) {
  return _TaskDetail.fromJson(json);
}

/// @nodoc
mixin _$TaskDetail {
  String get id => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String? get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String? get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_due_date')
  DateTime? get orderDueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_item_id')
  String? get orderItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_index')
  int? get itemIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String? get garmentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipient_name')
  String? get recipientName => throw _privateConstructorUsedError;
  int? get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
  double? get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate =>
      throw _privateConstructorUsedError; // General (to-do) fields.
  String? get title => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_at')
  DateTime? get dueAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_minutes_before')
  int? get reminderMinutesBefore => throw _privateConstructorUsedError;
  @JsonKey(name: 'remind_at')
  DateTime? get remindAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String? get clientId =>
      throw _privateConstructorUsedError; // Derived flags (both kinds).
  @JsonKey(name: 'is_complete')
  bool get isComplete => throw _privateConstructorUsedError;
  bool get delayed => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_today')
  bool get dueToday => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_tomorrow')
  bool get dueTomorrow => throw _privateConstructorUsedError;
  List<TaskStage> get stages => throw _privateConstructorUsedError;
  List<TaskEvent> get events => throw _privateConstructorUsedError;
  HandoverInfo? get handover => throw _privateConstructorUsedError;

  /// Serializes this TaskDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskDetailCopyWith<TaskDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskDetailCopyWith<$Res> {
  factory $TaskDetailCopyWith(
          TaskDetail value, $Res Function(TaskDetail) then) =
      _$TaskDetailCopyWithImpl<$Res, TaskDetail>;
  @useResult
  $Res call(
      {String id,
      String kind,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'order_number') String? orderNumber,
      @JsonKey(name: 'order_due_date') DateTime? orderDueDate,
      @JsonKey(name: 'order_item_id') String? orderItemId,
      @JsonKey(name: 'item_index') int? itemIndex,
      @JsonKey(name: 'garment_type') String? garmentType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      int? quantity,
      @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
      double? unitPrice,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      String? title,
      String? notes,
      @JsonKey(name: 'due_at') DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before') int? reminderMinutesBefore,
      @JsonKey(name: 'remind_at') DateTime? remindAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'is_complete') bool isComplete,
      bool delayed,
      @JsonKey(name: 'due_today') bool dueToday,
      @JsonKey(name: 'due_tomorrow') bool dueTomorrow,
      List<TaskStage> stages,
      List<TaskEvent> events,
      HandoverInfo? handover});

  $HandoverInfoCopyWith<$Res>? get handover;
}

/// @nodoc
class _$TaskDetailCopyWithImpl<$Res, $Val extends TaskDetail>
    implements $TaskDetailCopyWith<$Res> {
  _$TaskDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? orderId = freezed,
    Object? orderNumber = freezed,
    Object? orderDueDate = freezed,
    Object? orderItemId = freezed,
    Object? itemIndex = freezed,
    Object? garmentType = freezed,
    Object? recipientName = freezed,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? thumbnailUrl = freezed,
    Object? expectedCompletionDate = freezed,
    Object? title = freezed,
    Object? notes = freezed,
    Object? dueAt = freezed,
    Object? reminderMinutesBefore = freezed,
    Object? remindAt = freezed,
    Object? completedAt = freezed,
    Object? clientId = freezed,
    Object? isComplete = null,
    Object? delayed = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
    Object? stages = null,
    Object? events = null,
    Object? handover = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderDueDate: freezed == orderDueDate
          ? _value.orderDueDate
          : orderDueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderItemId: freezed == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
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
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      unitPrice: freezed == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double?,
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
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderMinutesBefore: freezed == reminderMinutesBefore
          ? _value.reminderMinutesBefore
          : reminderMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int?,
      remindAt: freezed == remindAt
          ? _value.remindAt
          : remindAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
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
              as List<TaskStage>,
      events: null == events
          ? _value.events
          : events // ignore: cast_nullable_to_non_nullable
              as List<TaskEvent>,
      handover: freezed == handover
          ? _value.handover
          : handover // ignore: cast_nullable_to_non_nullable
              as HandoverInfo?,
    ) as $Val);
  }

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HandoverInfoCopyWith<$Res>? get handover {
    if (_value.handover == null) {
      return null;
    }

    return $HandoverInfoCopyWith<$Res>(_value.handover!, (value) {
      return _then(_value.copyWith(handover: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TaskDetailImplCopyWith<$Res>
    implements $TaskDetailCopyWith<$Res> {
  factory _$$TaskDetailImplCopyWith(
          _$TaskDetailImpl value, $Res Function(_$TaskDetailImpl) then) =
      __$$TaskDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String kind,
      @JsonKey(name: 'order_id') String? orderId,
      @JsonKey(name: 'order_number') String? orderNumber,
      @JsonKey(name: 'order_due_date') DateTime? orderDueDate,
      @JsonKey(name: 'order_item_id') String? orderItemId,
      @JsonKey(name: 'item_index') int? itemIndex,
      @JsonKey(name: 'garment_type') String? garmentType,
      @JsonKey(name: 'recipient_name') String? recipientName,
      int? quantity,
      @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
      double? unitPrice,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      DateTime? expectedCompletionDate,
      String? title,
      String? notes,
      @JsonKey(name: 'due_at') DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before') int? reminderMinutesBefore,
      @JsonKey(name: 'remind_at') DateTime? remindAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'is_complete') bool isComplete,
      bool delayed,
      @JsonKey(name: 'due_today') bool dueToday,
      @JsonKey(name: 'due_tomorrow') bool dueTomorrow,
      List<TaskStage> stages,
      List<TaskEvent> events,
      HandoverInfo? handover});

  @override
  $HandoverInfoCopyWith<$Res>? get handover;
}

/// @nodoc
class __$$TaskDetailImplCopyWithImpl<$Res>
    extends _$TaskDetailCopyWithImpl<$Res, _$TaskDetailImpl>
    implements _$$TaskDetailImplCopyWith<$Res> {
  __$$TaskDetailImplCopyWithImpl(
      _$TaskDetailImpl _value, $Res Function(_$TaskDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? orderId = freezed,
    Object? orderNumber = freezed,
    Object? orderDueDate = freezed,
    Object? orderItemId = freezed,
    Object? itemIndex = freezed,
    Object? garmentType = freezed,
    Object? recipientName = freezed,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? thumbnailUrl = freezed,
    Object? expectedCompletionDate = freezed,
    Object? title = freezed,
    Object? notes = freezed,
    Object? dueAt = freezed,
    Object? reminderMinutesBefore = freezed,
    Object? remindAt = freezed,
    Object? completedAt = freezed,
    Object? clientId = freezed,
    Object? isComplete = null,
    Object? delayed = null,
    Object? dueToday = null,
    Object? dueTomorrow = null,
    Object? stages = null,
    Object? events = null,
    Object? handover = freezed,
  }) {
    return _then(_$TaskDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      orderDueDate: freezed == orderDueDate
          ? _value.orderDueDate
          : orderDueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      orderItemId: freezed == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
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
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int?,
      unitPrice: freezed == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double?,
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
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      dueAt: freezed == dueAt
          ? _value.dueAt
          : dueAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderMinutesBefore: freezed == reminderMinutesBefore
          ? _value.reminderMinutesBefore
          : reminderMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int?,
      remindAt: freezed == remindAt
          ? _value.remindAt
          : remindAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
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
              as List<TaskStage>,
      events: null == events
          ? _value._events
          : events // ignore: cast_nullable_to_non_nullable
              as List<TaskEvent>,
      handover: freezed == handover
          ? _value.handover
          : handover // ignore: cast_nullable_to_non_nullable
              as HandoverInfo?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskDetailImpl extends _TaskDetail {
  const _$TaskDetailImpl(
      {required this.id,
      required this.kind,
      @JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'order_number') this.orderNumber,
      @JsonKey(name: 'order_due_date') this.orderDueDate,
      @JsonKey(name: 'order_item_id') this.orderItemId,
      @JsonKey(name: 'item_index') this.itemIndex,
      @JsonKey(name: 'garment_type') this.garmentType,
      @JsonKey(name: 'recipient_name') this.recipientName,
      this.quantity,
      @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
      this.unitPrice,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      @JsonKey(name: 'expected_completion_date') this.expectedCompletionDate,
      this.title,
      this.notes,
      @JsonKey(name: 'due_at') this.dueAt,
      @JsonKey(name: 'reminder_minutes_before') this.reminderMinutesBefore,
      @JsonKey(name: 'remind_at') this.remindAt,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'client_id') this.clientId,
      @JsonKey(name: 'is_complete') required this.isComplete,
      required this.delayed,
      @JsonKey(name: 'due_today') required this.dueToday,
      @JsonKey(name: 'due_tomorrow') required this.dueTomorrow,
      final List<TaskStage> stages = const <TaskStage>[],
      final List<TaskEvent> events = const <TaskEvent>[],
      this.handover})
      : _stages = stages,
        _events = events,
        super._();

  factory _$TaskDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String kind;
  @override
  @JsonKey(name: 'order_id')
  final String? orderId;
  @override
  @JsonKey(name: 'order_number')
  final String? orderNumber;
  @override
  @JsonKey(name: 'order_due_date')
  final DateTime? orderDueDate;
  @override
  @JsonKey(name: 'order_item_id')
  final String? orderItemId;
  @override
  @JsonKey(name: 'item_index')
  final int? itemIndex;
  @override
  @JsonKey(name: 'garment_type')
  final String? garmentType;
  @override
  @JsonKey(name: 'recipient_name')
  final String? recipientName;
  @override
  final int? quantity;
  @override
  @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
  final double? unitPrice;
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
  final String? notes;
  @override
  @JsonKey(name: 'due_at')
  final DateTime? dueAt;
  @override
  @JsonKey(name: 'reminder_minutes_before')
  final int? reminderMinutesBefore;
  @override
  @JsonKey(name: 'remind_at')
  final DateTime? remindAt;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'client_id')
  final String? clientId;
// Derived flags (both kinds).
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
  final List<TaskStage> _stages;
  @override
  @JsonKey()
  List<TaskStage> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  final List<TaskEvent> _events;
  @override
  @JsonKey()
  List<TaskEvent> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  final HandoverInfo? handover;

  @override
  String toString() {
    return 'TaskDetail(id: $id, kind: $kind, orderId: $orderId, orderNumber: $orderNumber, orderDueDate: $orderDueDate, orderItemId: $orderItemId, itemIndex: $itemIndex, garmentType: $garmentType, recipientName: $recipientName, quantity: $quantity, unitPrice: $unitPrice, thumbnailUrl: $thumbnailUrl, expectedCompletionDate: $expectedCompletionDate, title: $title, notes: $notes, dueAt: $dueAt, reminderMinutesBefore: $reminderMinutesBefore, remindAt: $remindAt, completedAt: $completedAt, clientId: $clientId, isComplete: $isComplete, delayed: $delayed, dueToday: $dueToday, dueTomorrow: $dueTomorrow, stages: $stages, events: $events, handover: $handover)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.orderDueDate, orderDueDate) ||
                other.orderDueDate == orderDueDate) &&
            (identical(other.orderItemId, orderItemId) ||
                other.orderItemId == orderItemId) &&
            (identical(other.itemIndex, itemIndex) ||
                other.itemIndex == itemIndex) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.expectedCompletionDate, expectedCompletionDate) ||
                other.expectedCompletionDate == expectedCompletionDate) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.dueAt, dueAt) || other.dueAt == dueAt) &&
            (identical(other.reminderMinutesBefore, reminderMinutesBefore) ||
                other.reminderMinutesBefore == reminderMinutesBefore) &&
            (identical(other.remindAt, remindAt) ||
                other.remindAt == remindAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.delayed, delayed) || other.delayed == delayed) &&
            (identical(other.dueToday, dueToday) ||
                other.dueToday == dueToday) &&
            (identical(other.dueTomorrow, dueTomorrow) ||
                other.dueTomorrow == dueTomorrow) &&
            const DeepCollectionEquality().equals(other._stages, _stages) &&
            const DeepCollectionEquality().equals(other._events, _events) &&
            (identical(other.handover, handover) ||
                other.handover == handover));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        kind,
        orderId,
        orderNumber,
        orderDueDate,
        orderItemId,
        itemIndex,
        garmentType,
        recipientName,
        quantity,
        unitPrice,
        thumbnailUrl,
        expectedCompletionDate,
        title,
        notes,
        dueAt,
        reminderMinutesBefore,
        remindAt,
        completedAt,
        clientId,
        isComplete,
        delayed,
        dueToday,
        dueTomorrow,
        const DeepCollectionEquality().hash(_stages),
        const DeepCollectionEquality().hash(_events),
        handover
      ]);

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskDetailImplCopyWith<_$TaskDetailImpl> get copyWith =>
      __$$TaskDetailImplCopyWithImpl<_$TaskDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskDetailImplToJson(
      this,
    );
  }
}

abstract class _TaskDetail extends TaskDetail {
  const factory _TaskDetail(
      {required final String id,
      required final String kind,
      @JsonKey(name: 'order_id') final String? orderId,
      @JsonKey(name: 'order_number') final String? orderNumber,
      @JsonKey(name: 'order_due_date') final DateTime? orderDueDate,
      @JsonKey(name: 'order_item_id') final String? orderItemId,
      @JsonKey(name: 'item_index') final int? itemIndex,
      @JsonKey(name: 'garment_type') final String? garmentType,
      @JsonKey(name: 'recipient_name') final String? recipientName,
      final int? quantity,
      @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
      final double? unitPrice,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      @JsonKey(name: 'expected_completion_date')
      final DateTime? expectedCompletionDate,
      final String? title,
      final String? notes,
      @JsonKey(name: 'due_at') final DateTime? dueAt,
      @JsonKey(name: 'reminder_minutes_before')
      final int? reminderMinutesBefore,
      @JsonKey(name: 'remind_at') final DateTime? remindAt,
      @JsonKey(name: 'completed_at') final DateTime? completedAt,
      @JsonKey(name: 'client_id') final String? clientId,
      @JsonKey(name: 'is_complete') required final bool isComplete,
      required final bool delayed,
      @JsonKey(name: 'due_today') required final bool dueToday,
      @JsonKey(name: 'due_tomorrow') required final bool dueTomorrow,
      final List<TaskStage> stages,
      final List<TaskEvent> events,
      final HandoverInfo? handover}) = _$TaskDetailImpl;
  const _TaskDetail._() : super._();

  factory _TaskDetail.fromJson(Map<String, dynamic> json) =
      _$TaskDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get kind;
  @override
  @JsonKey(name: 'order_id')
  String? get orderId;
  @override
  @JsonKey(name: 'order_number')
  String? get orderNumber;
  @override
  @JsonKey(name: 'order_due_date')
  DateTime? get orderDueDate;
  @override
  @JsonKey(name: 'order_item_id')
  String? get orderItemId;
  @override
  @JsonKey(name: 'item_index')
  int? get itemIndex;
  @override
  @JsonKey(name: 'garment_type')
  String? get garmentType;
  @override
  @JsonKey(name: 'recipient_name')
  String? get recipientName;
  @override
  int? get quantity;
  @override
  @JsonKey(name: 'unit_price', fromJson: nullableDecimalToDouble)
  double? get unitPrice;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  @JsonKey(name: 'expected_completion_date')
  DateTime? get expectedCompletionDate; // General (to-do) fields.
  @override
  String? get title;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'due_at')
  DateTime? get dueAt;
  @override
  @JsonKey(name: 'reminder_minutes_before')
  int? get reminderMinutesBefore;
  @override
  @JsonKey(name: 'remind_at')
  DateTime? get remindAt;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'client_id')
  String? get clientId; // Derived flags (both kinds).
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
  List<TaskStage> get stages;
  @override
  List<TaskEvent> get events;
  @override
  HandoverInfo? get handover;

  /// Create a copy of TaskDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskDetailImplCopyWith<_$TaskDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
