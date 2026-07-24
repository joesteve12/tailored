import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/errors.dart';

/// User feedback shown as a top-positioned banner ("snackbar" in the app's
/// vocabulary, even though it's technically an Overlay entry and not a
/// Material [SnackBar]).
///
/// Why not Material's SnackBar: it's designed for the bottom of the screen
/// and getting it to render at the top requires a MediaQuery-based margin
/// hack that fights with the keyboard and the app bar. A small overlay
/// widget gives us reliable top placement, survives navigation (mounted on
/// the root [Overlay]), and slides in/out with a proper animation.
///
/// The public API is deliberately unchanged from the prior bottom-SnackBar
/// implementation so every call site across the app carries over without
/// edits: [showErrorSnackbar] pipes through [describeError] to avoid ever
/// leaking Dio internals, and [showSuccessSnackbar] handles the confirmation
/// side.

/// Show an error banner at the top of the screen.
///
/// [action] is an optional short lead ("Delete failed", "Save failed"),
/// combined with the human-friendly [describeError] output. Without
/// [action] the description alone is shown.
void showErrorSnackbar(
  BuildContext context,
  Object err, {
  String? action,
}) {
  final description = describeError(err);
  final message = action != null ? '$action — $description' : description;
  _TopFeedbackOverlay.show(
    context,
    message: message,
    kind: _FeedbackKind.error,
  );
}

/// Show a success banner at the top of the screen.
void showSuccessSnackbar(BuildContext context, String message) {
  _TopFeedbackOverlay.show(
    context,
    message: message,
    kind: _FeedbackKind.success,
  );
}

/// Show an error banner with a plain string message. Use for client-side
/// validation feedback ("Add at least one item", "Required: chest, waist")
/// where there's no exception to describe — the exception-taking
/// [showErrorSnackbar] would be forced to wrap the string in a fake error.
void showErrorMessage(BuildContext context, String message) {
  _TopFeedbackOverlay.show(
    context,
    message: message,
    kind: _FeedbackKind.error,
  );
}

enum _FeedbackKind { error, success }

/// Static coordinator for the currently-visible banner. Only one is on
/// screen at a time — a new call dismisses the previous immediately rather
/// than queuing, because the more recent event is what the user wants to
/// see (e.g. a save that fails right after an upload that succeeded — the
/// failure is the actionable one).
class _TopFeedbackOverlay {
  static OverlayEntry? _current;
  static _TopFeedbackState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    required _FeedbackKind kind,
    Duration duration = const Duration(seconds: 3),
  }) {
    // rootOverlay: true so the banner survives Navigator.push/pop that
    // happens right after the call site (create → pop back to list, etc.),
    // rather than being torn down with the just-popped route's overlay.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Dismiss any currently-visible banner instantly. Using the state's
    // dismiss-with-animation would double-buffer briefly; the new one
    // sliding in is enough visual signal.
    _current?.remove();
    _current = null;
    _currentState = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopFeedback(
        message: message,
        kind: kind,
        duration: duration,
        onRegisterState: (state) {
          if (_current == entry) _currentState = state;
        },
        onDismissed: () {
          if (_current == entry) {
            _current = null;
            _currentState = null;
          }
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _TopFeedback extends StatefulWidget {
  const _TopFeedback({
    required this.message,
    required this.kind,
    required this.duration,
    required this.onRegisterState,
    required this.onDismissed,
  });

  final String message;
  final _FeedbackKind kind;
  final Duration duration;
  final ValueChanged<_TopFeedbackState> onRegisterState;
  final VoidCallback onDismissed;

  @override
  State<_TopFeedback> createState() => _TopFeedbackState();
}

class _TopFeedbackState extends State<_TopFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _autoDismiss = Timer(widget.duration, _dismiss);
    widget.onRegisterState(this);
  }

  Future<void> _dismiss() async {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    if (!mounted) return;
    // Reverse-animate before the overlay entry is removed so users see the
    // banner slide back up rather than blink away.
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (widget.kind) {
      _FeedbackKind.error => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.error_outline,
        ),
      _FeedbackKind.success => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.check_circle_outline,
        ),
    };

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _dismiss,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(icon, color: fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: fg),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
