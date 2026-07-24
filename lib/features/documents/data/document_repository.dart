import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';

/// Fetches generated order documents (invoice, receipt) as raw bytes for the
/// OS share sheet — the same hand-off the per-item work order uses (Phase 7),
/// just at the order level. The work order itself stays on the orders repo
/// since it's keyed by item; these two are order-wide.
///
/// `format` is 'pdf' (default) or 'image' (PNG). The endpoints stream the
/// file back with an attachment header; only the bytes are needed.
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

  Future<Uint8List> fetchInvoice(String orderId, {String format = 'pdf'}) =>
      _bytes('/orders/$orderId/invoice', format);

  Future<Uint8List> fetchReceipt(String orderId, {String format = 'pdf'}) =>
      _bytes('/orders/$orderId/receipt', format);
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(dioProvider));
});
