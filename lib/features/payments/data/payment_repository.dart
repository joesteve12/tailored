import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/payment.dart';

/// Payments live under `/orders/{id}/payments`. There's no update — a
/// recorded payment is either kept or voided (deleted) — and the order's
/// `amount_paid` / `payment_status` are recomputed by the backend on every
/// record and void, so callers refetch the order afterwards rather than
/// adjusting figures locally.
class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// GET /orders/{id}/payments → {total, results}. Newest first (the backend
  /// orders by paid_at desc). Returns just the rows.
  Future<List<Payment>> list(String orderId) async {
    final response = await _dio.get('/orders/$orderId/payments');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST a payment. `amount` must be > 0 and not exceed the outstanding
  /// balance — the backend returns 400 with the outstanding balance in the
  /// detail if it would overpay, which the form surfaces.
  Future<Payment> record(
    String orderId, {
    required double amount,
    required String method,
    String? notes,
  }) async {
    final response = await _dio.post('/orders/$orderId/payments', data: {
      'amount': amount,
      'method': method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE a payment (void). The backend recalculates the order's paid total
  /// and status from the remaining payments.
  Future<void> voidPayment(String orderId, String paymentId) async {
    await _dio.delete('/orders/$orderId/payments/$paymentId');
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});
