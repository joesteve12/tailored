import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Mirrors the backend `PaymentResponse` — one money event on an order,
/// either money in (`kind == 'payment'`) or money back out
/// (`kind == 'refund'`). Both live in one list so an order has a single
/// chronological money timeline rather than two the reader has to merge.
///
/// **Refund amounts arrive positive** and are negated at the point of
/// display. A signed `amount` would have made every existing sum in the app
/// and the backend look correct while being wrong.
///
/// **There is no `voidedAt` any more.** Voiding was a server-side soft
/// delete: the row stayed, a flag was set, and every query that touched
/// payments had to remember to filter on it — which several didn't, so
/// voided rows leaked into platform revenue and into the receipt builder.
/// Deletion is now a real delete. The record of what was actually printed
/// survives in `document_issues` (see [DocumentIssue]), which keeps
/// denormalised copies of the order number, client name, amount and balance
/// precisely so it can outlive the row it describes. Rows here are either
/// present or gone; nothing renders greyed or struck through.
///
/// Money fields go through the converters in `json_converters.dart`, which
/// accept a Decimal-string or a raw JSON number — the backend currently
/// sends numbers.
@freezed
class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,

    /// 'payment' | 'refund'. Defaulted rather than required so a response
    /// from an older build can still be parsed instead of throwing.
    @Default('payment') String kind,
    @JsonKey(fromJson: decimalStringToDouble) required double amount,

    /// A gratuity handed over with this payment.
    ///
    /// Deliberately NOT part of [amount]: a tip never touches the order's
    /// `totalAmount` or `amountPaid` and never moves `paymentStatus`.
    /// Modelling it as an addon would inflate the order and make the invoice
    /// look like the shop billed for its own tip.
    @JsonKey(name: 'tip_amount', fromJson: decimalStringToDouble)
    @Default(0) double tipAmount,
    required String method,

    /// Why money went back out. Required by the backend on refunds, always
    /// null on payments.
    String? reason,
    String? notes,
    @JsonKey(name: 'paid_at') required DateTime paidAt,

    /// When the row was inserted — insertion order, not the (possibly
    /// back-dated) [paidAt] shown in the timeline. Only the most recently
    /// inserted entry on an order is deletable, because every later row's
    /// frozen snapshot counts this one in; the UI uses this to show the delete
    /// action on that entry alone (see [OrderActivitySection]).
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Allocated once, per shop, when the row was recorded. Null on payments
    /// that predate the money rebuild.
    @JsonKey(name: 'receipt_number') String? receiptNumber,

    /// Frozen snapshot of the order's total and running paid figure at the
    /// moment this row was recorded — never recomputed. Both are null on
    /// legacy rows; the historical values aren't recoverable from anything
    /// still in the database, so no backfill was attempted.
    @JsonKey(name: 'order_total_at_payment', fromJson: nullableDecimalToDouble)
    double? orderTotalAtPayment,
    @JsonKey(name: 'amount_paid_after', fromJson: nullableDecimalToDouble)
    double? amountPaidAfter,
  }) = _Payment;

  /// True when this row is money leaving the shop.
  bool get isRefund => kind == 'refund';

  /// Epsilon comparisons throughout, matching the convention elsewhere in the
  /// money UI. These are doubles parsed from the wire; `== 0` on a double is
  /// a coin flip nobody should be making about whether a row is a tip.
  bool get hasTip => tipAmount > 0.005;

  /// A tip recorded on its own — the customer collects, is delighted, and
  /// hands over a dash. Recorded as `amount: 0, tipAmount: n`, which settles
  /// nothing on the order and so leaves `paymentStatus` untouched.
  bool get isStandaloneTip => amount < 0.005 && tipAmount > 0.005;

  /// Everything that changed hands in this transaction, tip included. For
  /// the receipt's "total received" line only — never for balance math.
  double get totalReceived => amount + tipAmount;

  /// The balance remaining after this exact payment, read from the frozen
  /// snapshot and never computed live.
  ///
  /// Null for rows recorded before snapshots existed — render
  /// [kUnknownFigure] (an em dash), not a number. Deriving one from today's
  /// order total would put a confident, wrong figure on a document a client
  /// may still be holding a printed copy of.
  double? get balanceAfter {
    final total = orderTotalAtPayment;
    final paid = amountPaidAfter;
    if (total == null || paid == null) return null;
    return total - paid;
  }

  /// The amount as it should read in a timeline: negative for a refund.
  /// Pair with `formatSignedNaira` so a refund renders `−₦9,500` and a
  /// payment `+₦50,000`.
  double get signedAmount => isRefund ? -amount : amount;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
