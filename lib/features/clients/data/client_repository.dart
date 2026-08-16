import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/client.dart';
import '../models/client_list_response.dart';
import '../state/client_stats_provider.dart';

class ClientRepository {
  ClientRepository(this._dio);

  final Dio _dio;

  /// dioProvider's baseUrl already ends in /api/v1 — paths here are
  /// relative to that, matching auth_repository.dart's convention.
  Future<ClientListResponse> list({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/clients', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'page_size': pageSize,
    });
    return ClientListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Client> getById(String id) async {
    final response = await _dio.get('/clients/$id');
    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  /// Revenue / outstanding / active-order / guest counts for the client
  /// detail stats strip. Backs [clientStatsProvider].
  Future<ClientStats> stats(String id) async {
    final response = await _dio.get('/clients/$id/stats');
    return ClientStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Client> create({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final response = await _dio.post('/clients', data: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  /// Only includes fields that were actually passed in — omits unset
  /// fields from the JSON body entirely rather than sending them as null.
  ///
  /// UNCONFIRMED ASSUMPTION: that the backend only touches fields present
  /// in the body and leaves the rest alone. ClientUpdate's schema makes
  /// every field optional, which strongly suggests this, but it was never
  /// verified against the actual handler. Test this the first time you
  /// edit just one field on a client with other fields already filled in
  /// — if those other fields come back empty afterward, the backend is
  /// nulling everything not sent, and this needs to switch to always
  /// sending the full object instead.
  Future<Client> update(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };

    final response = await _dio.put('/clients/$id', data: data);
    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/clients/$id');
  }

  /// POSTs to /uploads/clients/{id}/photo as multipart/form-data and
  /// returns the uploaded photo's URL.
  ///
  /// The endpoint's response schema is a bare JSON string ("string" in the
  /// OpenAPI spec), not a wrapped object — Dio's default json
  /// ResponseType decodes that straight to a Dart String, so
  /// `response.data as String` is correct here, not `response.data['url']`
  /// or similar.
  ///
  /// UNCONFIRMED ASSUMPTION: that this call also persists photo_url onto
  /// the client record server-side, since the path includes the client_id
  /// and has everything it needs to do so. Callers (see
  /// ClientDetailNotifier) refetch the client after calling this instead
  /// of trusting that assumption blindly — if photo_url comes back null on
  /// refetch, the assumption is wrong and this endpoint only uploads +
  /// returns a URL, requiring a follow-up update() call with that URL to
  /// actually attach it to the client.
  Future<String> uploadPhoto(String clientId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/uploads/clients/$clientId/photo',
      data: formData,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(dioProvider));
});
