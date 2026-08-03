import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                  'This garment has finished its pipeline. If it was the '
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busyScreen ? null : _appendStage,
                        icon: const Icon(Icons.add),
                        label: const Text('Add stage'),
                      ),
                    ),
                    const SizedBox(height: 8),
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

class _ProductionHeader extends StatelessWidget {
  const _ProductionHeader({required this.task});

  final TaskDetail task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnail = task.thumbnailUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                image: (thumbnail != null && thumbnail.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(thumbnail), fit: BoxFit.cover)
                    : null,
              ),
              child: (thumbnail == null || thumbnail.isEmpty)
                  ? Icon(Icons.checkroom_outlined,
                      color: scheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.codeLabel ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.primary)),
                  Text(task.garmentType ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if ((task.recipientName ?? '').isNotEmpty)
                    Text(task.recipientName!,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (task.quantity != null && task.unitPrice != null)
                    Text(
                        '${task.quantity} × ${formatNaira(task.unitPrice!)}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final dueLocal = task.dueAt?.toLocal();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(task.title ?? '(untitled)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  decoration:
                      task.isComplete ? TextDecoration.lineThrough : null,
                )),
        const SizedBox(height: 12),
        if (dueLocal != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(Icons.event, color: task.delayed ? scheme.error : null),
            title: Text(
                '${taskDueDateLabel(dueLocal)} · ${dueTimeLabel(dueLocal, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}'),
            subtitle: task.delayed && !task.isComplete
                ? Text('Delayed', style: TextStyle(color: scheme.error))
                : null,
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_outlined),
          title: Text(reminderOffsetLabel(task.reminderMinutesBefore)),
        ),
        if ((task.orderNumber ?? '').isNotEmpty ||
            (task.recipientName ?? '').isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: Text([
              if ((task.orderNumber ?? '').isNotEmpty) task.orderNumber!,
              if ((task.recipientName ?? '').isNotEmpty) task.recipientName!,
            ].join(' · ')),
            trailing:
                (task.orderId != null) ? const Icon(Icons.chevron_right) : null,
            onTap: task.orderId != null
                ? () => context.push('/orders/${task.orderId}')
                : null,
          ),
        if ((task.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(task.notes!, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 20),
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
                  label: const Text('Mark done'),
                ),
        ),
        const SizedBox(height: 16),
        _EventsSection(task: task),
      ],
    );
  }
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
