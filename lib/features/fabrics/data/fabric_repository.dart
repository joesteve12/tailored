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

  /// GET /fabrics?search= → {fabrics, total}. `search` matches serial, fabric
  /// details, or recipient name (partial, case-insensitive) server-side; an
  /// empty/blank query returns everything, newest first. Returns just the rows.
  Future<List<FabricInventoryItem>> list({String? search}) async {
    final response = await _dio.get('/fabrics', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final data = response.data as Map<String, dynamic>;
    return (data['fabrics'] as List)
        .map((e) => FabricInventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
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
