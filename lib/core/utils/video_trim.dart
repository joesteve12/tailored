import 'dart:io';

import 'package:flutter/services.dart';

/// Max length of a scoped-video reference clip (Phase 8 / proposal §4). The
/// trim screen enforces this on the device; the backend's 20MB size cap is the
/// authoritative server-side limit.
const Duration kMaxVideoDuration = Duration(seconds: 10);

const MethodChannel _channel = MethodChannel('tailored/video_trim');

/// Losslessly trim [src] to the [start, end] window using native code
/// (Android MediaMuxer — no ffmpeg) and return the trimmed file.
///
/// Throws if the trim fails, or if the running platform has no native
/// implementation (e.g. web) — callers surface that as a normal upload error.
Future<File> trimVideo(
  File src, {
  required Duration start,
  required Duration end,
}) async {
  final path = await _channel.invokeMethod<String>('trim', {
    'srcPath': src.path,
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
  });
  if (path == null || path.isEmpty) {
    throw Exception('Video trim returned no file');
  }
  return File(path);
}
