import 'package:dio/dio.dart';

typedef TokenGetter = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

/// Attaches the stored JWT as a Bearer token to every outgoing request, and
/// reacts to a 401 by clearing the session.
///
/// Important: your backend currently issues a single access token with no
/// refresh token — confirmed from the google_auth() service function, which
/// only calls create_access_token() once and returns that. So a 401 here
/// always means "the session is over, log in again." There is no
/// silent-refresh step to attempt first, because there's nothing to refresh
/// with. If you add refresh tokens on the backend later, this is the file
/// to come back to — it would grow a "try refreshing once before giving up"
/// step in onError.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken, required this.onUnauthorized});

  final TokenGetter getToken;
  final UnauthorizedHandler onUnauthorized;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await onUnauthorized();
    }
    handler.next(err);
  }
}
