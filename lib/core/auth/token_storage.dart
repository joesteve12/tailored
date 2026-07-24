import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over flutter_secure_storage so nothing else in the app
/// touches the storage API directly — keeps any future storage-strategy
/// change to one file.
///
/// Caches the logged-in user's JSON alongside the token (see
/// [writeCachedUserJson]). This is what lets [AuthStateNotifier] (in
/// auth_state.dart) restore "you're still logged in" on cold start without
/// an extra network round trip — the backend has no GET /auth/me endpoint
/// today, so this local cache is standing in for that. If you add /auth/me
/// later, you could simplify this back down to just the token and re-fetch
/// the user on start instead — either is fine, this just avoids a backend
/// change being a prerequisite for Phase 1.
class TokenStorage {
  TokenStorage()
      : _storage = const FlutterSecureStorage(
          // encryptedSharedPreferences avoids a known flutter_secure_storage
          // issue on Android where a key written before a device/app
          // backup-restore can throw a PlatformException on first read
          // afterwards.
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_access_token';
  static const _userKey = 'auth_cached_user';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readCachedUserJson() => _storage.read(key: _userKey);

  Future<void> writeCachedUserJson(String json) =>
      _storage.write(key: _userKey, value: json);

  /// Clears both the token and the cached user — call this on logout AND
  /// on a 401 from the backend (session is over either way).
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
