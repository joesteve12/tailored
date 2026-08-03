import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/document_issue.dart';

/// Fetches generated order documents as raw bytes for the OS share sheet —
/// the same hand-off the per-item work order uses, just at the order level.
///
/// `format` is 'pdf' (default) or 'image' (PNG). The endpoints stream the
/// file back with an attachment header; only the bytes are needed.
///
/// **Receipts are per payment, not per order.** `GET /orders/{id}/receipt`
/// no longer exists — it returns 410 with the replacement path in the body.
/// An order-level receipt couldn't answer the only question a receipt is for
/// (what did this client hand over, when, and what was left), because it was
/// drawn from live order totals: taking a second payment silently rewrote the
/// first receipt.
class DocumentRepository {
  DocumentRepository(this._dio);

  final Dio _dio;

  Future<Uint8List> _bytes(String path, String format) async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// GET /orders/{id}/invoice.
  ///
  /// The backend refuses this with a 400 when the order's `paymentStatus` is
  /// `paid` **or `overpaid`** — invoicing a client who is owed money back is
  /// exactly the mistake the second case was added to prevent. Callers should
  /// hide the action in both states rather than surfacing the rejection.
  Future<Uint8List> fetchInvoice(String orderId, {String format = 'pdf'}) =>
      _bytes('/orders/$orderId/invoice', format);

  /// GET /orders/{id}/payments/{paymentId}/receipt.
  ///
  /// Works for refunds and standalone tips as well as payments — every row in
  /// the money timeline has a document. The PDF renders from that row's
  /// frozen snapshot, so reprinting a three-month-old receipt shows what the
  /// client's paper shows even after the order total has moved underneath it.
  Future<Uint8List> fetchPaymentReceipt(
    String orderId,
    String paymentId, {
    String format = 'pdf',
  }) =>
      _bytes('/orders/$orderId/payments/$paymentId/receipt', format);

  /// GET /orders/{id}/documents → {total, results}. Newest first.
  ///
  /// The log of what was actually generated for this order. Rows survive the
  /// deletion of the payment they describe — [DocumentIssue.paymentId] goes
  /// null while the denormalised amount, receipt number and balance stay — so
  /// this is the honest source for "has a receipt already gone out for this
  /// payment", which is what the delete-payment warning needs to know.
  Future<List<DocumentIssue>> listDocuments(String orderId) async {
    final response = await _dio.get('/orders/$orderId/documents');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => DocumentIssue.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(dioProvider));
});
