import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_repository.dart';
import '../models/document_issue.dart';

/// The log of documents actually generated for one order, keyed by order id.
/// Auto-disposes with the order screen, matching `paymentsProvider`.
///
/// This exists for one job: the delete-payment dialog needs to know whether a
/// receipt has already gone out for the row being deleted, so it can name the
/// receipt number and date instead of hedging. "A receipt (RCP-0007) was
/// generated on 12 Jul" is a reason to stop and think; "a receipt may have
/// been generated" is noise that gets clicked through.
///
/// Invalidate after generating a document so a freshly-shared receipt is
/// visible to that dialog immediately.
final orderDocumentsProvider =
    FutureProvider.family<List<DocumentIssue>, String>((ref, orderId) async {
  return ref.read(documentRepositoryProvider).listDocuments(orderId);
});

/// Finds the receipt already issued for [paymentId], or null.
///
/// Matches on `paymentId` and not on amount, because amounts repeat — two
/// ₦50,000 payments on the same order are ordinary — and a false positive
/// here would show the wrong receipt number in a destructive-action dialog.
///
/// Returns null once the payment has been deleted: the audit row survives
/// with `paymentId` null by design. That's correct for this use, since a
/// deleted payment can't be deleted again.
DocumentIssue? receiptForPayment(
  List<DocumentIssue> documents,
  String paymentId,
) {
  for (final doc in documents) {
    if (doc.isReceipt && doc.paymentId == paymentId) return doc;
  }
  return null;
}
