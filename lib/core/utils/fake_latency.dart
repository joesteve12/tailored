import 'package:flutter/foundation.dart';

/// Debug-only artificial latency, for eyeballing loading states (skeleton
/// loaders) without a slow network.
///
/// Flip [kFakeLatency] to `true` and every provider that `await`s
/// [fakeLatency] will stall for a beat before returning, so the shimmer is
/// visible on first load and on every pull-to-refresh. It is additionally
/// gated on [kDebugMode], so it can NEVER slow a profile or release build,
/// even if this is accidentally left `true`.
///
/// Reusable across the whole app: drop `await fakeLatency();` at the top of any
/// `FutureProvider` body whose loading state you want to preview.
const bool kFakeLatency = false;

const Duration _kFakeLatencyDuration = Duration(seconds: 30);

/// Waits [duration] (default 2s) only when both [kDebugMode] and [kFakeLatency]
/// are true; otherwise returns immediately.
Future<void> fakeLatency([Duration? duration]) async {
  if (kDebugMode && kFakeLatency) {
    await Future<void>.delayed(duration ?? _kFakeLatencyDuration);
  }
}
