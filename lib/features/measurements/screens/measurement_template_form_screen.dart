import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../models/measurement_template.dart';
import '../state/dictionary_admin_notifiers.dart';
import '../utils/dictionary_errors.dart';

/// One row being edited. Held locally because the template's field list is
/// saved as a whole: the backend's PUT replaces every TemplateField row with
/// whatever is sent, so there's nothing to sync per-row and no half-saved state
/// to reason about.
class _FieldRow {
  _FieldRow({
    required this.fieldId,
    required this.label,
    required this.unit,
    required this.isRequired,
    required this.isArchived,
  });

  final String fieldId;
  final String label;
  final String unit;
  bool isRequired;

  /// The underlying dictionary field has been archived. The capture form skips
  /// these, so the row is dead weight — shown with a warning so it gets removed
  /// deliberately instead of silently disappearing from the garment.
  final bool isArchived;
}

/// Create or edit a measurement template. Pass [templateId] to edit.
///
/// The field list is drag-to-reorder — the order here is the order the tailor
/// meets the inputs on the capture form, so it should match the order they
/// actually run the tape. Required fields block a set from being saved without
/// them.
class MeasurementTemplateFormScreen extends ConsumerStatefulWidget {
  const MeasurementTemplateFormScreen({super.key, this.templateId});

  final String? templateId;

  bool get isEditing => templateId != null;

  @override
  ConsumerState<MeasurementTemplateFormScreen> createState() =>
      _MeasurementTemplateFormScreenState();
}

