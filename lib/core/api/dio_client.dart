import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../auth/token_storage.dart';
import 'auth_interceptor.dart';

class ApiConfig {
  // The API base URL, resolved at COMPILE time via --dart-define.
  //
  // Default (used when no --dart-define is passed): the production Railway
  // URL below. This means a release build (`flutter build apk`, App Store
  // upload, etc.) with no extra flags ships pointing at production — which
  // is what you want. Forgetting the flag during local dev, by contrast,
  // fails loudly on the first request, so the mistake is immediately visible.
  //
  // TODO: paste your Railway HTTPS URL below, including the `/api/v1` suffix,
  // e.g. 'https://tailored-be-production.up.railway.app/api/v1'.
  //
  // For local dev against a backend running on your machine, override at
  // run time:
  //
  //   Android emulator (10.0.2.2 is the emulator's alias for the host's
  //   localhost):
  //     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1
  //
  //   iOS simulator (shares the host network stack):
  //     flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8001/api/v1
  //
  //   Physical device on your LAN (replace with your machine's LAN IP):
  //     flutter run --dart-define=API_BASE_URL=http://192.168.x.y:8001/api/v1
  //
  // Tip: put the flag in your IDE run configuration (VS Code launch.json's
  // `toolArgs` or Android Studio's "Additional run args") so you don't
  // retype it every time.
  //
  // NOTE: Android 9+ blocks cleartext HTTP on release builds by default, so
  // production MUST be https://. LAN/emulator http:// URLs above are fine
  // only for debug builds — release builds require HTTPS.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://<YOUR-RAILWAY-DOMAIN>/api/v1',
  );
}

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      getToken: tokenStorage.readToken,
      // Goes through the same logout() the user-initiated button uses,
      // not a hand-rolled "clear storage + invalidate" duplicate — that
      // duplicate used to only clear the token, never the per-tenant
      // record caches (client/guest/measurement), which is exactly the
      // gap that let a stale session's cached data leak into the next
      // login if it ever happened via a 401 instead of the logout button.
      onUnauthorized: () => ref.read(authStateProvider.notifier).logout(),
    ),
  );

  return dio;
});
