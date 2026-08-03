// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String get clientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_number')
  String get orderNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
  double get itemsSubtotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
  double get addonsTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
  double get subtotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_type')
  String get discountType => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
  double get discountValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
  double get discountAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_includes_addons')
  bool get discountIncludesAddons => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
  double get amountPaid => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_status')
  String get paymentStatus => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<OrderItem> get items => throw _privateConstructorUsedError;
  List<OrderAddon> get addons => throw _privateConstructorUsedError;
  List<OrderMedia> get media => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String clientId,
      @JsonKey(name: 'order_number') String orderNumber,
      String status,
      String priority,
      @JsonKey(name: 'due_date') DateTime dueDate,
      @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
      double itemsSubtotal,
      @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
      double addonsTotal,
      @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
      double subtotal,
      @JsonKey(name: 'discount_type') String discountType,
      @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
      double discountValue,
      @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
      double discountAmount,
      @JsonKey(name: 'discount_includes_addons') bool discountIncludesAddons,
      @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
      double totalAmount,
      @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
      double amountPaid,
      @JsonKey(name: 'payment_status') String paymentStatus,
      String? notes,
      List<OrderItem> items,
      List<OrderAddon> addons,
      List<OrderMedia> media,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? orderNumber = null,
    Object? status = null,
    Object? priority = null,
    Object? dueDate = null,
    Object? itemsSubtotal = null,
    Object? addonsTotal = null,
    Object? subtotal = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? discountAmount = null,
    Object? discountIncludesAddons = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? paymentStatus = null,
    Object? notes = freezed,
    Object? items = null,
    Object? addons = null,
    Object? media = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      itemsSubtotal: null == itemsSubtotal
          ? _value.itemsSubtotal
          : itemsSubtotal // ignore: cast_nullable_to_non_nullable
              as double,
      addonsTotal: null == addonsTotal
          ? _value.addonsTotal
          : addonsTotal // ignore: cast_nullable_to_non_nullable
              as double,
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      discountIncludesAddons: null == discountIncludesAddons
          ? _value.discountIncludesAddons
          : discountIncludesAddons // ignore: cast_nullable_to_non_nullable
              as bool,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      amountPaid: null == amountPaid
          ? _value.amountPaid
          : amountPaid // ignore: cast_nullable_to_non_nullable
              as double,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      addons: null == addons
          ? _value.addons
          : addons // ignore: cast_nullable_to_non_nullable
              as List<OrderAddon>,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as List<OrderMedia>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
          _$OrderImpl value, $Res Function(_$OrderImpl) then) =
      __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'client_id') String clientId,
      @JsonKey(name: 'order_number') String orderNumber,
      String status,
      String priority,
      @JsonKey(name: 'due_date') DateTime dueDate,
      @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
      double itemsSubtotal,
      @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
      double addonsTotal,
      @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
      double subtotal,
      @JsonKey(name: 'discount_type') String discountType,
      @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
      double discountValue,
      @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
      double discountAmount,
      @JsonKey(name: 'discount_includes_addons') bool discountIncludesAddons,
      @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
      double totalAmount,
      @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
      double amountPaid,
      @JsonKey(name: 'payment_status') String paymentStatus,
      String? notes,
      List<OrderItem> items,
      List<OrderAddon> addons,
      List<OrderMedia> media,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
      _$OrderImpl _value, $Res Function(_$OrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? orderNumber = null,
    Object? status = null,
    Object? priority = null,
    Object? dueDate = null,
    Object? itemsSubtotal = null,
    Object? addonsTotal = null,
    Object? subtotal = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? discountAmount = null,
    Object? discountIncludesAddons = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? paymentStatus = null,
    Object? notes = freezed,
    Object? items = null,
    Object? addons = null,
    Object? media = null,
    Object? createdAt = null,
  }) {
    return _then(_$OrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      orderNumber: null == orderNumber
          ? _value.orderNumber
          : orderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      itemsSubtotal: null == itemsSubtotal
          ? _value.itemsSubtotal
          : itemsSubtotal // ignore: cast_nullable_to_non_nullable
              as double,
      addonsTotal: null == addonsTotal
          ? _value.addonsTotal
          : addonsTotal // ignore: cast_nullable_to_non_nullable
              as double,
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      discountValue: null == discountValue
          ? _value.discountValue
          : discountValue // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      discountIncludesAddons: null == discountIncludesAddons
          ? _value.discountIncludesAddons
          : discountIncludesAddons // ignore: cast_nullable_to_non_nullable
              as bool,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      amountPaid: null == amountPaid
          ? _value.amountPaid
          : amountPaid // ignore: cast_nullable_to_non_nullable
              as double,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      addons: null == addons
          ? _value._addons
          : addons // ignore: cast_nullable_to_non_nullable
              as List<OrderAddon>,
      media: null == media
          ? _value._media
          : media // ignore: cast_nullable_to_non_nullable
              as List<OrderMedia>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl extends _Order {
  const _$OrderImpl(
      {required this.id,
      @JsonKey(name: 'client_id') required this.clientId,
      @JsonKey(name: 'order_number') required this.orderNumber,
      required this.status,
      this.priority = 'normal',
      @JsonKey(name: 'due_date') required this.dueDate,
      @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
      this.itemsSubtotal = 0,
      @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
      this.addonsTotal = 0,
      @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
      this.subtotal = 0,
      @JsonKey(name: 'discount_type') this.discountType = 'none',
      @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
      this.discountValue = 0,
      @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
      this.discountAmount = 0,
      @JsonKey(name: 'discount_includes_addons')
      this.discountIncludesAddons = true,
      @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
      required this.totalAmount,
      @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
      required this.amountPaid,
      @JsonKey(name: 'payment_status') required this.paymentStatus,
      this.notes,
      final List<OrderItem> items = const <OrderItem>[],
      final List<OrderAddon> addons = const <OrderAddon>[],
      final List<OrderMedia> media = const <OrderMedia>[],
      @JsonKey(name: 'created_at') required this.createdAt})
      : _items = items,
        _addons = addons,
        _media = media,
        super._();

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @override
  final String status;
  @override
  @JsonKey()
  final String priority;
  @override
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @override
  @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
  final double itemsSubtotal;
  @override
  @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
  final double addonsTotal;
  @override
  @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
  final double subtotal;
  @override
  @JsonKey(name: 'discount_type')
  final String discountType;
  @override
  @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
  final double discountValue;
  @override
  @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
  final double discountAmount;
  @override
  @JsonKey(name: 'discount_includes_addons')
  final bool discountIncludesAddons;
  @override
  @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
  final double totalAmount;
  @override
  @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
  final double amountPaid;
  @override
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @override
  final String? notes;
  final List<OrderItem> _items;
  @override
  @JsonKey()
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<OrderAddon> _addons;
  @override
  @JsonKey()
  List<OrderAddon> get addons {
    if (_addons is EqualUnmodifiableListView) return _addons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_addons);
  }

  final List<OrderMedia> _media;
  @override
  @JsonKey()
  List<OrderMedia> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'Order(id: $id, clientId: $clientId, orderNumber: $orderNumber, status: $status, priority: $priority, dueDate: $dueDate, itemsSubtotal: $itemsSubtotal, addonsTotal: $addonsTotal, subtotal: $subtotal, discountType: $discountType, discountValue: $discountValue, discountAmount: $discountAmount, discountIncludesAddons: $discountIncludesAddons, totalAmount: $totalAmount, amountPaid: $amountPaid, paymentStatus: $paymentStatus, notes: $notes, items: $items, addons: $addons, media: $media, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.itemsSubtotal, itemsSubtotal) ||
                other.itemsSubtotal == itemsSubtotal) &&
            (identical(other.addonsTotal, addonsTotal) ||
                other.addonsTotal == addonsTotal) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.discountIncludesAddons, discountIncludesAddons) ||
                other.discountIncludesAddons == discountIncludesAddons) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._addons, _addons) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        clientId,
        orderNumber,
        status,
        priority,
        dueDate,
        itemsSubtotal,
        addonsTotal,
        subtotal,
        discountType,
        discountValue,
        discountAmount,
        discountIncludesAddons,
        totalAmount,
        amountPaid,
        paymentStatus,
        notes,
        const DeepCollectionEquality().hash(_items),
        const DeepCollectionEquality().hash(_addons),
        const DeepCollectionEquality().hash(_media),
        createdAt
      ]);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(
      this,
    );
  }
}

