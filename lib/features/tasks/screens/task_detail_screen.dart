import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../orders/models/order_item.dart';
import '../../orders/state/order_detail_notifier.dart';
import '../../orders/widgets/measurement_snapshot_section.dart';
import '../models/task_detail.dart';
import '../models/task_stage.dart';
import '../state/task_detail_notifier.dart';
import '../state/tasks_providers.dart';
import '../utils/task_labels.dart';
import '../widgets/stage_timeline.dart';
import '../widgets/task_pickers.dart';
import '../widgets/todo_sheet.dart';

/// The task detail — production layout (header context, vertical stage
/// timeline, owner actions, events) or to-do layout (title, complete
/// button, due/reminder/links, events), branched on `kind`.
///
/// Mutation pattern: every action funnels through [_run], which surfaces
/// failures as SnackBars and tracks a per-stage busy id so exactly the row
/// being acted on shows a spinner — no full-screen blanking for a tap
/// (matching the order detail's philosophy).
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  String? _busyStageId;
  bool _busyScreen = false;

  TaskDetailNotifier get _notifier =>
      ref.read(taskDetailProvider(widget.taskId).notifier);

  Future<void> _run(
    Future<void> Function() op, {
    String? stageId,
  }) async {
    setState(() {
      _busyStageId = stageId;
      _busyScreen = stageId == null;
    });
    try {
      await op();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyStageId = null;
          _busyScreen = false;
        });
      }
    }
  }

  // ── Stage actions ────────────────────────────────────────────────────────
  Future<void> _finish(TaskStage stage) => _run(stageId: stage.id, () async {
        final updated = await _notifier.finish(stage.id);
        if (!mounted) return;
        final handover = updated.handover;
        if (updated.isComplete) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('All stages done'),
              content: const Text(
                  'This outfit has finished its pipeline. If it was the '
                  'last one, the order has moved to Ready.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK')),
              ],
            ),
          );
        } else if (handover != null) {
          // Handover is one-sided: finishing IS the handover; this dialog
          // just tells the owner whose table the garment goes to.
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Done'),
              content: Text(handover.nextEmployeeName != null
                  ? 'Hand over to ${handover.nextEmployeeName} for '
                      '${handover.nextStageName}.'
                  : '${handover.nextStageName} is next — it has no worker '
                      'yet. Assign one before it can start.'),
              actions: [
                if (handover.nextEmployeeId == null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _assignById(handover.nextStageId);
                    },
                    child: const Text('Assign now'),
                  ),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK')),
              ],
            ),
          );
        }
      });

  Future<void> _assign(TaskStage stage) => _assignById(stage.id);

  Future<void> _assignById(String stageId) async {
    final employee = await pickEmployee(context, ref);
    if (employee == null) return;
    await _run(
        stageId: stageId, () => _notifier.assignStage(stageId, employee.id));
  }

  Future<void> _skip(TaskStage stage) async {
    final confirmed = await _confirm(
      title: 'Skip ${stage.processName}?',
      body: 'The stage is marked finished without any work recorded. '
          'It stays visible in the pipeline as "Skipped".',
      confirmLabel: 'Skip',
    );
    if (confirmed) {
      await _run(stageId: stage.id, () => _notifier.skip(stage.id));
    }
  }

  Future<void> _sendBack(TaskStage stage, TaskDetail task) async {
    // Spell out exactly what resets — a send-back wipes downstream work.
    final laterTouched = task.stages
        .where((s) =>
            s.sequence > stage.sequence &&
            (s.startedAt != null || s.finishedAt != null))
        .map((s) => s.processName)
        .toList();
    final confirmed = await _confirm(
      title: 'Send work back to ${stage.processName}?',
      body: laterTouched.isEmpty
          ? '${stage.processName} reopens for rework.'
          : '${stage.processName} reopens for rework, and progress on '
              '${laterTouched.join(', ')} is cleared.',
      confirmLabel: 'Send back',
      destructive: true,
    );
    if (confirmed) {
      await _run(stageId: stage.id, () => _notifier.sendBack(stage.id));
    }
  }

  Future<void> _move(TaskStage stage, int delta) async {
    // The API takes an absolute 1-based sequence; the menu offers ±1.
    final target = stage.sequence + delta;
    await _run(
        stageId: stage.id, () => _notifier.reorderStage(stage.id, target));
  }

  Future<void> _removeStage(TaskStage stage) async {
    final confirmed = await _confirm(
      title: 'Remove ${stage.processName}?',
      body: 'Only stages that haven\'t been started can be removed.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed) {
      await _run(stageId: stage.id, () => _notifier.removeStage(stage.id));
    }
  }

  // ── Task-level actions ───────────────────────────────────────────────────
  Future<void> _editExpectedDate(TaskDetail task) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: task.expectedCompletionDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    if (task.orderDueDate != null && picked.isAfter(task.orderDueDate!)) {
      // Warn but allow — same rule as the create screen; the owner may
      // knowingly plan an item past the order's promise date.
      final proceed = await _confirm(
        title: "After the order's due date",
        body:
            "This is later than the order's due date of ${taskDueDateLabel(task.orderDueDate!)}. Use it anyway?",
        confirmLabel: 'Use this date',
      );
      if (!proceed) return;
    }
    await _run(() => _notifier.updateExpectedDate(picked));
  }

  Future<void> _appendStage() async {
    // Two-step append: process, then optional worker.
    final processes = await ref.read(activeProcessesProvider.future);
    if (!mounted) return;
    final processId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in processes)
              ListTile(
                title: Text(p.name),
                onTap: () => Navigator.pop(ctx, p.id),
              ),
          ],
        ),
      ),
    );
    if (processId == null || !mounted) return;
    final employee = await pickEmployee(context, ref);
    await _run(() =>
        _notifier.appendStage(processId: processId, employeeId: employee?.id));
  }

  Future<void> _deleteTask(TaskDetail task) async {
    final confirmed = await _confirm(
      title: task.isGeneral ? 'Delete this to-do?' : 'Delete this task?',
      body: task.isGeneral
          ? 'The to-do and its reminder are removed. Its history stays in '
              'the activity log.'
          : 'The item goes back to "Not started". The task\'s history '
              'stays in the order\'s activity log.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _notifier.deleteTask();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(taskDetailProvider(widget.taskId));
    final task = detailAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(task?.isGeneral == true ? 'To-do' : 'Task'),
        actions: [
          if (task != null)
            _ScreenMenu(
              task: task,
              enabled: !_busyScreen,
              onEditDate: () => _editExpectedDate(task),
              onEditTodo: () => showTodoSheet(context, ref, existing: task),
              onAddStage: _appendStage,
              onDelete: () => _deleteTask(task),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorRetry(
          error: err,
          onRetry: () =>
              ref.read(taskDetailProvider(widget.taskId).notifier).refresh(),
        ),
        data: (task) => RefreshIndicator(
          onRefresh: () =>
              ref.read(taskDetailProvider(widget.taskId).notifier).refresh(),
          child: task.isGeneral
              ? _TodoBody(
                  task: task,
                  busy: _busyScreen,
                  onToggleComplete: () => _run(() => task.isComplete
                      ? _notifier.reopen()
                      : _notifier.complete()),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _ProductionHeader(task: task),
                    const SizedBox(height: 24),
                    const _SectionLabel(
                        icon: Icons.timeline_outlined, text: 'Production'),
                    const SizedBox(height: 12),
                    StageTimeline(
                      task: task,
                      busyStageId: _busyStageId,
                      actions: StageActions(
                        onStart: (s) =>
                            _run(stageId: s.id, () => _notifier.start(s.id)),
                        onFinish: _finish,
                        onCancelStart: (s) => _run(
                            stageId: s.id, () => _notifier.cancelStart(s.id)),
                        onAssign: _assign,
                        onSkip: _skip,
                        onSendBack: (s) => _sendBack(s, task),
                        onMove: (s, d) => _move(s, d),
                        onRemove: _removeStage,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busyScreen ? null : _appendStage,
                        icon: const Icon(Icons.add),
                        label: const Text('Add stage'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EventsSection(task: task),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ScreenMenu extends StatelessWidget {
  const _ScreenMenu({
    required this.task,
    required this.enabled,
    required this.onEditDate,
    required this.onEditTodo,
    required this.onAddStage,
    required this.onDelete,
  });

  final TaskDetail task;
  final bool enabled;
  final VoidCallback onEditDate;
  final VoidCallback onEditTodo;
  final VoidCallback onAddStage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: enabled,
      itemBuilder: (_) => [
        if (task.isProduction)
          const PopupMenuItem(value: 'date', child: Text('Edit expected date')),
        if (task.isProduction)
          const PopupMenuItem(value: 'add', child: Text('Add stage')),
        if (task.isGeneral)
          const PopupMenuItem(value: 'edit', child: Text('Edit to-do')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      onSelected: (value) {
        switch (value) {
          case 'date':
            onEditDate();
          case 'add':
            onAddStage();
          case 'edit':
            onEditTodo();
          case 'delete':
            onDelete();
        }
      },
    );
  }
}

/// The garment identity card at the top of a production task. Two stacked
/// regions in one card:
///
///  * the **top** — thumbnail, code, garment, recipient, qty×price, and a
///    trailing chevron — is a tap target that opens the parent order on its
///    Outfits tab with this item highlighted (`?tab=outfits&item=<id>`), so
///    the task and the outfit it belongs to are one hop apart; and
///  * the **bottom** — the measurement snapshot the garment is cut from,
///    resolved from the parent order and expandable in place.
///
/// The measurement half lives here (rather than as its own section lower
/// down) so "what is this?" and "what's it cut from?" sit together.
class _ProductionHeader extends StatelessWidget {
  const _ProductionHeader({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final thumbnail = task.thumbnailUrl;
    final orderId = task.orderId;
    final orderItemId = task.orderItemId;
    final canOpenOrder = orderId != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: identity + tap-through to the order (highlighting the item)
          InkWell(
            onTap: canOpenOrder
                ? () => context.push(
                      '/orders/$orderId?tab=outfits'
                      '${orderItemId != null ? '&item=$orderItemId' : ''}',
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      image: (thumbnail != null && thumbnail.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(thumbnail),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: (thumbnail == null || thumbnail.isEmpty)
                        ? Icon(Icons.checkroom_outlined,
                            color: tokens.mutedForeground)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((task.codeLabel ?? '').isNotEmpty)
                          Text(task.codeLabel!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  )),
                        Text(task.garmentType ?? 'Garment',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if ((task.recipientName ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14, color: tokens.mutedForeground),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(task.recipientName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: tokens.mutedForeground)),
                              ),
                            ],
                          ),
                        ],
                        if (task.quantity != null &&
                            task.unitPrice != null) ...[
                          const SizedBox(height: 2),
                          Text(
                              '${task.quantity} × ${formatNaira(task.unitPrice!)}',
                              style: TextStyle(
                                  color: tokens.mutedForeground, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  if (canOpenOrder) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: tokens.mutedForeground),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom: the measurement snapshot the garment is cut from.
          if (canOpenOrder && orderItemId != null) ...[
            Divider(height: 1, thickness: 1, color: tokens.sidebarBorder),
            _OutfitMeasurementSection(
              orderId: orderId,
              orderItemId: orderItemId,
            ),
          ],
        ],
      ),
    );
  }
}

/// A quiet section heading — a small icon and an all-caps-ish label in the
/// muted foreground — used to break the production body into blocks.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTokens.mutedForeground;
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
      ],
    );
  }
}

/// The measurement snapshots the garment is cut from, rendered inside the
/// header card. A multi-piece outfit (top + skirt) has one snapshot per piece.
/// The task payload carries the order + item ids but not the set ids, so the
/// parent order is read (cached — usually already loaded when you arrive from
/// the order) to resolve the item's `measurementSetIds`, then the shared
/// [MeasurementSnapshotSection] renders each one's values on demand.
class _OutfitMeasurementSection extends ConsumerWidget {
  const _OutfitMeasurementSection({
    required this.orderId,
    required this.orderItemId,
  });

  final String orderId;
  final String orderItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = context.appTokens.mutedForeground;
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: child,
        );

    Widget muteRow(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.straighten_outlined, size: 15, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: muted)),
              ),
            ],
          ),
        );

    return orderAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => pad(const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )),
      error: (_, __) => pad(Row(
        children: [
          Expanded(child: muteRow('Could not load measurements.')),
          TextButton(
            onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
            child: const Text('Retry'),
          ),
        ],
      )),
      data: (order) {
        OrderItem? item;
        for (final i in order.items) {
          if (i.id == orderItemId) {
            item = i;
            break;
          }
        }
        final setIds = item?.measurementSetIds ?? const <String>[];
        if (setIds.isEmpty) {
          return pad(muteRow('No measurement snapshot for this outfit.'));
        }
        return pad(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final setId in setIds)
              MeasurementSnapshotSection(setId: setId),
          ],
        ));
      },
    );
  }
}

