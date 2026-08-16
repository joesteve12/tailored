import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/task_summary.dart';
import '../state/task_detail_notifier.dart';
import '../tasks_paths.dart';
import '../utils/task_labels.dart';
import 'mini_timeline.dart';

/// One card on the Tasks tab. The list is MIXED; this widget branches on
/// `kind` and dispatches — one wire shape, two card layouts. Splitting to
/// two Dart types would force a sealed wrapper on the list side for no
/// gain.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onDismissed});

  final TaskSummary task;

  /// Called with the task id once a to-do is swiped to complete/reopen, so
  /// the list can drop the row on the spot. Ignored for production cards —
  /// they don't swipe.
  final ValueChanged<String>? onDismissed;

  @override
  Widget build(BuildContext context) {
    return task.isGeneral
        ? _GeneralTaskCard(task: task, onDismissed: onDismissed)
        : _ProductionTaskCard(task: task);
  }
}

/// Coloured pill: On Time (incomplete, not delayed) / Delayed. Completed
/// cards show neither — the completed filter is the history view, not a
/// checklist to badge.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (task.isComplete) return const SizedBox.shrink();
    final delayed = task.delayed;
    // Match the app's status-chip idiom (see order_card): the semantic colour
    // at a light alpha for the fill, the full colour for the label. Delayed
    // rides the warm `error` brick red (same as a cancelled order); On Time
    // stays a calm neutral so only the alerting state carries colour.
    final color = delayed ? scheme.error : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        delayed ? 'Delayed' : 'On Time',
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProductionTaskCard extends StatelessWidget {
  const _ProductionTaskCard({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expected = task.expectedCompletionDate;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appTokens.radiusXl),
        //side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push(taskDetailPath(task.taskId)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(url: task.thumbnailUrl, code: task.codeLabel),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.garmentType ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StatusBadge(task: task),
                          ],
                        ),
                        if ((task.recipientName ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              task.recipientName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (expected != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.event,
                                    size: 14, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Expected ${taskDueDateLabel(expected)}',
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (task.stages.isNotEmpty) ...[
                const SizedBox(height: 12),
                MiniTimeline(stages: task.stages),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.code});

  final String? url;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The code label ("TQ372-1") overlays the image in the reference
    // design; it's the item's addressable name, not decoration.
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            image: (url != null && url!.isNotEmpty)
                ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
                : null,
          ),
          child: (url == null || url!.isEmpty)
              ? Icon(Icons.checkroom_outlined,
                  color: scheme.onSurfaceVariant, size: 28)
              : null,
        ),
        if ((code ?? '').isNotEmpty)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                code!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// A to-do card. Completion is a SWIPE (left, `endToStart`): dragging the
/// row reveals a primary "Complete" panel; a quiet "Swipe to complete" hint
/// on the trailing edge makes the gesture discoverable. Tapping the row
/// still opens the detail screen. There's no status badge — an overdue
/// to-do says so by turning its due line red, the only status it has.
class _GeneralTaskCard extends ConsumerWidget {
  const _GeneralTaskCard({required this.task, this.onDismissed});

  final TaskSummary task;
  final ValueChanged<String>? onDismissed;

  /// Toggle complete/reopen. Returns whether it succeeded: on success the
  /// swipe is allowed to dismiss and [onDismissed] drops the row; on failure
  /// we SnackBar and return false so the row springs back untouched.
  /// taskDetailProvider adopts the server response and fans out the
  /// invalidations that refetch this list.
  Future<bool> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(taskDetailProvider(task.taskId).notifier);
      if (task.isComplete) {
        await notifier.reopen();
      } else {
        await notifier.complete();
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update to-do: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.appTokens.mutedForeground;
    final radius = BorderRadius.circular(context.appTokens.radiusXl);
    final dueLocal = task.dueAt?.toLocal();
    final done = task.isComplete;
    final overdue = task.delayed && !done;
    final linkText = [
      if ((task.orderNumber ?? '').isNotEmpty) task.orderNumber!,
      if ((task.recipientName ?? '').isNotEmpty) task.recipientName!,
    ].join(' · ');
    final hasMeta = dueLocal != null ||
        task.reminderEnabled == true ||
        linkText.isNotEmpty;

    return Dismissible(
      key: ValueKey('todo-${task.taskId}'),
      direction: DismissDirection.startToEnd,
      background: _SwipeBackground(reopen: done, radius: radius),
      // Toggle first; only let the row slide away if it stuck. onDismissed
      // then removes it from the list model right away — so the refetch that
      // follows never rebuilds a dismissed tile (which would assert), and the
      // row leaves in one motion instead of springing back first.
      confirmDismiss: (_) => _toggle(context, ref),
      onDismissed: (_) => onDismissed?.call(task.taskId),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          //side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () => context.push(taskDetailPath(task.taskId)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title ?? '(untitled)',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                  decoration:
                                      done ? TextDecoration.lineThrough : null,
                                  color: done ? muted : null,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // The hint shares the title's row rather than taking its
                    // own line — it's fixed width, so a long title simply
                    // ellipsizes beside it instead of overflowing.
                    if (!done) ...[
                      const SizedBox(width: 10),
                      _SwipeHint(color: muted),
                    ],
                  ],
                ),
                if (hasMeta) ...[
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (dueLocal != null)
                            _TaskMeta(
                              maxWidth: maxW,
                              icon: Icons.schedule,
                              // Overdue reads purely as a red date now — no
                              // "Overdue" label, just the error colour.
                              text:
                                  '${taskDueDateLabel(dueLocal)}, ${dueTimeLabel(dueLocal, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}',
                              color: overdue ? scheme.error : muted,
                            ),
                          if (task.reminderEnabled == true)
                            _TaskMeta(
                              maxWidth: maxW,
                              icon: Icons.notifications_outlined,
                              text: reminderLabel(task.reminderEnabled),
                              color: muted,
                            ),
                          if (linkText.isNotEmpty)
                            _TaskMeta(
                              maxWidth: maxW,
                              icon: Icons.receipt_long_outlined,
                              text: linkText,
                              color: muted,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A light meta item under a to-do title — small icon, short label, no fill.
/// Muted by default; the due line passes [ColorScheme.error] when overdue,
/// which is the card's only status signal.
class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.icon,
    required this.text,
    required this.color,
    required this.maxWidth,
  });

  final IconData icon;
  final String text;
  final Color color;

  /// The meta items live in a [Wrap], which hands its children unbounded
  /// width — so a long value (a linked order number plus a client name)
  /// would run past the card edge and overflow. Capping to the row's own
  /// width lets the label ellipsize and drop onto its own line instead.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel revealed behind a to-do as it's swiped right — a primary field
/// with a leading action label. Says "Complete" for a pending to-do,
/// "Reopen" for a done one. Rounded to the card's radius so the revealed
/// edge matches the tile it sits behind.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.reopen, required this.radius});

  final bool reopen;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.primary, borderRadius: radius),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reopen ? Icons.undo : Icons.check_circle,
              color: scheme.onPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            reopen ? 'Reopen' : 'Complete',
            style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// The resting cue beside a pending to-do's title — "Swipe to complete" and
/// a pair of rightward chevrons, both faint, so the gesture is discoverable
/// without shouting over the title. Chevrons point right, the direction the
/// swipe travels.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final faint = color.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Swipe to complete',
          style: TextStyle(
              fontSize: 11, color: faint, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 3),
        Icon(Icons.keyboard_double_arrow_right, size: 15, color: faint),
      ],
    );
  }
}
