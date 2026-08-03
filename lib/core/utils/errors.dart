import 'package:dio/dio.dart';

/// Maps a raw error into something a user should actually see.
///
/// Uses DioException's typed ``type``/``response`` fields rather than sniffing
/// ``toString()`` output (which varies by Dio version and isn't a stable
/// contract to match strings against).
///
/// Used by both the read-side [AsyncErrorView] and the write-side
/// [showErrorSnackbar] — both surfaces now render the same phrasing for the
/// same underlying failure, and neither leaks Dio internals at the user.
String describeError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "The request timed out. Check your connection and try again.";
      case DioExceptionType.connectionError:
        return "Couldn't reach the server. Check your connection and try again.";
      case DioExceptionType.badCertificate:
        return "Couldn't verify the server's connection.";
      case DioExceptionType.cancel:
        return "The request was cancelled.";
      case DioExceptionType.badResponse:
        if (status == 404) return "That couldn't be found. It may have been deleted.";
        if (status == 422) return "The server rejected that request.";
        if (status == 401 || status == 403) return "You're not signed in to do that.";
        if (status != null && status >= 500) {
          return "The server had a problem. Try again in a moment.";
        }
        return "Something went wrong (error $status).";
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return "Something went wrong. Try again.";
    }
  }
  return "Something went wrong. Try again.";
}


/// The backend's own `detail` string, when it sent one.
///
/// Deliberately NOT wired into [describeError]: most of the app's 4xx
/// responses carry phrasing meant for a developer, and piping all of them
/// straight to users would leak internals. Callers that know their endpoint
/// returns owner-facing messages opt in — see
/// `features/measurements/utils/dictionary_errors.dart`, where "A field with
/// key 'chest' already exists" is exactly what should be shown and
/// "Something went wrong (error 400)" is useless.
///
/// Handles both FastAPI shapes: `{"detail": "..."}` from an HTTPException, and
/// `{"detail": [{"loc": [...], "msg": "..."}]}` from a pydantic 422.
String? serverDetail(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;

  final detail = data['detail'];
  if (detail is String) {
    final trimmed = detail.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map && first['msg'] is String) {
      // Pydantic prefixes validator failures with "Value error, " — an artifact
      // of its internals, not something a tailor needs to read.
      final msg = (first['msg'] as String).replaceFirst('Value error, ', '').trim();
      return msg.isEmpty ? null : msg;
    }
  }
  return null;
}
