// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CalendarOrder _$CalendarOrderFromJson(Map<String, dynamic> json) {
  return _CalendarOrder.fromJson(json);
}

/// @nodoc
mixin _$CalendarOrder {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_name')
  String? get clientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime get dueDate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_status')
  String get paymentStatus => throw _privateConstructorUsedError;

  /// Serializes this CalendarOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarOrderCopyWith<CalendarOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarOrderCopyWith<$Res> {
  factory $CalendarOrderCopyWith(
          CalendarOrder value, $Res Function(CalendarOrder) then) =
      _$CalendarOrderCopyWithImpl<$Res, CalendarOrder>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'client_name') String? clientName,
      @JsonKey(name: 'due_date') DateTime dueDate,
      String status,
      String priority,
      @JsonKey(name: 'payment_status') String paymentStatus});
}

/// @nodoc
class _$CalendarOrderCopyWithImpl<$Res, $Val extends CalendarOrder>
    implements $CalendarOrderCopyWith<$Res> {
  _$CalendarOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? clientName = freezed,
    Object? dueDate = null,
    Object? status = null,
    Object? priority = null,
    Object? paymentStatus = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CalendarOrderImplCopyWith<$Res>
    implements $CalendarOrderCopyWith<$Res> {
  factory _$$CalendarOrderImplCopyWith(
          _$CalendarOrderImpl value, $Res Function(_$CalendarOrderImpl) then) =
      __$$CalendarOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'order_number') String orderNumber,
      @JsonKey(name: 'client_name') String? clientName,
      @JsonKey(name: 'due_date') DateTime dueDate,
      String status,
      String priority,
      @JsonKey(name: 'payment_status') String paymentStatus});
}

