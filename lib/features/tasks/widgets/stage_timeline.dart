import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
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
class _StageRow extends StatefulWidget {
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
  State<_StageRow> createState() => _StageRowState();
}

class _StageRowState extends State<_StageRow>
    with SingleTickerProviderStateMixin {
  // One controller drives the height reveal, the chevron rotation, and the
  // content's fade/slide, so every part of the transition moves in lockstep
  // rather than as separate implicit animations racing at different rates.
  // Seeded to the current expanded state so a row that's already open
  // doesn't animate on first build.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.isExpanded ? 1 : 0,
  );

  // Drives height + chevron across the whole 0→1 span. Deliberately the
  // SAME curve in both directions (no separate reverseCurve) — asymmetric
  // easing (a gentle ease-out opening against a sharp ease-in closing) is
  // what made the collapse feel like it was snapping instead of settling.
  // With one curve, closing is just opening played backwards: continuous
  // and symmetric, not a different motion.
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  // Drives the content's own fade + horizontal slide. Also a single curve
  // used both directions: opening, it's still mostly transparent while the
  // card is small and reaches full opacity as height settles; closing plays
  // that back exactly, fading out as the card shrinks rather than vanishing
  // early and leaving a blank card to finish collapsing on its own.
  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
  );
  late final Animation<Offset> _contentSlide = _contentFade.drive(
    Tween(begin: const Offset(0.04, 0), end: Offset.zero),
  );

  @override
  void didUpdateWidget(covariant _StageRow old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stage = widget.stage;

    // The connector line is a positioned fill behind the row rather than an
    // Expanded segment inside an IntrinsicHeight — that older layout forced
    // the card to its intrinsic (fully-expanded) height, which silently
    // defeated any expand/collapse animation. Here the Stack sizes to the
    // card's *actual* height, so the card can animate its height freely and
    // the line just follows it, keeping the vertical progress rail intact.
    return Stack(
      children: [
        Positioned(
          top: 26,
          bottom: 0,
          left: 12,
          // The segment below a finished stage is primary — it's the part
          // of the rail the work has actually passed through; below an
          // untouched or in-progress stage it stays the neutral outline.
          child: Container(
            width: 2,
            color: stage.isFinished ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NodeDot(stage: stage),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: widget.isCurrent
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: scheme.primary, width: 1.2),
                        )
                      : null,
                  child: InkWell(
                    // The whole card surface is the tap target; the popup
                    // menu absorbs its own taps and won't fire this.
                    onTap: widget.onToggle,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              _StageMenu(
                                stage: stage,
                                isCurrent: widget.isCurrent,
                                canMoveUp: widget.canMoveUp,
                                canMoveDown: widget.canMoveDown,
                                canRemove: widget.canRemove,
                                enabled: !widget.busy,
                                actions: widget.actions,
                              ),
                              // Chevron rotates on the same curve as the reveal.
                              // Pointer-ignore so taps pass through to the
                              // InkWell above — it's visual feedback only, not a
                              // separate tap target.
                              IgnorePointer(
                                child: RotationTransition(
                                  turns: _curve.drive(
                                      Tween(begin: 0.0, end: 0.5)),
                                  child: Icon(
                                    Icons.expand_more,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          _StatusLine(stage: stage),
                          // The details are always built (so their measured
                          // height is stable) and layered through three
                          // transitions: SizeTransition clips them to the
                          // animating height fraction (Card's antiAlias clip
                          // catches any horizontal overshoot from the slide
                          // below), and inside that, the content itself
                          // fades in while sliding a few percent in from the
                          // right — a small right-to-left settle rather than
                          // a flat vertical wipe.
                          SizeTransition(
                            sizeFactor: _curve,
                            axisAlignment: -1,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: FadeTransition(
                                opacity: _contentFade,
                                child: _ExpandedDetails(stage: stage),
                              ),
                            ),
                          ),
                          _ActionRow(
                            stage: stage,
                            isCurrent: widget.isCurrent,
                            busy: widget.busy,
                            actions: widget.actions,
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
      ],
    );
  }
}

/// The status node — just the 26×26 dot now; the connector rail is drawn by
/// the parent [Stack] so it can span the card's animated height.
class _NodeDot extends StatelessWidget {
  const _NodeDot({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (stage.state) {
      case 'done':
        return _circle(scheme.primary,
            child: Icon(Icons.check, size: 16, color: scheme.onPrimary));
      case 'in_progress':
        return _circle(scheme.primary,
            child: Icon(Icons.schedule, size: 16, color: scheme.onPrimary));
      case 'skipped':
        return _circle(scheme.surfaceContainerHighest,
            border: scheme.outline,
            child:
                Icon(Icons.remove, size: 16, color: scheme.onSurfaceVariant));
      default:
        // Not started — a hollow ring reads as "not reached yet".
        return _circle(Colors.transparent, border: scheme.outline);
    }
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

/// The sub-header line(s): always the worker, plus a timing line once the
/// stage has been started or finished — each led by a small icon rather than
/// run together as one grey string.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final worker = stage.assignedEmployeeName;

    String? timing;
    IconData? timingIcon;
    switch (stage.state) {
      case 'done':
        final finishedAt = stage.finishedAt?.toLocal();
        if (finishedAt != null) {
          timing = 'Completed ${taskDueDateLabel(finishedAt)}';
          timingIcon = Icons.check_circle_outline;
        }
        break;
      case 'in_progress':
        final startedAt = stage.startedAt?.toLocal();
        if (startedAt != null) {
          timing = 'Started ${taskDueDateLabel(startedAt)}';
          timingIcon = Icons.play_circle_outline;
        }
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconLine(
            context,
            icon: Icons.person_outline,
            text: worker ?? 'Unassigned',
            muted: worker == null,
          ),
          if (timing != null) ...[
            const SizedBox(height: 3),
            _iconLine(context, icon: timingIcon!, text: timing),
          ],
        ],
      ),
    );
  }

  Widget _iconLine(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool muted = false,
  }) {
    final color = context.appTokens.mutedForeground;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.stage});

  final TaskStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    String stamp(DateTime? dt) {
      if (dt == null) return '—';
      final local = dt.toLocal();
      return '${taskDueDateLabel(local)} · ${dueTimeLabel(local, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}';
    }

    return Padding(
      // The card's content padding is asymmetric (12 left / 4 right, to leave
      // room for the header chevron), so add 8 on the right here to land the
      // block on an even 12/12 inset that lines up with the card edges.
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(context, 'Status', stageStateLabel(stage.state)),
            _detailRow(context, 'Started', stamp(stage.startedAt)),
            _detailRow(context, 'Finished', stamp(stage.finishedAt)),
            _detailRow(context, 'Worker',
                stage.assignedEmployeeName ?? 'Unassigned'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final tokens = context.appTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
