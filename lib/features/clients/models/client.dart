import 'package:freezed_annotation/freezed_annotation.dart';

part 'client.freezed.dart';
part 'client.g.dart';

/// Mirrors the confirmed ClientResponse schema. `name` and `phone` are the
/// only required fields on the backend (matches ClientCreate); everything
/// else (email, address, notes, photo_url) is nullable.
///
/// `photoUrl` is only ever set via POST
/// /uploads/clients/{client_id}/photo — there's no way to set it through
/// create/update directly with a real file, even though ClientUpdate's
/// schema technically accepts a photo_url string field.
@freezed
class Client with _$Client {
  const factory Client({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Client;

  factory Client.fromJson(Map<String, dynamic> json) =>
      _$ClientFromJson(json);
}