/// @nodoc
class __$$CalendarOrderImplCopyWithImpl<$Res>
    extends _$CalendarOrderCopyWithImpl<$Res, _$CalendarOrderImpl>
    implements _$$CalendarOrderImplCopyWith<$Res> {
  __$$CalendarOrderImplCopyWithImpl(
      _$CalendarOrderImpl _value, $Res Function(_$CalendarOrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of CalendarOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? clientName = freezed,
    Object? dueDate = null,
    Object? status = null,
    Object? priority = null,
    Object? paymentStatus = null,
  }) {
    return _then(_$CalendarOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: freezed == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarOrderImpl extends _CalendarOrder {
  const _$CalendarOrderImpl(
      {required this.id,
      @JsonKey(name: 'order_number') required this.orderNumber,
      @JsonKey(name: 'client_name') this.clientName,
      @JsonKey(name: 'due_date') required this.dueDate,
      required this.status,
      required this.priority,
      @JsonKey(name: 'payment_status') required this.paymentStatus})
      : super._();

  factory _$CalendarOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarOrderImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  @JsonKey(name: 'client_name')
  final String? clientName;
  @override
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @override
  final String status;
  @override
  final String priority;
  @override
  @JsonKey(name: 'payment_status')
  final String paymentStatus;

  @override
  String toString() {
    return 'CalendarOrder(id: $id, orderNumber: $orderNumber, clientName: $clientName, dueDate: $dueDate, status: $status, priority: $priority, paymentStatus: $paymentStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, orderNumber, clientName,
      dueDate, status, priority, paymentStatus);

  /// Create a copy of CalendarOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarOrderImplCopyWith<_$CalendarOrderImpl> get copyWith =>
      __$$CalendarOrderImplCopyWithImpl<_$CalendarOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarOrderImplToJson(
      this,
    );
  }
}

abstract class _CalendarOrder extends CalendarOrder {
  const factory _CalendarOrder(
      {required final String id,
      @JsonKey(name: 'order_number') required final String orderNumber,
      @JsonKey(name: 'client_name') final String? clientName,
      @JsonKey(name: 'due_date') required final DateTime dueDate,
      required final String status,
      required final String priority,
      @JsonKey(name: 'payment_status')
      required final String paymentStatus}) = _$CalendarOrderImpl;
  const _CalendarOrder._() : super._();

  factory _CalendarOrder.fromJson(Map<String, dynamic> json) =
      _$CalendarOrderImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  @JsonKey(name: 'client_name')
  String? get clientName;
  @override
  @JsonKey(name: 'due_date')
  DateTime get dueDate;
  @override
  String get status;
  @override
  String get priority;
  @override
  @JsonKey(name: 'payment_status')
  String get paymentStatus;

  /// Create a copy of CalendarOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarOrderImplCopyWith<_$CalendarOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CalendarResponse _$CalendarResponseFromJson(Map<String, dynamic> json) {
  return _CalendarResponse.fromJson(json);
}

/// @nodoc
mixin _$CalendarResponse {
  List<CalendarOrder> get orders => throw _privateConstructorUsedError;
  List<TaskSummary> get tasks => throw _privateConstructorUsedError;

  /// Serializes this CalendarResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarResponseCopyWith<CalendarResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarResponseCopyWith<$Res> {
  factory $CalendarResponseCopyWith(
          CalendarResponse value, $Res Function(CalendarResponse) then) =
      _$CalendarResponseCopyWithImpl<$Res, CalendarResponse>;
  @useResult
  $Res call({List<CalendarOrder> orders, List<TaskSummary> tasks});
}

/// @nodoc
class _$CalendarResponseCopyWithImpl<$Res, $Val extends CalendarResponse>
    implements $CalendarResponseCopyWith<$Res> {
  _$CalendarResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
    Object? tasks = null,
  }) {
    return _then(_value.copyWith(
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as List<CalendarOrder>,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<TaskSummary>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CalendarResponseImplCopyWith<$Res>
    implements $CalendarResponseCopyWith<$Res> {
  factory _$$CalendarResponseImplCopyWith(_$CalendarResponseImpl value,
          $Res Function(_$CalendarResponseImpl) then) =
      __$$CalendarResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CalendarOrder> orders, List<TaskSummary> tasks});
}

/// @nodoc
class __$$CalendarResponseImplCopyWithImpl<$Res>
    extends _$CalendarResponseCopyWithImpl<$Res, _$CalendarResponseImpl>
    implements _$$CalendarResponseImplCopyWith<$Res> {
  __$$CalendarResponseImplCopyWithImpl(_$CalendarResponseImpl _value,
      $Res Function(_$CalendarResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CalendarResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
    Object? tasks = null,
  }) {
    return _then(_$CalendarResponseImpl(
      orders: null == orders
          ? _value._orders
          : orders // ignore: cast_nullable_to_non_nullable
              as List<CalendarOrder>,
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<TaskSummary>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarResponseImpl implements _CalendarResponse {
  const _$CalendarResponseImpl(
      {final List<CalendarOrder> orders = const <CalendarOrder>[],
      final List<TaskSummary> tasks = const <TaskSummary>[]})
      : _orders = orders,
        _tasks = tasks;

  factory _$CalendarResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarResponseImplFromJson(json);

  final List<CalendarOrder> _orders;
  @override
  @JsonKey()
  List<CalendarOrder> get orders {
    if (_orders is EqualUnmodifiableListView) return _orders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orders);
  }

  final List<TaskSummary> _tasks;
  @override
  @JsonKey()
  List<TaskSummary> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  String toString() {
    return 'CalendarResponse(orders: $orders, tasks: $tasks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarResponseImpl &&
            const DeepCollectionEquality().equals(other._orders, _orders) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_orders),
      const DeepCollectionEquality().hash(_tasks));

  /// Create a copy of CalendarResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarResponseImplCopyWith<_$CalendarResponseImpl> get copyWith =>
      __$$CalendarResponseImplCopyWithImpl<_$CalendarResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarResponseImplToJson(
      this,
    );
  }
}

abstract class _CalendarResponse implements CalendarResponse {
  const factory _CalendarResponse(
      {final List<CalendarOrder> orders,
      final List<TaskSummary> tasks}) = _$CalendarResponseImpl;

  factory _CalendarResponse.fromJson(Map<String, dynamic> json) =
      _$CalendarResponseImpl.fromJson;

  @override
  List<CalendarOrder> get orders;
  @override
  List<TaskSummary> get tasks;

  /// Create a copy of CalendarResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarResponseImplCopyWith<_$CalendarResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
