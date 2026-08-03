import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payment_repository.dart';
import '../models/payment.dart';

/// The order's money timeline — payments, refunds and tips together, newest
/// first. A `FutureProvider.family` keyed by order id, matching the
/// read-only-list convention used for employee workload: the Activity section
/// reads it, and every money mutation invalidates it (alongside refreshing the
/// order detail, whose `amountPaid` / `paymentStatus` the backend recomputed).
/// Auto-disposes when the order screen is closed.
///
/// "record/void" used to describe the writers. There is no void any more —
/// deletion is a hard delete, and the record of what was printed lives in
/// `orderDocumentsProvider` instead. The list this returns contains only rows
/// that currently exist; nothing here needs filtering before display.
///
/// Also read for the date floor on the money sheets: the latest `paidAt` here
/// is the earliest date a new row may carry.
final paymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, orderId) async {
  return ref.read(paymentRepositoryProvider).list(orderId);
});
