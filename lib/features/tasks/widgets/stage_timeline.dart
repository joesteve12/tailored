import 'package:flutter/material.dart';

import '../models/task_detail.dart';
import '../models/task_stage.dart';
import '../utils/task_labels.dart';

/// The actions a stage row can request. The timeline renders and decides
/// WHICH controls each stage shows (from its derived state and position);
/// the screen owns what happens (notifier calls, confirm dialogs,
/// pickers) — so this file never imports Riverpod or repositories.
class StageActions {
  const StageActions({
    required this.onStart,
    required this.onFinish,
    required this.onCancelStart,
    required this.onAssign,
    required this.onSkip,
    required this.onSendBack,
    required this.onMove,
    required this.onRemove,
  });

  final void Function(TaskStage) onStart;
  final void Function(TaskStage) onFinish;
  final void Function(TaskStage) onCancelStart;
  final void Function(TaskStage) onAssign;
  final void Function(TaskStage) onSkip;
  final void Function(TaskStage) onSendBack;

  /// Move an untouched stage one slot up (-1) or down (+1) within the
  /// untouched tail — the drag-free reorder affordance.
  final void Function(TaskStage, int delta) onMove;
  final void Function(TaskStage) onRemove;
}

/// The vertical stage timeline on the production task detail.
///
/// Accordion behaviour: tapping a card header expands it and collapses
/// any previously open card — one open at a time. The current (active)
/// stage starts expanded; all others start collapsed.
///
/// [StageTimeline] is StatefulWidget because it owns [_expandedId]: the
/// single source of truth for which card is open. [_StageRow] is
/// stateless — it receives [isExpanded] and [onToggle] from above, so
/// there is no state duplication and no risk of two cards thinking they
/// are both open.
///
/// When a mutation changes the current stage (start, finish, skip…) the
/// parent rebuilds the timeline with a new task, and the initialisation
/// in [initState] / [didUpdateWidget] re-opens the new current stage.
class StageTimeline extends StatefulWidget {
  const StageTimeline({
    super.key,
    required this.task,
    required this.actions,
    required this.busyStageId,
  });

  final TaskDetail task;
  final StageActions actions;
  final String? busyStageId;

  @override
  State<StageTimeline> createState() => _StageTimelineState();
}

class _StageTimelineState extends State<StageTimeline> {
  /// The id of the currently expanded card, or null when all are collapsed.
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _expandedId = widget.task.currentStage?.id;
  }

  @override
  void didUpdateWidget(covariant StageTimeline old) {
    super.didUpdateWidget(old);
    final newCurrentId = widget.task.currentStage?.id;
    final oldCurrentId = old.task.currentStage?.id;
    // Re-open the new current stage whenever it changes (start, finish,
    // skip, send-back all move the current pointer). Do not collapse the
    // user's manual choice if the current stage didn't change.
    if (newCurrentId != oldCurrentId) {
      setState(() => _expandedId = newCurrentId);
    }
  }

  void _toggle(String stageId) {
    setState(() {
      _expandedId = (_expandedId == stageId) ? null : stageId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.task.stages;
    final currentId = widget.task.currentStage?.id;
    final firstUntouchedIndex = stages.indexWhere((s) => s.isUntouched);

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _StageRow(
            stage: stages[i],
            isCurrent: stages[i].id == currentId,
            isExpanded: stages[i].id == _expandedId,
            onToggle: () => _toggle(stages[i].id),
            canMoveUp: stages[i].isUntouched && i > firstUntouchedIndex,
            canMoveDown: stages[i].isUntouched && i < stages.length - 1,
            canRemove: stages[i].isUntouched && stages.length > 1,
            busy: stages[i].id == widget.busyStageId,
            actions: widget.actions,
          ),
        _TerminalRow(task: widget.task),
      ],
    );
  }
}

