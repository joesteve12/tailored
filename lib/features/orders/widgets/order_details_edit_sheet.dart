import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/section_label.dart';
import '../models/order.dart';
import 'order_form_fields.dart';

/// What the edit-details sheet collected. Deliberately not an [Order] — the
/// sheet only touches the three descriptive fields it owns; discount now lives
/// in the payment ticket, and the caller commits the rest via the notifier.
class OrderDetailsEdit {
  const OrderDetailsEdit({
    required this.dueDate,
    required this.notes,
    required this.priority,
  });

  final DateTime dueDate;
  final String notes;
  final String priority;
}

/// Edit an order's due date, priority, and notes. Slides up from the bottom
/// (replacing the old centre dialog) so it reads as part of the page rather
/// than an interruption, and matches the create form's field styling.
///
/// Discount used to live here too; it moved to the payment ticket on the
/// Overview tab, where the money it changes is already shown. Returns an
/// [OrderDetailsEdit] via `Navigator.pop`, or null if dismissed — the caller
/// owns the mutation and its busy state.
class OrderDetailsEditSheet extends StatefulWidget {
  const OrderDetailsEditSheet({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailsEditSheet> createState() => _OrderDetailsEditSheetState();
}

class _OrderDetailsEditSheetState extends State<OrderDetailsEditSheet> {
  late DateTime _dueDate;
  late final TextEditingController _notesController;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.order.dueDate;
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _priority = widget.order.priority;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      // Editing allows a due date in the past (an order can run late).
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    Navigator.pop(
      context,
      OrderDetailsEdit(
        dueDate: _dueDate,
        notes: _notesController.text.trim(),
        priority: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Edit order',
                  style: TextStyle(
                    fontFamily: tokens.fontDisplay,
                    fontFamilyFallback: tokens.fontDisplayFallback,
                    fontSize: 22,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('Due date'),
            const SizedBox(height: 10),
            DueDateTile(date: _dueDate, onTap: _pickDueDate),
            const SizedBox(height: 22),
            const SectionLabel('Priority'),
            const SizedBox(height: 10),
            PrioritySelector(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Notes'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Client preferences, reminders, delivery details…',
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
