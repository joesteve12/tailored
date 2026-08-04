import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';
import 'order_addon.dart';
import 'order_item.dart';
import 'order_media.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Mirrors OrderResponse on the restructured backend. Relative to the
/// pre-restructure model this adds the money breakdown the backend now
/// computes — `subtotal`, `discountType` / `discountValue` / `discountAmount`
/// — plus `priority` and the order-level `media` list (max 3).
///
/// Money fields go through `decimalStringToDouble`, which accepts either a
/// Decimal-string or a raw JSON number — the backend currently serialises
/// these as numbers. The app never does authoritative money math (the
/// backend settles every figure), so a double for display is fine.
///
/// `subtotal` means **items + addons**. `itemsSubtotal` and `addonsTotal`
/// are the two components; orders with no addons have `addonsTotal == 0` and
/// `subtotal == itemsSubtotal`, so the figure is unchanged from before the
/// money rebuild for every existing order.
///
/// `paymentStatus` has four values: unpaid | partial | paid | **overpaid**.
/// The last means the shop owes a refund — see [refundDue].
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
    // The list endpoint denormalises the client's name onto each order so the
    // list card can render it without a per-row client fetch. Nullable because
    // single-order reads (getById) don't include it — the order detail screen
    // gets the name from its own client tile instead.
    @JsonKey(name: 'client_name') String? clientName,
    @JsonKey(name: 'order_number') required String orderNumber,
    required String status,
    @Default('normal') String priority,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'items_subtotal', fromJson: decimalStringToDouble)
    @Default(0) double itemsSubtotal,
    @JsonKey(name: 'addons_total', fromJson: decimalStringToDouble)
    @Default(0) double addonsTotal,
    @JsonKey(name: 'subtotal', fromJson: decimalStringToDouble)
    @Default(0) double subtotal,
    @JsonKey(name: 'discount_type') @Default('none') String discountType,
    @JsonKey(name: 'discount_value', fromJson: decimalStringToDouble)
    @Default(0) double discountValue,
    @JsonKey(name: 'discount_amount', fromJson: decimalStringToDouble)
    @Default(0) double discountAmount,
    @JsonKey(name: 'discount_includes_addons')
    @Default(true) bool discountIncludesAddons,
    @JsonKey(name: 'total_amount', fromJson: decimalStringToDouble)
    required double totalAmount,
    @JsonKey(name: 'amount_paid', fromJson: decimalStringToDouble)
    required double amountPaid,
    @JsonKey(name: 'payment_status') required String paymentStatus,
    String? notes,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @Default(<OrderAddon>[]) List<OrderAddon> addons,
    @Default(<OrderMedia>[]) List<OrderMedia> media,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// What's still owed **to the shop**. Zero once the order is settled, and
  /// zero when it's in credit.
  ///
  /// This used to be `(totalAmount - amountPaid).clamp(0, totalAmount)`, and
  /// removing that clamp is the point of the whole rebuild on this side. The
  /// clamp silently swallowed credit: remove a garment from a paid order and
  /// the card would cheerfully report `Balance due ₦0` while the shop owed
  /// the client ₦9,500. Do not reinstate it — read [refundDue] instead.
  double get balanceDue {
    final owed = totalAmount - amountPaid;
    return owed > 0 ? owed : 0;
  }

  /// What's owed **back to the client**. Zero unless the order is in credit.
  ///
  /// Only one of [balanceDue] and [refundDue] is ever non-zero, so the money
  /// card can show whichever is live and never both.
  double get refundDue {
    final credit = amountPaid - totalAmount;
    return credit > 0 ? credit : 0;
  }

  /// True when the shop owes money back. Reads the backend's settled
  /// `payment_status` rather than re-deriving it from the figures — the
  /// server is authoritative, and a client-side comparison of two doubles
  /// would disagree with it at the margins.
  bool get isOverpaid => paymentStatus == 'overpaid';

  /// True when this order carries chargeable extras. Gates the
  /// Garments/Extras split on the money card and the
  /// discount-includes-addons prompt — both are noise on a plain order.
  bool get hasAddons => addons.isNotEmpty;

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