abstract class _Order extends Order {
  const factory _Order(
          {required final String id,
          @JsonKey(name: 'client_id') required final String clientId,
          @JsonKey(name: 'order_number') required final String orderNumber,
          required final String status,
          final String priority,
          @JsonKey(name: 'due_date') required final DateTime dueDate,
          @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
          final double itemsSubtotal,
          @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
          final double addonsTotal,
          @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
          final double subtotal,
          @JsonKey(name: 'discount_type') final String discountType,
          @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
          final double discountValue,
          @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
          final double discountAmount,
          @JsonKey(name: 'discount_includes_addons')
          final bool discountIncludesAddons,
          @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
          required final double totalAmount,
          @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
          required final double amountPaid,
          @JsonKey(name: 'payment_status') required final String paymentStatus,
          final String? notes,
          final List<OrderItem> items,
          final List<OrderAddon> addons,
          final List<OrderMedia> media,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$OrderImpl;
  const _Order._() : super._();

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String get clientId;
  @override
  @JsonKey(name: 'order_number')
  String get orderNumber;
  @override
  String get status;
  @override
  String get priority;
  @override
  @JsonKey(name: 'due_date')
  DateTime get dueDate;
  @override
  @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
  double get itemsSubtotal;
  @override
  @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
  double get addonsTotal;
  @override
  @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
  double get subtotal;
  @override
  @JsonKey(name: 'discount_type')
  String get discountType;
  @override
  @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
  double get discountValue;
  @override
  @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
  double get discountAmount;
  @override
  @JsonKey(name: 'discount_includes_addons')
  bool get discountIncludesAddons;
  @override
  @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
  double get totalAmount;
  @override
  @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
  double get amountPaid;
  @override
  @JsonKey(name: 'payment_status')
  String get paymentStatus;
  @override
  String? get notes;
  @override
  List<OrderItem> get items;
  @override
  List<OrderAddon> get addons;
  @override
  List<OrderMedia> get media;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderListResponse _$OrderListResponseFromJson(Map<String, dynamic> json) {
  return _OrderListResponse.fromJson(json);
}

/// @nodoc
mixin _$OrderListResponse {
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  @JsonKey(name: 'page_size')
  int get pageSize => throw _privateConstructorUsedError;
  List<Order> get results => throw _privateConstructorUsedError;

  /// Serializes this OrderListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderListResponseCopyWith<OrderListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderListResponseCopyWith<$Res> {
  factory $OrderListResponseCopyWith(
          OrderListResponse value, $Res Function(OrderListResponse) then) =
      _$OrderListResponseCopyWithImpl<$Res, OrderListResponse>;
  @useResult
  $Res call(
      {int total,
      int page,
      @JsonKey(name: 'page_size') int pageSize,
      List<Order> results});
}

/// @nodoc
class _$OrderListResponseCopyWithImpl<$Res, $Val extends OrderListResponse>
    implements $OrderListResponseCopyWith<$Res> {
  _$OrderListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderListResponse
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
              as List<Order>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderListResponseImplCopyWith<$Res>
    implements $OrderListResponseCopyWith<$Res> {
  factory _$$OrderListResponseImplCopyWith(_$OrderListResponseImpl value,
          $Res Function(_$OrderListResponseImpl) then) =
      __$$OrderListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int total,
      int page,
      @JsonKey(name: 'page_size') int pageSize,
      List<Order> results});
}

/// @nodoc
class __$$OrderListResponseImplCopyWithImpl<$Res>
    extends _$OrderListResponseCopyWithImpl<$Res, _$OrderListResponseImpl>
    implements _$$OrderListResponseImplCopyWith<$Res> {
  __$$OrderListResponseImplCopyWithImpl(_$OrderListResponseImpl _value,
      $Res Function(_$OrderListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
    Object? results = null,
  }) {
    return _then(_$OrderListResponseImpl(
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
              as List<Order>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderListResponseImpl implements _OrderListResponse {
  const _$OrderListResponseImpl(
      {required this.total,
      required this.page,
      @JsonKey(name: 'page_size') required this.pageSize,
      required final List<Order> results})
      : _results = results;

  factory _$OrderListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderListResponseImplFromJson(json);

  @override
  final int total;
  @override
  final int page;
  @override
  @JsonKey(name: 'page_size')
  final int pageSize;
  final List<Order> _results;
  @override
  List<Order> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  String toString() {
    return 'OrderListResponse(total: $total, page: $page, pageSize: $pageSize, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderListResponseImpl &&
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

  /// Create a copy of OrderListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderListResponseImplCopyWith<_$OrderListResponseImpl> get copyWith =>
      __$$OrderListResponseImplCopyWithImpl<_$OrderListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderListResponseImplToJson(
      this,
    );
  }
}

abstract class _OrderListResponse implements OrderListResponse {
  const factory _OrderListResponse(
      {required final int total,
      required final int page,
      @JsonKey(name: 'page_size') required final int pageSize,
      required final List<Order> results}) = _$OrderListResponseImpl;

  factory _OrderListResponse.fromJson(Map<String, dynamic> json) =
      _$OrderListResponseImpl.fromJson;

  @override
  int get total;
  @override
  int get page;
  @override
  @JsonKey(name: 'page_size')
  int get pageSize;
  @override
  List<Order> get results;

  /// Create a copy of OrderListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderListResponseImplCopyWith<_$OrderListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
