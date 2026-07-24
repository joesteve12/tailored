import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payment_repository.dart';
import '../models/payment.dart';

/// The payment history for one order. A `FutureProvider.family` keyed by
/// order id, matching the read-only-list convention used for employee
/// workload: the section reads it, and record/void invalidate it (alongside
/// refreshing the order detail, whose `amount_paid` / `payment_status` the
/// backend recomputed). Auto-disposes when the order screen is closed.
final paymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, orderId) async {
  return ref.read(paymentRepositoryProvider).list(orderId);
});
