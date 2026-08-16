import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../employees/models/employee.dart';
import '../../orders/state/order_detail_notifier.dart';
import '../models/production_process.dart';
import '../models/task_inputs.dart';
import '../state/tasks_providers.dart';
import '../tasks_paths.dart';
import '../utils/task_labels.dart';
import '../widgets/task_pickers.dart';

/// Create the production task for one order item:
/// `/orders/:orderId/items/:itemId/task/new`.
///
/// Flow: tick processes from the dictionary (pre-ordered by sort_order) →
/// they appear in the Pipeline section, drag-to-reorder, each with an
/// optional worker → pick the expected completion date → create. Rules
/// surfaced inline rather than as failures: ≥1 stage and a date are
/// required; a date after the order's due date warns but is allowed; an
/// unassigned stage is fine now but can't be STARTED until assigned (the
/// footnote says so once, instead of nagging per row).
///
/// One stage per process instance: ticking a process adds it once. The
/// backend permits duplicates in a pipeline, but the create screen keeps
/// the common case simple — a second instance of a process can be
/// appended from the task detail afterwards.
class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({
    super.key,
    required this.orderId,
    required this.itemId,
  });

  final String orderId;
  final String itemId;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _StageDraft {
  _StageDraft(this.process);

  final ProductionProcess process;
  Employee? worker;
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final List<_StageDraft> _pipeline = [];
  DateTime? _expectedDate;
  bool _busy = false;

  bool _selected(ProductionProcess p) =>
      _pipeline.any((d) => d.process.id == p.id);

  void _toggle(ProductionProcess p) {
    setState(() {
      final existing = _pipeline.indexWhere((d) => d.process.id == p.id);
      if (existing >= 0) {
        _pipeline.removeAt(existing);
      } else {
        _pipeline.add(_StageDraft(p));
      }
    });
  }

  Future<void> _pickWorker(_StageDraft draft) async {
    final employee = await pickEmployee(context, ref);
    if (employee != null) setState(() => draft.worker = employee);
  }

  Future<void> _assignAllToOne() async {
    final employee = await pickEmployee(context, ref);
    if (employee == null) return;
    // Fills every picker; each stays individually editable afterwards.
    setState(() {
      for (final d in _pipeline) {
        d.worker = employee;
      }
    });
  }

  Future<void> _pickDate(DateTime? orderDue) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? orderDue ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  Future<void> _create() async {
    if (_pipeline.isEmpty || _expectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pick at least one stage and a completion date')));
      return;
    }
    setState(() => _busy = true);
    try {
      final detail = await createProductionTask(
        ref,
        widget.itemId,
        expectedCompletionDate: _expectedDate!,
        stages: [
          for (final d in _pipeline)
            TaskStageInput(processId: d.process.id, employeeId: d.worker?.id),
        ],
      );
      if (mounted) {
        // Replace, not push: back from the new task should land on the
        // order, not on a spent create form.
        context.pushReplacement(taskDetailPath(detail.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create task: $e')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final processesAsync = ref.watch(activeProcessesProvider);
    // The order supplies its due date for the inline warning and the
    // garment name for the header context. Watching the existing detail
    // provider reuses whatever the order screen already fetched.
    final order = ref.watch(orderDetailProvider(widget.orderId)).valueOrNull;
    final orderDue = order?.dueDate;
    String? garment;
    if (order != null) {
      for (final item in order.items) {
        if (item.id == widget.itemId) {
          garment = item.garmentType;
          break;
        }
      }
    }

    final dateAfterDue = _expectedDate != null &&
        orderDue != null &&
        _expectedDate!.isAfter(orderDue);
    final hasUnassigned = _pipeline.any((d) => d.worker == null);

    return Scaffold(
      appBar: AppBar(
        title: Text(garment == null ? 'Create task' : 'Task · $garment'),
      ),
      body: processesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load processes.\n$err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(activeProcessesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (processes) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text('Stages', style: Theme.of(context).textTheme.titleSmall),
            Text(
              'Tick the work this outfit needs, in any order — arrange '
              'the pipeline below.',
              style:
                  TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            for (final p in processes)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selected(p),
                onChanged: (_) => _toggle(p),
                title: Text(p.name),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                // New processes are managed in one place (Settings) rather
                // than inline — decided in review. On return, the
                // provider refetch picks up anything added there.
                onPressed: () => context.push('/settings/processes'),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Manage processes'),
              ),
            ),
            if (_pipeline.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text('Pipeline',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _assignAllToOne,
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: const Text('Assign all to one worker'),
                  ),
                ],
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = _pipeline.removeAt(oldIndex);
                    _pipeline.insert(newIndex, moved);
                  });
                },
                children: [
                  for (var i = 0; i < _pipeline.length; i++)
                    Card(
                      key: ValueKey(_pipeline[i].process.id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(
                            '${i + 1}. ${_pipeline[i].process.name}'),
                        subtitle: Text(
                          _pipeline[i].worker?.name ?? 'Unassigned',
                          style: TextStyle(
                            color: _pipeline[i].worker == null
                                ? scheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => _pickWorker(_pipeline[i]),
                          child: Text(_pipeline[i].worker == null
                              ? 'Assign'
                              : 'Change'),
                        ),
                      ),
                    ),
                ],
              ),
              if (hasUnassigned)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Unassigned stages are fine — they just can\'t be '
                    'started until a worker is assigned.',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_expectedDate == null
                  ? 'Expected completion date *'
                  : 'Expected ${taskDueDateLabel(_expectedDate!)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickDate(orderDue),
            ),
            if (dateAfterDue)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Heads up: this is after the order\'s due date '
                  '(${taskDueDateLabel(orderDue!)}). Allowed, but the '
                  'outfit would finish late.',
                  style: TextStyle(
                      color: scheme.onErrorContainer, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create task'),
          ),
        ),
      ),
    );
  }
}