class _TodoBody extends StatelessWidget {
  const _TodoBody({
    required this.task,
    required this.busy,
    required this.onToggleComplete,
  });

  final TaskDetail task;
  final bool busy;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final dueLocal = task.dueAt?.toLocal();
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final overdue = task.delayed && !task.isComplete;
    final linkText = [
      if ((task.orderNumber ?? '').isNotEmpty) task.orderNumber!,
      if ((task.recipientName ?? '').isNotEmpty) task.recipientName!,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Title ──────────────────────────────────────────────────────
        Text(
          task.title ?? '(untitled)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
                decoration:
                    task.isComplete ? TextDecoration.lineThrough : null,
                color: task.isComplete ? tokens.mutedForeground : null,
              ),
        ),
        const SizedBox(height: 20),

        // ── Details (due / reminder / link) ────────────────────────────
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (dueLocal != null)
                _DetailRow(
                  icon: Icons.event_outlined,
                  accent: overdue ? scheme.error : scheme.primary,
                  label: 'Due',
                  value:
                      '${taskDueDateLabel(dueLocal)} · ${dueTimeLabel(dueLocal, use24h: use24h)}',
                  valueColor: overdue ? scheme.error : null,
                ),
              if (dueLocal != null) const _RowDivider(),
              _DetailRow(
                icon: task.reminderEnabled == true
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                accent: task.reminderEnabled == true
                    ? scheme.primary
                    : tokens.mutedForeground,
                label: 'Reminder',
                value: task.reminderEnabled == true ? 'On' : 'Off',
              ),
              if (linkText.isNotEmpty) ...[
                const _RowDivider(),
                _DetailRow(
                  icon: Icons.link_outlined,
                  accent: scheme.primary,
                  label: 'Linked',
                  value: linkText,
                  onTap: task.orderId != null
                      ? () => context.push('/orders/${task.orderId}')
                      : null,
                ),
              ],
            ],
          ),
        ),

        // ── Notes ──────────────────────────────────────────────────────
        if ((task.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel(icon: Icons.notes_outlined, text: 'Notes'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Text(
              task.notes!,
              style: TextStyle(color: scheme.onSurface, height: 1.4),
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: task.isComplete
              ? OutlinedButton.icon(
                  onPressed: busy ? null : onToggleComplete,
                  icon: const Icon(Icons.undo),
                  label: const Text('Reopen'),
                )
              : FilledButton.icon(
                  onPressed: busy ? null : onToggleComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as done'),
                ),
        ),
        const SizedBox(height: 20),
        _EventsSection(task: task),
      ],
    );
  }
}

/// One line inside the to-do details card: a tinted icon tile, a muted
/// label, and the value pushed to the right. Tappable (with a chevron)
/// when [onTap] is set — used by the linked-order row.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(tokens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  color: tokens.mutedForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: tokens.mutedForeground),
            ],
          ],
        ),
      ),
    );
  }
}

/// A full-width hairline between [_DetailRow]s.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    if (task.events.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Text('Activity', style: Theme.of(context).textTheme.titleSmall),
        for (final e in task.events)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(taskEventActionLabel(e.action)),
            subtitle: (e.detail ?? '').isNotEmpty ? Text(e.detail!) : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  taskDueDateLabel(e.createdAt.toLocal()),
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                ),
                Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(e.createdAt.toLocal()),
                    alwaysUse24HourFormat:
                        MediaQuery.of(context).alwaysUse24HourFormat,
                  ),
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load.\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
