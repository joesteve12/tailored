import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'document_issue.freezed.dart';
part 'document_issue.g.dart';

/// Mirrors the backend `DocumentIssueResponse` — one entry in the
/// append-only log of every invoice, receipt and work order this shop has
/// actually generated.
///
/// This table is what makes hard-deleting a payment safe, which is why
/// **every identifying field here is a copy, not a join**. [orderNumber],
/// [clientName], [amount] and [balanceAfter] were captured at generation
/// time; [orderId] and [paymentId] go null when the thing they point at is
/// deleted, and the row stays readable regardless: "receipt RCP-0007 for
/// ORD-20260627-2131-A7F2, Adaeze, ₦50,000, balance ₦45,000".
///
/// So a UI rendering this list must lead with the denormalised fields and
/// treat the two ids as optional deep links. Keying a row off [paymentId]
/// will produce blanks on exactly the rows that matter most — the ones whose
/// payment was removed.
///
/// [documentNumber] carries the receipt number on receipts and is null on
/// invoices and work orders, which are unnumbered.
@freezed
class DocumentIssue with _$DocumentIssue {
  const DocumentIssue._();

  const factory DocumentIssue({
    required String id,
    @JsonKey(name: 'order_id') String? orderId,
    @JsonKey(name: 'payment_id') String? paymentId,

    /// 'invoice' | 'receipt' | 'work_order'.
    required String kind,
    @JsonKey(name: 'document_number') String? documentNumber,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'client_name') String? clientName,
    @JsonKey(fromJson: nullableDecimalToDouble) double? amount,
    @JsonKey(name: 'balance_after', fromJson: nullableDecimalToDouble)
    double? balanceAfter,
    @JsonKey(name: 'generated_at') required DateTime generatedAt,
  }) = _DocumentIssue;

  bool get isReceipt => kind == 'receipt';

  factory DocumentIssue.fromJson(Map<String, dynamic> json) =>
      _$DocumentIssueFromJson(json);
}
