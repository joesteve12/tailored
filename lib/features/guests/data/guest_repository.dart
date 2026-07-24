import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../models/guest_profile.dart';

class GuestRepository {
  GuestRepository(this._dio);

  final Dio _dio;

  /// GET /clients/{client_id}/guests returns a plain JSON array — no
  /// total/page/page_size wrapper like ClientListResponse. No pagination
  /// on this endpoint either, which matches reality: a client has a
  /// handful of guests (family members), not hundreds.
  Future<List<GuestProfile>> list(String clientId) async {
    final response = await _dio.get('/clients/$clientId/guests');
    return (response.data as List)
        .map((e) => GuestProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GuestProfile> getById(String clientId, String guestId) async {
    final response = await _dio.get('/clients/$clientId/guests/$guestId');
    return GuestProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GuestProfile> create(
    String clientId, {
    required String name,
    String? relation,
  }) async {
    final response = await _dio.post('/clients/$clientId/guests', data: {
      'name': name,
      if (relation != null && relation.isNotEmpty) 'relation': relation,
    });
    return GuestProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Same unconfirmed partial-update assumption as ClientRepository.update
  /// — only fields actually passed are included in the body, on the
  /// (untested) theory that the backend leaves omitted fields alone.
  /// Same test applies here too: edit just `relation` on a guest that
  /// already has a name, and check the name survives.
  Future<GuestProfile> update(
    String clientId,
    String guestId, {
    String? name,
    String? relation,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (relation != null) 'relation': relation,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
    final response =
        await _dio.put('/clients/$clientId/guests/$guestId', data: data);
    return GuestProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String clientId, String guestId) async {
    await _dio.delete('/clients/$clientId/guests/$guestId');
  }

  /// POSTs to /uploads/guests/{guest_id}/photo. Written defensively
  /// unlike ClientRepository.uploadPhoto: that method assumes a
  /// map-shaped response (`response.data['url']`), but its own docstring
  /// says the OpenAPI schema for this response is a bare string — those
  /// two things contradict each other, and the mismatch was flagged but
  /// left unfixed there (out of scope at the time). Handling both shapes
  /// here means this one works correctly regardless of which the backend
  /// actually returns, without needing to track down which docstring was
  /// right.
  Future<String> uploadPhoto(String guestId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '/uploads/guests/$guestId/photo',
      data: formData,
    );
    final data = response.data;
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      final url = data['url'] ?? data['photo_url'];
      if (url is String) return url;
    }
    throw FormatException('Unexpected upload response shape: $data');
  }
}

final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  return GuestRepository(ref.watch(dioProvider));
});
