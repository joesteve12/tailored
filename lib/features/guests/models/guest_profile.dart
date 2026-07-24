import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_profile.freezed.dart';
part 'guest_profile.g.dart';

/// Mirrors GuestProfileResponse. `name` is the only required field
/// (matches GuestProfileCreate); `relation` and `photoUrl` are both
/// nullable, same pattern as Client's optional fields.
@freezed
class GuestProfile with _$GuestProfile {
  const factory GuestProfile({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    required String name,
    String? relation,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _GuestProfile;

  factory GuestProfile.fromJson(Map<String, dynamic> json) =>
      _$GuestProfileFromJson(json);
}