/// A single stage card. Stateless — expansion state lives in
/// [_StageTimelineState]. Tapping the card header (anywhere except the
/// popup menu) calls [onToggle].
class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.isCurrent,
    required this.isExpanded,
    required this.onToggle,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.busy,
    required this.actions,
  });

  final TaskStage stage;
  final bool isCurrent;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final bool busy;
  final StageActions actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NodeColumn(stage: stage),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: isCurrent
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: scheme.primary, width: 1.2),
                      )
                    : null,
                child: InkWell(
                  // The whole card surface is the tap target; the popup
                  // menu absorbs its own taps and won't fire this.
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stage.processName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _StageMenu(
                              stage: stage,
                              isCurrent: isCurrent,
                              canMoveUp: canMoveUp,
                              canMoveDown: canMoveDown,
                              canRemove: canRemove,
                              enabled: !busy,
                              actions: actions,
                            ),
                            // Chevron indicates expand/collapse state.
                            // Pointer-ignore so taps pass through to the
                            // InkWell above — the chevron is visual
                            // feedback only, not a separate tap target.
                            IgnorePointer(
                              child: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                        _StatusLine(stage: stage),
                        if (isExpanded) _ExpandedDetails(stage: stage),
                        _ActionRow(
                          stage: stage,
                          isCurrent: isCurrent,
                          busy: busy,
                          actions: actions,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeColumn extends StatelessWidget {
  const _NodeColumn({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    late Widget dot;
    switch (stage.state) {
      case 'done':
        dot = _circle(scheme.primary,
            child: Icon(Icons.check, size: 16, color: scheme.onPrimary));
        break;
      case 'skipped':
        dot = _circle(scheme.surfaceContainerHighest,
            border: scheme.outline,
            child:
                Icon(Icons.remove, size: 16, color: scheme.onSurfaceVariant));
        break;
      case 'in_progress':
        dot = _circle(scheme.primary,
            child: Icon(Icons.schedule, size: 16, color: scheme.onPrimary));
        break;
      default:
        dot = _circle(Colors.transparent, border: scheme.outline);
    }

    return Column(
      children: [
        dot,
        Expanded(
          child: Container(
            width: 2,
            color: stage.isFinished ? scheme.primary : scheme.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _circle(Color fill, {Color? border, Widget? child}) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border, width: 1.5) : null,
        ),
        child: child,
      );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String text;
    switch (stage.state) {
      case 'done':
        final finishedAt = stage.finishedAt?.toLocal();
        text = finishedAt != null
            ? 'Completed On ${taskDueDateLabel(finishedAt)}'
                '${stage.assignedEmployeeName != null ? ' · ${stage.assignedEmployeeName}' : ''}'
            : 'Completed';
        break;
      case 'skipped':
        text = 'Skipped';
        break;
      case 'in_progress':
        final startedAt = stage.startedAt?.toLocal();
        text = startedAt != null
            ? 'Started On ${taskDueDateLabel(startedAt)}'
                '${stage.assignedEmployeeName != null ? ' · ${stage.assignedEmployeeName}' : ''}'
            : 'In progress';
        break;
      default:
        text = stage.assignedEmployeeName ?? 'Unassigned';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String stamp(DateTime? dt) {
      if (dt == null) return '—';
      final local = dt.toLocal();
      return '${taskDueDateLabel(local)} · ${dueTimeLabel(local, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: ${stageStateLabel(stage.state)}'),
            Text('Started: ${stamp(stage.startedAt)}'),
            Text('Finished: ${stamp(stage.finishedAt)}'),
            Text('Worker: ${stage.assignedEmployeeName ?? 'Unassigned'}'),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.stage,
    required this.isCurrent,
    required this.busy,
    required this.actions,
  });

  final TaskStage stage;
  final bool isCurrent;
  final bool busy;
  final StageActions actions;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (busy) {
      buttons.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    } else if (isCurrent && stage.isInProgress) {
      buttons.addAll([
        FilledButton(
          onPressed: () => actions.onFinish(stage),
          child: const Text('Finish'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => actions.onCancelStart(stage),
          child: const Text('Cancel'),
        ),
      ]);
    } else if (isCurrent && stage.isUntouched) {
      if (stage.assignedEmployeeId != null) {
        buttons.add(FilledButton(
          onPressed: () => actions.onStart(stage),
          child: const Text('Start'),
        ));
      } else {
        buttons.add(FilledButton.tonal(
          onPressed: () => actions.onAssign(stage),
          child: const Text('Assign'),
        ));
      }
    } else if (stage.isUntouched && stage.assignedEmployeeId == null) {
      buttons.add(OutlinedButton(
        onPressed: () => actions.onAssign(stage),
        child: const Text('Assign'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(children: buttons),
    );
  }
}

class _StageMenu extends StatelessWidget {
  const _StageMenu({
    required this.stage,
    required this.isCurrent,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.enabled,
    required this.actions,
  });

  final TaskStage stage;
  final bool isCurrent;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final bool enabled;
  final StageActions actions;

  @override
  Widget build(BuildContext context) {
    final entries = <PopupMenuEntry<String>>[
      if (!stage.isFinished)
        const PopupMenuItem(value: 'assign', child: Text('Assign / reassign')),
      if (isCurrent && stage.isUntouched)
        const PopupMenuItem(value: 'skip', child: Text('Skip this stage')),
      if (stage.isFinished)
        const PopupMenuItem(
            value: 'send_back', child: Text('Send work back here')),
      if (canMoveUp) const PopupMenuItem(value: 'up', child: Text('Move up')),
      if (canMoveDown)
        const PopupMenuItem(value: 'down', child: Text('Move down')),
      if (canRemove)
        const PopupMenuItem(value: 'remove', child: Text('Remove stage')),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      enabled: enabled,
      itemBuilder: (_) => entries,
      onSelected: (value) {
        switch (value) {
          case 'assign':
            actions.onAssign(stage);
          case 'skip':
            actions.onSkip(stage);
          case 'send_back':
            actions.onSendBack(stage);
          case 'up':
            actions.onMove(stage, -1);
          case 'down':
            actions.onMove(stage, 1);
          case 'remove':
            actions.onRemove(stage);
        }
      },
    );
  }
}

class _TerminalRow extends StatelessWidget {
  const _TerminalRow({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expected = task.expectedCompletionDate;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: task.isComplete ? scheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: task.isComplete
                ? null
                : Border.all(color: scheme.outline, width: 1.5),
          ),
          child: task.isComplete
              ? Icon(Icons.flag, size: 14, color: scheme.onPrimary)
              : Icon(Icons.flag_outlined,
                  size: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            expected != null
                ? 'Expected Completion — ${taskDueDateLabel(expected)}'
                : 'Expected Completion',
            style: TextStyle(
                color: task.delayed ? scheme.error : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
