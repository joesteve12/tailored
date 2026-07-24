import 'package:flutter/material.dart';

import '../utils/errors.dart';

/// Drop-in replacement for `error: (err, _) => Text('Error: $err')`.
///
/// That pattern is what made every error in this app a dead end: no retry
/// button, and on screens where a `RefreshIndicator` existed it only
/// wrapped the `data:` branch, so once a provider landed in `AsyncError`
/// (a 15s timeout, a 404, a 422, anything) there was no way left in the UI
/// to fire the request again. None of the providers are `autoDispose`
/// either, so navigating away and back doesn't help — the cached error
/// just sits there until the app is restarted.
///
/// [onRetry] should call the relevant notifier's `refresh()` (every
/// notifier in this codebase already has one). This widget owns its own
/// "is a retry in flight" state so the button disables itself and shows a
/// spinner instead of letting someone fire five retries in a row.
class AsyncErrorView extends StatefulWidget {
  const AsyncErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final Future<void> Function() onRetry;

  /// Use for error states embedded inside another scrollable (e.g. a
  /// section inside ClientDetailScreen) where a full-height Center with
  /// big padding would look wrong next to surrounding content.
  final bool compact;

  @override
  State<AsyncErrorView> createState() => _AsyncErrorViewState();
}

class _AsyncErrorViewState extends State<AsyncErrorView> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: widget.compact ? 28 : 36,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 8),
        Text(
          describeError(widget.error),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _retrying ? null : _handleRetry,
          icon: _retrying
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text('Try again'),
        ),
      ],
    );

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: content,
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: content),
    );
  }
}
