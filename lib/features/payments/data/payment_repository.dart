import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/payment.dart';

/// Payments and refunds both live under `/orders/{id}/payments` — one money
/// timeline per order, with `kind` distinguishing direction.
///
/// There's no update: a money event is recorded or removed, never edited.
/// Removal is now a **hard delete** ([deletePayment]); the old void was a
/// soft delete whose flag every query had to remember, and several didn't.
/// The audit trail lives in `document_issues` instead — see
/// `DocumentRepository.listDocuments`.
///
/// The order's `amount_paid` / `payment_status` are recomputed server-side on
/// every record, refund and delete, so callers refetch the order afterwards
/// rather than adjusting figures locally.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// Serialises a client-chosen timestamp for `paid_at`.
  ///
  /// **This is the opposite of `dueDate`** — do not reuse the orders repo's
  /// `_dateOnly` here. `paid_at` is a full timestamp; sending a bare date
  /// would drop the time the backend uses to order same-day rows.
  ///
  /// Converted to UTC and sent with an explicit `Z`. That matters more than
  /// it looks: `DateTime.toIso8601String()` on a *local* DateTime emits no
  /// offset at all, and the backend reads an offsetless timestamp as UTC. In
  /// WAT (UTC+1) a picker set to local midnight would then be filed an hour
  /// off — and since the backend compares `paid_at` against its floor at UTC
  /// **date** granularity, that hour is enough to push "today" onto
  /// yesterday and get an ordinary same-day payment rejected. Callers should
  /// hand a picked date over at midday local for the same reason; noon is the
  /// same calendar day in UTC for any offset within ±12h.
  static String _isoTimestamp(DateTime value) =>
      value.toUtc().toIso8601String();

  /// GET /orders/{id}/payments → {total, results}. Newest first (the backend
  /// orders by paid_at desc, then created_at desc to break the ties that
  /// backdating makes common). Returns just the rows.
  Future<List<Payment>> list(String orderId) async {
    final response = await _dio.get('/orders/$orderId/payments');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST a payment.
  ///
  /// [amount] must not exceed the outstanding balance — the backend returns
  /// 400 with the balance named in the detail, which the form surfaces
  /// verbatim. Overpayment is rejected at entry on purpose: it's nearly
  /// always a typo, and a legitimate excess is a [tipAmount].
  ///
  /// [amount] may be 0 when [tipAmount] is positive — that's a standalone
  /// tip. Both being zero is refused by the backend.
  ///
  /// [paidAt] null means "now"; pass a value only when the user actually
  /// picked a date, so an untouched field never fights the backend's floor.
  Future<Payment> record(
    String orderId, {
    required double amount,
    double tipAmount = 0,
    required String method,
    String? notes,
    DateTime? paidAt,
  }) async {
    final response = await _dio.post('/orders/$orderId/payments', data: {
      'amount': amount,
      if (tipAmount > 0) 'tip_amount': tipAmount,
      'method': method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (paidAt != null) 'paid_at': _isoTimestamp(paidAt),
    });
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST a refund — money back out, stored as a positive amount with
  /// `kind: 'refund'` and subtracted at read time.
  ///
  /// [reason] is required and must be non-blank; "why did money go back out"
  /// is the one question this record exists to answer, and the backend
  /// rejects a blank string as hard as a missing field.
  ///
  /// Allowed on cancelled orders, unlike payments — refunding a deposit on a
  /// cancellation is the most common refund a shop issues. Refusing more than
  /// was ever received is a 400 naming the refundable figure.
  Future<Payment> refund(
    String orderId, {
    required double amount,
    required String method,
    required String reason,
    String? notes,
    DateTime? paidAt,
  }) async {
    final response = await _dio.post('/orders/$orderId/refunds', data: {
      'amount': amount,
      'method': method,
      'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (paidAt != null) 'paid_at': _isoTimestamp(paidAt),
    });
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE a payment or refund. **Hard delete** — this was `voidPayment`,
  /// and the rename is not cosmetic: the row is gone afterwards, not flagged.
  ///
  /// The backend does not refuse this even when a receipt was generated, so
  /// the warning is the client's job. Deleting a payment a refund was taken
  /// against can leave the order's `amountPaid` negative; that's recorded
  /// honestly rather than clamped, so callers must not assume it's positive.
  Future<void> deletePayment(String orderId, String paymentId) async {
    await _dio.delete('/orders/$orderId/payments/$paymentId');
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});
