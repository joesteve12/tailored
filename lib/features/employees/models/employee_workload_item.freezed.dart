// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_workload_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EmployeeWorkloadItem _$EmployeeWorkloadItemFromJson(Map<String, dynamic> json) {
  return _EmployeeWorkloadItem.fromJson(json);
}

/// @nodoc
mixin _$EmployeeWorkloadItem {
  @JsonKey(name: 'stage_id')
  String get stageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_id')
  String get taskId => throw _privateConstructorUsedError;
  @JsonKey(name: 'process_name')
  String get processName => throw _privateConstructorUsedError;
  int get sequence => throw _privateConstructorUsedError;
  @JsonKey(name: 'stage_state')
  String get stageState => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_item_id')
  String get orderItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'garment_type')
  String get garmentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_state')
  String get productionState => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_completion_date')
  DateTime get expectedCompletionDate => throw _privateConstructorUsedError;

  /// Serializes this EmployeeWorkloadItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmployeeWorkloadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmployeeWorkloadItemCopyWith<EmployeeWorkloadItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmployeeWorkloadItemCopyWith<$Res> {
  factory $EmployeeWorkloadItemCopyWith(EmployeeWorkloadItem value,
          $Res Function(EmployeeWorkloadItem) then) =
      _$EmployeeWorkloadItemCopyWithImpl<$Res, EmployeeWorkloadItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'stage_id') String stageId,
      @JsonKey(name: 'task_id') String taskId,
      @JsonKey(name: 'process_name') String processName,
      int sequence,
      @JsonKey(name: 'stage_state') String stageState,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'expected_completion_date')
      DateTime expectedCompletionDate});
}

/// @nodoc
class _$EmployeeWorkloadItemCopyWithImpl<$Res,
        $Val extends EmployeeWorkloadItem>
    implements $EmployeeWorkloadItemCopyWith<$Res> {
  _$EmployeeWorkloadItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmployeeWorkloadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? taskId = null,
    Object? processName = null,
    Object? sequence = null,
    Object? stageState = null,
    Object? orderItemId = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? dueDate = freezed,
    Object? expectedCompletionDate = null,
  }) {
    return _then(_value.copyWith(
      stageId: null == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      sequence: null == sequence
          ? _value.sequence
          : sequence // ignore: cast_nullable_to_non_nullable
              as int,
      stageState: null == stageState
          ? _value.stageState
          : stageState // ignore: cast_nullable_to_non_nullable
              as String,
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expectedCompletionDate: null == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EmployeeWorkloadItemImplCopyWith<$Res>
    implements $EmployeeWorkloadItemCopyWith<$Res> {
  factory _$$EmployeeWorkloadItemImplCopyWith(_$EmployeeWorkloadItemImpl value,
          $Res Function(_$EmployeeWorkloadItemImpl) then) =
      __$$EmployeeWorkloadItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'stage_id') String stageId,
      @JsonKey(name: 'task_id') String taskId,
      @JsonKey(name: 'process_name') String processName,
      int sequence,
      @JsonKey(name: 'stage_state') String stageState,
      @JsonKey(name: 'order_item_id') String orderItemId,
      @JsonKey(name: 'garment_type') String garmentType,
      @JsonKey(name: 'production_state') String productionState,
      @JsonKey(name: 'order_id') String orderId,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'due_date') DateTime? dueDate,
      @JsonKey(name: 'expected_completion_date')
      DateTime expectedCompletionDate});
}

