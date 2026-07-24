import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  const TaskCard({super.key, required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    return task.isGeneral
        ? _GeneralTaskCard(task: task)
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
    final bg = delayed ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = delayed ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        delayed ? 'Delayed' : 'On Time',
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w600),
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
                                    size: 14,
                                    color: scheme.onSurfaceVariant),
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
                ? DecorationImage(
                    image: NetworkImage(url!), fit: BoxFit.cover)
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _GeneralTaskCard extends ConsumerWidget {
  const _GeneralTaskCard({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dueLocal = task.dueAt?.toLocal();
    final linked = (task.orderNumber ?? '').isNotEmpty ||
        (task.recipientName ?? '').isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(taskDetailPath(task.taskId)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompleteCheckbox(task: task),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title ?? '(untitled)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isComplete
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isComplete
                                        ? scheme.onSurfaceVariant
                                        : null,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(task: task),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (dueLocal != null)
                            _MetaChip(
                              icon: Icons.event,
                              text:
                                  '${taskDueDateLabel(dueLocal)} · ${dueTimeLabel(dueLocal, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}',
                            ),
                          if (task.reminderMinutesBefore != null)
                            _MetaChip(
                              icon: Icons.notifications_active_outlined,
                              text: reminderOffsetLabel(
                                  task.reminderMinutesBefore),
                            ),
                          if (linked)
                            _MetaChip(
                              icon: Icons.link,
                              text: [
                                if ((task.orderNumber ?? '').isNotEmpty)
                                  task.orderNumber!,
                                if ((task.recipientName ?? '').isNotEmpty)
                                  task.recipientName!,
                              ].join(' · '),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// The card's leading checkbox: complete/reopen without leaving the list,
/// with optimistic tick + failure SnackBar. taskDetailProvider adopts the
/// server response so the summary and everything else refresh via the
/// notifier's fan-out invalidations.
class _CompleteCheckbox extends ConsumerStatefulWidget {
  const _CompleteCheckbox({required this.task});

  final TaskSummary task;

  @override
  ConsumerState<_CompleteCheckbox> createState() =>
      _CompleteCheckboxState();
}

class _CompleteCheckboxState extends ConsumerState<_CompleteCheckbox> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final notifier =
          ref.read(taskDetailProvider(widget.task.taskId).notifier);
      if (widget.task.isComplete) {
        await notifier.reopen();
      } else {
        await notifier.complete();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update to-do: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: _busy
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Checkbox(
              value: widget.task.isComplete,
              onChanged: (_) => _toggle(),
            ),
    );
  }
}
