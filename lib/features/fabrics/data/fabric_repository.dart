import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/fabric_inventory.dart';

/// Read side of the fabric inventory — the `/fabrics` endpoints added in the
/// backend restructure. The shop's fabrics live in their own table now (a
/// garment can be cut from several), so this is a flat, cross-order view rather
/// than something derived from the order list.
class FabricRepository {
  FabricRepository(this._dio);

  final Dio _dio;

  /// GET /fabrics?search=&page=&page_size= → {fabrics, total}. `search` matches
  /// serial, fabric details, or recipient name (partial, case-insensitive)
  /// server-side; an empty/blank query returns everything, newest first.
  ///
  /// Returns the page of rows plus the unfiltered `total` the server reports,
  /// so the caller can tell when it has reached the end (loaded == total).
  ///
  /// UNCONFIRMED ASSUMPTION: that `/fabrics` honours `page` / `page_size` the
  /// same way `/clients` does. The endpoint already returns `total` (implying a
  /// paged view), and mirroring the clients contract is the natural fit — but it
  /// wasn't verified against the handler. If the backend ignores these params it
  /// degrades safely: page 1 returns everything, `total` equals the row count,
  /// `hasMore` is false, and the list behaves as it did before (no paging, no
  /// breakage) — the perf win just doesn't kick in until the backend paginates.
  Future<({List<FabricInventoryItem> items, int total})> list({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/fabrics', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': page,
      'page_size': pageSize,
    });
    final data = response.data as Map<String, dynamic>;
    final items = (data['fabrics'] as List)
        .map((e) => FabricInventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num?)?.toInt() ?? items.length;
    return (items: items, total: total);
  }

  /// GET /fabrics/{serial} → one fabric plus the order and recipient it's tied
  /// to. 404s if no fabric carries that serial (surfaced to the caller).
  Future<FabricInventoryDetail> getBySerial(String serial) async {
    final response = await _dio.get('/fabrics/$serial');
    return FabricInventoryDetail.fromJson(
        response.data as Map<String, dynamic>);
  }
}

final fabricRepositoryProvider = Provider<FabricRepository>((ref) {
  return FabricRepository(ref.watch(dioProvider));
});
