import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Mirrors the backend PaymentResponse. Note `amount` arrives as a JSON
/// *number* here (PaymentResponse encodes Decimal→float), unlike the order's
/// money fields which are Decimal-strings — [decimalStringToDouble] accepts
/// either, so the same converter is reused for consistency.
///
/// Voiding a payment is a *soft delete* on the server: the row stays,
/// `voided_at` is set, and the order's `amount_paid` / `payment_status` are
/// recomputed excluding it. The Payments tab in the Activity section
/// renders voided rows as history (greyed / struck-through) so the log
/// stays complete — that's why `voidedAt` is on the client model.
@freezed
class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(fromJson: decimalStringToDouble) required double amount,
    required String method,
    String? notes,
    @JsonKey(name: 'paid_at') required DateTime paidAt,
    @JsonKey(name: 'voided_at') DateTime? voidedAt,
  }) = _Payment;

  /// True when this payment has been voided and should render as history
  /// rather than an active row. The record itself stays in the log either
  /// way.
  bool get isVoided => voidedAt != null;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
