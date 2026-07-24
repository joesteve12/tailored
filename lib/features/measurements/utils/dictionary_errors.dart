import 'package:dio/dio.dart';

import '../../../core/utils/errors.dart';

/// Error text for the measurement-dictionary screens (fields + templates).
///
/// The generic [describeError] flattens every 400 into "Something went wrong
/// (error 400)". That's the right default across the app, but it's exactly
/// wrong here, because the three most common failures on these screens are all
/// 400s whose `detail` is the entire answer:
///
///   * "A field with key 'chest' already exists"
///   * "This field is used by 12 captured measurements. Archive it instead."
///   * "Template is in use by existing measurements. Archive it instead."
///   * "Can't change the value type of a field that already has captured
///     measurements."
///
/// Every one of those is a message the shop owner can act on, written for them.
/// So this describer prefers the server's own words for the statuses where the
/// backend is known to send owner-facing text, and falls back to [describeError]
/// for everything else (timeouts, 401s, 500s), which stay generic on purpose.
String describeDictionaryError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 400 || status == 409 || status == 422) {
      final detail = serverDetail(error);
      if (detail != null) return detail;
    }
  }
  return describeError(error);
}