/// @nodoc
class __$$EmployeeWorkloadItemImplCopyWithImpl<$Res>
    extends _$EmployeeWorkloadItemCopyWithImpl<$Res, _$EmployeeWorkloadItemImpl>
    implements _$$EmployeeWorkloadItemImplCopyWith<$Res> {
  __$$EmployeeWorkloadItemImplCopyWithImpl(_$EmployeeWorkloadItemImpl _value,
      $Res Function(_$EmployeeWorkloadItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of EmployeeWorkloadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? taskId = null,
    Object? processName = null,
    Object? sequence = null,
    Object? stageState = null,
    Object? orderItemId = null,
    Object? garmentType = null,
    Object? productionState = null,
    Object? orderId = null,
    Object? orderNumber = null,
    Object? dueDate = freezed,
    Object? expectedCompletionDate = null,
  }) {
    return _then(_$EmployeeWorkloadItemImpl(
      stageId: null == stageId
          ? _value.stageId
          : stageId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      processName: null == processName
          ? _value.processName
          : processName // ignore: cast_nullable_to_non_nullable
              as String,
      sequence: null == sequence
          ? _value.sequence
          : sequence // ignore: cast_nullable_to_non_nullable
              as int,
      stageState: null == stageState
          ? _value.stageState
          : stageState // ignore: cast_nullable_to_non_nullable
              as String,
      orderItemId: null == orderItemId
          ? _value.orderItemId
          : orderItemId // ignore: cast_nullable_to_non_nullable
              as String,
      garmentType: null == garmentType
          ? _value.garmentType
          : garmentType // ignore: cast_nullable_to_non_nullable
              as String,
      productionState: null == productionState
          ? _value.productionState
          : productionState // ignore: cast_nullable_to_non_nullable
              as String,
      orderId: null == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expectedCompletionDate: null == expectedCompletionDate
          ? _value.expectedCompletionDate
          : expectedCompletionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EmployeeWorkloadItemImpl extends _EmployeeWorkloadItem {
  const _$EmployeeWorkloadItemImpl(
      {@JsonKey(name: 'stage_id') required this.stageId,
      @JsonKey(name: 'task_id') required this.taskId,
      @JsonKey(name: 'process_name') required this.processName,
      required this.sequence,
      @JsonKey(name: 'stage_state') required this.stageState,
      @JsonKey(name: 'order_item_id') required this.orderItemId,
      @JsonKey(name: 'garment_type') required this.garmentType,
      @JsonKey(name: 'production_state') required this.productionState,
      @JsonKey(name: 'order_id') required this.orderId,
      @JsonKey(name: 'order_number') required this.orderNumber,
      @JsonKey(name: 'due_date') this.dueDate,
      @JsonKey(name: 'expected_completion_date')
      required this.expectedCompletionDate})
      : super._();

  factory _$EmployeeWorkloadItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmployeeWorkloadItemImplFromJson(json);

  @override
  @JsonKey(name: 'stage_id')
  final String stageId;
  @override
  @JsonKey(name: 'task_id')
  final String taskId;
  @override
  @JsonKey(name: 'process_name')
  final String processName;
  @override
  final int sequence;
  @override
  @JsonKey(name: 'stage_state')
  final String stageState;
  @override
  @JsonKey(name: 'order_item_id')
  final String orderItemId;
  @override
  @JsonKey(name: 'garment_type')
  final String garmentType;
  @override
  @JsonKey(name: 'production_state')
  final String productionState;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'expected_completion_date')
  final DateTime expectedCompletionDate;

  @override
  String toString() {
    return 'EmployeeWorkloadItem(stageId: $stageId, taskId: $taskId, processName: $processName, sequence: $sequence, stageState: $stageState, orderItemId: $orderItemId, garmentType: $garmentType, productionState: $productionState, orderId: $orderId, orderNumber: $orderNumber, dueDate: $dueDate, expectedCompletionDate: $expectedCompletionDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmployeeWorkloadItemImpl &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.processName, processName) ||
                other.processName == processName) &&
            (identical(other.sequence, sequence) ||
                other.sequence == sequence) &&
            (identical(other.stageState, stageState) ||
                other.stageState == stageState) &&
            (identical(other.orderItemId, orderItemId) ||
                other.orderItemId == orderItemId) &&
            (identical(other.garmentType, garmentType) ||
                other.garmentType == garmentType) &&
            (identical(other.productionState, productionState) ||
                other.productionState == productionState) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.expectedCompletionDate, expectedCompletionDate) ||
                other.expectedCompletionDate == expectedCompletionDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stageId,
      taskId,
      processName,
      sequence,
      stageState,
      orderItemId,
      garmentType,
      productionState,
      orderId,
      orderNumber,
      dueDate,
      expectedCompletionDate);

  /// Create a copy of EmployeeWorkloadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmployeeWorkloadItemImplCopyWith<_$EmployeeWorkloadItemImpl>
      get copyWith =>
          __$$EmployeeWorkloadItemImplCopyWithImpl<_$EmployeeWorkloadItemImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EmployeeWorkloadItemImplToJson(
      this,
    );
  }
}

abstract class _EmployeeWorkloadItem extends EmployeeWorkloadItem {
  const factory _EmployeeWorkloadItem(
      {@JsonKey(name: 'stage_id') required final String stageId,
      @JsonKey(name: 'task_id') required final String taskId,
      @JsonKey(name: 'process_name') required final String processName,
      required final int sequence,
      @JsonKey(name: 'stage_state') required final String stageState,
      @JsonKey(name: 'order_item_id') required final String orderItemId,
      @JsonKey(name: 'garment_type') required final String garmentType,
      @JsonKey(name: 'production_state') required final String productionState,
      @JsonKey(name: 'order_id') required final String orderId,
      @JsonKey(name: 'order_number') required final String orderNumber,
      @JsonKey(name: 'due_date') final DateTime? dueDate,
      @JsonKey(name: 'expected_completion_date')
      required final DateTime
          expectedCompletionDate}) = _$EmployeeWorkloadItemImpl;
  const _EmployeeWorkloadItem._() : super._();

  factory _EmployeeWorkloadItem.fromJson(Map<String, dynamic> json) =
      _$EmployeeWorkloadItemImpl.fromJson;

  @override
  @JsonKey(name: 'stage_id')
  String get stageId;
  @override
  @JsonKey(name: 'task_id')
  String get taskId;
  @override
  @JsonKey(name: 'process_name')
  String get processName;
  @override
  int get sequence;
  @override
  @JsonKey(name: 'stage_state')
  String get stageState;
  @override
  @JsonKey(name: 'order_item_id')
  String get orderItemId;
  @override
  @JsonKey(name: 'garment_type')
  String get garmentType;
  @override
  @JsonKey(name: 'production_state')
  String get productionState;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'expected_completion_date')
  DateTime get expectedCompletionDate;

  /// Create a copy of EmployeeWorkloadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmployeeWorkloadItemImplCopyWith<_$EmployeeWorkloadItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}
