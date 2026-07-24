import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';
import 'order_item.dart';
import 'order_media.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Mirrors OrderResponse on the restructured backend. Relative to the
/// pre-restructure model this adds the money breakdown the backend now
/// computes — `subtotal`, `discountType` / `discountValue` / `discountAmount`
/// — plus `priority` and the order-level `media` list (max 3).
///
/// All money fields arrive as Decimal-strings and go through
/// `decimalStringToDouble`; the app never does authoritative money math
/// (the backend settles every figure), so a double for display is fine.
///
/// `dueDate` is the backend's date-only field. `DateTime.parse` handles a
/// bare "YYYY-MM-DD" on the way in, but the reverse (sending it back in a
/// body) must NOT include a time component — see OrderRepository's
/// `_dateOnly`; never call `.toIso8601String()` on a due date in a request.
///
/// `status` is the **order-level** status (pending / in_progress / on_hold /
/// ready / delivered / cancelled), distinct from each item's production
/// status. Both are plain strings, mapped to labels at the view layer
/// (`orderStatusLabel`). `priority` is likewise a string
/// (low / normal / high / urgent), rendered via `priorityLabel`.
@freezed
class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    @JsonKey(name: 'order_number') required String orderNumber,
    required String status,
    @Default('normal') String priority,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
    @Default(0) double subtotal,
    @JsonKey(name: 'discount_type') @Default('none') String discountType,
    @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
    @Default(0) double discountValue,
    @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
    @Default(0) double discountAmount,
    @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
    required double totalAmount,
    @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
    required double amountPaid,
    @JsonKey(name: 'payment_status') required String paymentStatus,
    String? notes,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @Default(<OrderMedia>[]) List<OrderMedia> media,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// What's still owed — for the payment summary card.
  double get balanceDue => (totalAmount - amountPaid).clamp(0, totalAmount);

  /// True when this order has an active discount (type set and amount > 0).
  bool get hasDiscount => discountType != 'none' && discountAmount > 0;

  /// True when the order is in a terminal state and can no longer be
  /// edited (matches the backend's LOCKED_STATUSES). Used to hide/disable
  /// item-edit, media, and detail-edit affordances client-side rather than
  /// only learning it from a rejected request.
  bool get isLocked => status == 'delivered' || status == 'cancelled';

  /// True when the order has room for another media file (backend caps at 3).
  bool get canAddMedia => media.length < 3;
}

/// Mirrors OrderListResponse — same {total, page, page_size, results}
/// envelope as the clients list.
@freezed
class OrderListResponse with _$OrderListResponse {
  const factory OrderListResponse({
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    required List<Order> results,
  }) = _OrderListResponse;

  factory OrderListResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderListResponseFromJson(json);
}
