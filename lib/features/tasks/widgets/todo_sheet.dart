import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/reminder_reconciler.dart';
import '../models/task_detail.dart';
import '../models/task_inputs.dart';
import '../state/task_detail_notifier.dart';
import '../state/tasks_providers.dart';
import '../tasks_paths.dart';
import '../utils/task_labels.dart';
import 'task_pickers.dart';

/// Opens the to-do create/edit sheet. Pass [existing] (a general
/// TaskDetail) to edit; null to create. On successful create, navigates
/// to the new task's detail.
Future<void> showTodoSheet(
  BuildContext context,
  WidgetRef ref, {
  TaskDetail? existing,
}) {
  assert(existing == null || existing.isGeneral);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _TodoSheet(existing: existing),
  );
}

class _TodoSheet extends ConsumerStatefulWidget {
  const _TodoSheet({this.existing});

  final TaskDetail? existing;

  @override
  ConsumerState<_TodoSheet> createState() => _TodoSheetState();
}

class _TodoSheetState extends ConsumerState<_TodoSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime? _dueLocal = widget.existing?.dueAt?.toLocal();
  late bool _reminderEnabled = widget.existing?.reminderEnabled ?? false;
  // Link state: id + display label. Prefilled from the existing task's
  // linked order number / client name (the detail response carries both).
  late String? _orderId = widget.existing?.orderId;
  late String? _orderLabel = widget.existing?.orderNumber;
  late String? _clientId = widget.existing?.clientId;
  late String? _clientLabel = widget.existing?.recipientName;

  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final initial = _dueLocal ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      // Past dates allowed on purpose (backfilling an errand you already
      // missed is legitimate; it just lands in Delayed).
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      _dueLocal =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _dueLocal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A title and a due time are required')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // Permission on first USE of a reminder — the contract from the
      // Reminders spec. A denial isn't fatal: the reminder still exists
      // server-side and the in-app surfaces show it; just say so.
      if (_reminderEnabled) {
        final granted =
            await ref.read(reminderServiceProvider).ensurePermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notifications are off — the reminder will only show inside the app.'),
            ),
          );
        }
      }

      if (_isEdit) {
        await _saveEdit(title);
      } else {
        final detail = await createGeneralTask(
          ref,
          GeneralTaskInput(
            title: title,
            dueAt: _dueLocal!, // toUtc happens in toJson — one boundary
            reminderEnabled: _reminderEnabled,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            orderId: _orderId,
            clientId: _clientId,
          ),
        );
        if (mounted) {
          Navigator.pop(context);
          context.push(taskDetailPath(detail.id));
        }
        return;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save to-do: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Edit = a diff against the existing task, using the clear-flags for
  /// anything the user removed (absent key means "unchanged" on the wire,
  /// so removal must be an explicit null — see TaskRepository).
  Future<void> _saveEdit(String title) async {
    final existing = widget.existing!;
    final notifier = ref.read(taskDetailProvider(existing.id).notifier);
    final notes = _notes.text.trim();
    final existingNotes = existing.notes ?? '';
    final dueChanged =
        _dueLocal!.toUtc() != existing.dueAt?.toUtc();
    await notifier.updateGeneral(
      title: title == existing.title ? null : title,
      dueAt: dueChanged ? _dueLocal : null,
      notes: (notes.isNotEmpty && notes != existingNotes) ? notes : null,
      clearNotes: notes.isEmpty && existingNotes.isNotEmpty,
      reminderEnabled: _reminderEnabled != (existing.reminderEnabled ?? false)
          ? _reminderEnabled
          : null,
      orderId: (_orderId != null && _orderId != existing.orderId)
          ? _orderId
          : null,
      clearOrderLink: _orderId == null && existing.orderId != null,
      clientId: (_clientId != null && _clientId != existing.clientId)
          ? _clientId
          : null,
      clearClientLink: _clientId == null && existing.clientId != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueLocal = _dueLocal;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEdit ? 'Edit to-do' : 'New to-do',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'What needs doing?',
                  hintText: "e.g. Buy Chief Obi's material",
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(dueLocal == null
                    ? 'Due date & time *'
                    : '${taskDueDateLabel(dueLocal)} · ${dueTimeLabel(dueLocal, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDue,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder'),
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
              const SizedBox(height: 12),
              _LinkRow(
                icon: Icons.receipt_long_outlined,
                label: _orderLabel == null
                    ? 'Link an order (optional)'
                    : 'Order · $_orderLabel',
                linked: _orderId != null,
                onPick: () async {
                  final order = await pickOrder(context, ref);
                  if (order != null) {
                    setState(() {
                      _orderId = order.id;
                      _orderLabel = order.orderNumber;
                    });
                  }
                },
                onClear: () => setState(() {
                  _orderId = null;
                  _orderLabel = null;
                }),
              ),
              _LinkRow(
                icon: Icons.person_outline,
                label: _clientLabel == null
                    ? 'Link a client (optional)'
                    : 'Client · $_clientLabel',
                linked: _clientId != null,
                onPick: () async {
                  final client = await pickClient(context, ref);
                  if (client != null) {
                    setState(() {
                      _clientId = client.id;
                      _clientLabel = client.name;
                    });
                  }
                },
                onClear: () => setState(() {
                  _clientId = null;
                  _clientLabel = null;
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Create to-do'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.linked,
    required this.onPick,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final bool linked;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: linked
          ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
          : const Icon(Icons.chevron_right),
      onTap: onPick,
    );
  }
}