class _MeasurementTemplateFormScreenState
    extends ConsumerState<MeasurementTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _garmentTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<_FieldRow> _rows = [];
  bool _isArchived = false;
  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _garmentTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefill(MeasurementTemplate template) {
    if (_prefilled) return;
    _nameController.text = template.name;
    _garmentTypeController.text = template.garmentType ?? '';
    _descriptionController.text = template.description ?? '';
    _isArchived = template.isArchived;

    final ordered = [...template.fields]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _rows
      ..clear()
      ..addAll(ordered.map((f) => _FieldRow(
            fieldId: f.fieldId,
            label: f.label,
            unit: f.unit,
            isRequired: f.isRequired,
            isArchived: f.isArchived,
          )));
    _prefilled = true;
  }

  Future<void> _addFields() async {
    final fieldsAsync = ref.read(fieldAdminListProvider);
    final all = fieldsAsync.valueOrNull;
    if (all == null) {
      showErrorMessage(context, 'Fields are still loading');
      return;
    }

    final present = _rows.map((r) => r.fieldId).toSet();
    final available = all
        .where((f) => !f.isArchived && !present.contains(f.id))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    if (available.isEmpty) {
      showErrorMessage(
        context,
        present.isEmpty
            ? 'Add some measurement fields first'
            : 'Every field is already in this template',
      );
      return;
    }

    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FieldPickerSheet(fields: available),
    );
    if (picked == null || picked.isEmpty) return;

    setState(() {
      for (final f in available.where((f) => picked.contains(f.id))) {
        _rows.add(_FieldRow(
          fieldId: f.id,
          label: f.label,
          unit: f.unit,
          isRequired: false,
          isArchived: false,
        ));
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rows.isEmpty) {
      showErrorMessage(context, 'Add at least one field to this template');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(measurementRepositoryProvider);
      // Position in the list IS the sort order — that's the whole contract.
      final fields = [
        for (var i = 0; i < _rows.length; i++)
          TemplateFieldInput(
            fieldId: _rows[i].fieldId,
            sortOrder: i,
            isRequired: _rows[i].isRequired,
          ),
      ];

      if (widget.isEditing) {
        await repo.updateTemplate(
          widget.templateId!,
          name: _nameController.text.trim(),
          garmentType: _garmentTypeController.text.trim(),
          description: _descriptionController.text.trim(),
          isArchived: _isArchived,
          fields: fields,
        );
      } else {
        await repo.createTemplate(
          name: _nameController.text.trim(),
          garmentType: _garmentTypeController.text.trim(),
          description: _descriptionController.text.trim(),
          fields: fields,
        );
      }

      invalidateMeasurementDictionary(ref);
      await ref.read(templateAdminListProvider.notifier).refresh();
      if (!mounted) return;
      showSuccessSnackbar(
        context,
        widget.isEditing ? 'Template saved' : 'Template added',
      );
      context.pop();
    } catch (err) {
      if (mounted) showErrorMessage(context, describeDictionaryError(err));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this template?'),
        content: const Text(
          'If any measurements were recorded under it, the delete will be '
          'refused and you can archive it instead. Measurements are never '
          'affected either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(measurementRepositoryProvider)
          .deleteTemplate(widget.templateId!);
      invalidateMeasurementDictionary(ref);
      await ref.read(templateAdminListProvider.notifier).refresh();
      if (!mounted) return;
      showSuccessSnackbar(context, 'Template deleted');
      context.pop();
    } on DioException catch (err) {
      if (!mounted) return;
      // The backend refuses to delete a template that measurements were
      // captured under, and says so. Rather than dead-ending on the message,
      // offer the thing it's telling you to do.
      if (err.response?.statusCode == 400) {
        final archive = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Can't delete this template"),
            content: Text(
              '${describeDictionaryError(err)}\n\n'
              'Archiving hides it from new measurements. Everything recorded '
              'under it stays readable.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Archive it'),
              ),
            ],
          ),
        );
        if (archive == true) {
          setState(() => _isArchived = true);
          await _submit();
          return;
        }
      } else {
        showErrorMessage(context, describeDictionaryError(err));
      }
    } catch (err) {
      if (mounted) showErrorMessage(context, describeDictionaryError(err));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The picker sheet reads the dictionary, so warm it up either way.
    ref.watch(fieldAdminListProvider);

    if (!widget.isEditing) return _buildScaffold(context);

    final templateAsync = ref.watch(templateByIdProvider(widget.templateId!));
    return templateAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit template')),
        body: AsyncErrorView(
          error: err,
          onRetry: () async =>
              ref.invalidate(templateByIdProvider(widget.templateId!)),
        ),
      ),
      data: (template) {
        _prefill(template);
        return _buildScaffold(context);
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final hasArchivedRows = _rows.any((r) => r.isArchived);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit template' : 'New template'),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSubmitting ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Agbada',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _garmentTypeController,
              decoration: const InputDecoration(
                labelText: 'Garment type (optional)',
                hintText: 'e.g. agbada',
                helperText: 'Matches the garment on an order item',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fields',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _addFields,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add fields'),
                ),
              ],
            ),
            Text(
              'Drag to set the order the tailor measures in. Required fields '
              'must be filled before a measurement can be saved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No fields yet — add the measurements this garment needs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final row = _rows.removeAt(oldIndex);
                    _rows.insert(newIndex, row);
                  });
                },
                children: [
                  for (var i = 0; i < _rows.length; i++)
                    _FieldRowTile(
                      key: ValueKey(_rows[i].fieldId),
                      index: i,
                      row: _rows[i],
                      onRequiredChanged: (v) =>
                          setState(() => _rows[i].isRequired = v),
                      onRemove: () => setState(() => _rows.removeAt(i)),
                    ),
                ],
              ),
            if (hasArchivedRows)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Archived fields no longer appear when measurements are taken. '
                  'Remove them from this template, or un-archive the field.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            if (widget.isEditing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isArchived,
                title: const Text('Archived'),
                subtitle: const Text(
                  'Hidden when taking new measurements. Everything recorded under '
                  'it stays readable.',
                ),
                onChanged: (v) => setState(() => _isArchived = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Save changes' : 'Add template'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRowTile extends StatelessWidget {
  const _FieldRowTile({
    super.key,
    required this.index,
    required this.row,
    required this.onRequiredChanged,
    required this.onRemove,
  });

  final int index;
  final _FieldRow row;
  final ValueChanged<bool> onRequiredChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, color: scheme.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: TextStyle(
                    color: row.isArchived ? scheme.error : null,
                    decoration:
                        row.isArchived ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  row.isArchived
                      ? 'Archived — not shown when measuring'
                      : (row.unit == 'none' ? 'No unit' : row.unit),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: row.isArchived ? scheme.error : scheme.outline,
                      ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Required',
                  style: Theme.of(context).textTheme.labelSmall),
              Switch(
                value: row.isRequired,
                onChanged: row.isArchived ? null : onRequiredChanged,
              ),
            ],
          ),
          IconButton(
            tooltip: 'Remove',
            icon: Icon(Icons.close, color: scheme.outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Multi-select sheet over the shop's active dictionary. Multi-select rather
/// than one-at-a-time because building a template means picking eight or ten
/// fields, and eight round trips through a sheet is a chore.
class _FieldPickerSheet extends StatefulWidget {
  const _FieldPickerSheet({required this.fields});

  final List<MeasurementField> fields;

  @override
  State<_FieldPickerSheet> createState() => _FieldPickerSheetState();
}

class _FieldPickerSheetState extends State<_FieldPickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add fields',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected),
                  child: Text(
                    _selected.isEmpty ? 'Add' : 'Add ${_selected.length}',
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.fields.length,
              itemBuilder: (context, index) {
                final f = widget.fields[index];
                final description = f.description?.trim() ?? '';
                final detail = [
                  if (description.isNotEmpty) description,
                  if (f.unit != 'none') f.unit,
                ].join('  ·  ');
                return CheckboxListTile(
                  value: _selected.contains(f.id),
                  title: Text(f.label),
                  subtitle: detail.isEmpty ? null : Text(detail),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(f.id);
                    } else {
                      _selected.remove(f.id);
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
