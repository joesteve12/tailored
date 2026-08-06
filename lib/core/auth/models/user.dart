import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Confirmed against the real /auth/register response schema (201) you
/// shared. Two nullability calls worth knowing about, not just assuming:
///   - `phone`: nullable. Your google_auth() service function never sets
///     phone when creating a Google-signed-up user, so it'll be null in the
///     DB (and therefore in this JSON) for anyone who signs up via Google
///     instead of the register form. Making this non-nullable would crash
///     the parser the first time a Google user logs in.
///   - `businessName`: NOT nullable here, even though it's debatable.
///     google_auth() sets it to `""` (empty string) rather than null for
///     Google sign-ups, so the field is always present, just sometimes
///     empty. Treating it as required String matches that reality; just
///     don't assume a non-empty value when displaying it.
///   - `logoUrl`: nullable — nothing sets this at signup time in either
///     flow, only relevant once a logo-upload feature exists.
/// id is a UUID, but FastAPI/Pydantic serializes it as a plain string in
/// JSON, so `String` is correct here, not anything UUID-specific.
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'business_name') required String businessName,
    // Owner/contact name and address are collected at email/password signup
    // but are nullable in the response: Google signups create the account
    // before the profile is filled in, so both come back null for those users.
    @JsonKey(name: 'owner_name') String? ownerName,
    @JsonKey(name: 'business_address') String? businessAddress,
    // Clothing specializations. Always present (defaults to [] server-side for
    // Google signups and older accounts), so a non-nullable list with a []
    // fallback matches reality without risking a null-parse crash.
    @JsonKey(name: 'specializations') @Default(<String>[]) List<String> specializations,
    String? phone,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'auth_provider') String? authProvider,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

extension UserProfileCompletion on User {
  /// True once the business has filled in everything registration now collects.
  /// Google signups (which create the account with an empty business name and
  /// no owner/address) and accounts created before these fields existed come
  /// back incomplete; the router sends them through the "complete your profile"
  /// screen until this returns true.
  bool get isProfileComplete =>
      businessName.trim().isNotEmpty &&
      (ownerName?.trim().isNotEmpty ?? false) &&
      (businessAddress?.trim().isNotEmpty ?? false) &&
      specializations.isNotEmpty;
}
