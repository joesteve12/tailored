import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/widgets/async_error_view.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../models/measurement_set.dart';
import '../models/measurement_template.dart';
import '../state/measurement_dictionary_providers.dart';
import '../state/measurement_list_notifier.dart';
import '../state/measurement_set_providers.dart';


import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
/// Local first-or-null lookup, to avoid pulling in package:collection.
T? _findById<T>(Iterable<T> items, bool Function(T) test) {
  for (final e in items) {
    if (test(e)) return e;
  }
  return null;
}

/// One row currently shown in the form.
class _RowSpec {
  _RowSpec({
    required this.fieldId,
    required this.label,
    required this.unit,
    required this.valueType,
    required this.isRequired,
    required this.removable,
  });

  final String fieldId;
  final String label;
  final String unit;
  final String valueType; // number | text
  final bool isRequired;
  final bool removable; // ad-hoc fields can be removed; template fields can't
}

/// Captures or edits a measurement set. Pass [recipient] to create a new set
/// for that client/guest, or [setId] to edit an existing one. Picking a
/// template lays out its fields in order (required ones marked); extra fields
/// can be added ad-hoc from the shop's dictionary.
class MeasurementCaptureScreen extends ConsumerStatefulWidget {
  const MeasurementCaptureScreen({super.key, this.recipient, this.setId})
      : assert(recipient != null || setId != null,
            'Provide a recipient (create) or a setId (edit)');

  final RecipientRef? recipient;
  final String? setId;

  bool get isEditing => setId != null;

  @override
  ConsumerState<MeasurementCaptureScreen> createState() =>
      _MeasurementCaptureScreenState();
}

class _MeasurementCaptureScreenState
    extends ConsumerState<MeasurementCaptureScreen> {
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  String? _templateId;
  final List<_RowSpec> _rows = [];
  final Set<String> _adHocFieldIds = {};

  bool _isSubmitting = false;
  bool _prefilled = false;
  // The recipient: given directly on create, derived from the set on edit.
  RecipientRef? _recipient;

  @override
  void initState() {
    super.initState();
    _recipient = widget.recipient;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String fieldId) =>
      _controllers.putIfAbsent(fieldId, () => TextEditingController());

  static String _formatNumber(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toString();

  void _applyTemplate(
    MeasurementTemplate? template,
    List<MeasurementField> allFields,
  ) {
    final rows = <_RowSpec>[];
    if (template != null) {
      for (final tf in template.fields) {
        // Archived fields are skipped. A template keeps its link to a field
        // after the field is archived, so without this the form would still
        // render it — and a required one made the set impossible to save
        // (the backend now skips archived fields in its required check too).
        //
        // Editing an existing set is unaffected: a captured value on an
        // archived field is re-added below as an ad-hoc row, so nothing that
        // was already recorded is dropped on save.
        if (tf.isArchived) continue;
        rows.add(_RowSpec(
          fieldId: tf.fieldId,
          label: tf.label,
          unit: tf.unit,
          valueType: tf.valueType,
          isRequired: tf.isRequired,
          removable: false,
        ));
      }
    }
    // Re-append any ad-hoc fields the user added that aren't in this template.
    final inTemplate = rows.map((r) => r.fieldId).toSet();
    for (final fid in _adHocFieldIds) {
      if (inTemplate.contains(fid)) continue;
      final f = _findById(allFields, (e) => e.id == fid);
      if (f == null) continue;
      rows.add(_RowSpec(
        fieldId: f.id,
        label: f.label,
        unit: f.unit,
        valueType: f.valueType,
        isRequired: false,
        removable: true,
      ));
    }
    setState(() {
      _rows
        ..clear()
        ..addAll(rows);
    });
  }

  void _addAdHocField(MeasurementField f) {
    if (_rows.any((r) => r.fieldId == f.id)) return;
    _adHocFieldIds.add(f.id);
    setState(() {
      _rows.add(_RowSpec(
        fieldId: f.id,
        label: f.label,
        unit: f.unit,
        valueType: f.valueType,
        isRequired: false,
        removable: true,
      ));
    });
  }

  void _removeRow(_RowSpec row) {
    _adHocFieldIds.remove(row.fieldId);
    setState(() => _rows.removeWhere((r) => r.fieldId == row.fieldId));
  }

  Future<void> _pickAdHocField(List<MeasurementField> allFields) async {
    final present = _rows.map((r) => r.fieldId).toSet();
    final available = allFields
        .where((f) => !f.isArchived && !present.contains(f.id))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    if (available.isEmpty) {
      showErrorMessage(context, 'No more fields to add');
      return;
    }
    final picked = await showModalBottomSheet<MeasurementField>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: available
              .map((f) => ListTile(
                    title: Text(f.label),
                    subtitle: f.unit != 'none' ? Text(f.unit) : null,
                    onTap: () => Navigator.pop(ctx, f),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) _addAdHocField(picked);
  }

  /// Builds the value payload, validating number fields and (on create)
  /// required fields. Returns null if validation fails (message set in state).
  List<MeasurementValueInput>? _collectValues() {
    final values = <MeasurementValueInput>[];
    final missingRequired = <String>[];

    for (final row in _rows) {
      final text = _controllerFor(row.fieldId).text.trim();
      if (text.isEmpty) {
        if (row.isRequired && !widget.isEditing) missingRequired.add(row.label);
        continue;
      }
      if (row.valueType == 'number') {
        final v = double.tryParse(text);
        if (v == null) {
          if (mounted) {
            showErrorMessage(context, 'Enter a number for ${row.label}');
          }
          return null;
        }
        values.add(MeasurementValueInput(fieldId: row.fieldId, valueNumber: v));
      } else {
        values.add(MeasurementValueInput(fieldId: row.fieldId, valueText: text));
      }
    }

    if (missingRequired.isNotEmpty) {
      if (mounted) {
        showErrorMessage(context, 'Required: ${missingRequired.join(', ')}');
      }
      return null;
    }
    return values;
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    final values = _collectValues();
    if (values == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final repo = ref.read(measurementRepositoryProvider);
      final label = _labelController.text.trim();
      final notes = _notesController.text.trim();

      if (widget.isEditing) {
        await repo.updateSet(
          widget.setId!,
          templateId: _templateId,
          label: label,
          notes: notes,
          values: values,
        );
        ref.invalidate(measurementSetByIdProvider(widget.setId!));
      } else {
        final r = _recipient!;
        await repo.createSet(
          clientId: r.isClient ? r.id : null,
          guestRecipientId: r.isGuest ? r.id : null,
          templateId: _templateId,
          label: label,
          notes: notes,
          values: values,
        );
      }
      if (_recipient != null) {
        await ref
            .read(measurementListProvider(_recipient!).notifier)
            .refresh();
      }
      if (mounted) {
        showSuccessSnackbar(
          context,
          widget.isEditing ? 'Measurements updated' : 'Measurements saved',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          e,
          action: '${widget.isEditing ? 'Update' : 'Save'} failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _prefillFromSet(
    MeasurementSet set,
    List<MeasurementField> allFields,
    List<MeasurementTemplate> templates,
  ) {
    if (_prefilled) return;
    _labelController.text = set.label ?? '';
    _notesController.text = set.notes ?? '';
    _templateId = set.templateId;
    _recipient = set.clientId != null
        ? clientRecipient(set.clientId!)
        : guestRecipient(set.guestRecipientId!);

    final template = _templateId == null
        ? null
        : _findById(templates, (t) => t.id == _templateId);

    // Lay out template rows first.
    _applyTemplate(template, allFields);

    // Any captured value not covered by the template becomes an ad-hoc row.
    final present = _rows.map((r) => r.fieldId).toSet();
    for (final v in set.values) {
      if (!present.contains(v.fieldId)) {
        final f = _findById(allFields, (e) => e.id == v.fieldId);
        _adHocFieldIds.add(v.fieldId);
        _rows.add(_RowSpec(
          fieldId: v.fieldId,
          label: v.label,
          unit: v.unit ?? f?.unit ?? 'none',
          valueType: f?.valueType ?? (v.valueText != null ? 'text' : 'number'),
          isRequired: false,
          removable: true,
        ));
      }
    }

    // Fill controllers from captured values.
    for (final v in set.values) {
      final c = _controllerFor(v.fieldId);
      c.text = v.valueText ??
          (v.valueNumber != null ? _formatNumber(v.valueNumber!) : '');
    }
    _prefilled = true;
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  Widget _buildForm(
    BuildContext context,
    List<MeasurementField> allFields,
    List<MeasurementTemplate> templates,
  ) {
    final templateInList =
        _templateId != null && templates.any((t) => t.id == _templateId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String?>(
            value: templateInList ? _templateId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Template',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None (custom fields)'),
              ),
              ...templates.map((t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.name),
                  )),
            ],
            onChanged: (value) {
              _templateId = value;
              final tpl = value == null
                  ? null
                  : _findById(templates, (t) => t.id == value);
              _applyTemplate(tpl, allFields);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g. Wedding agbada',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (_rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Pick a template or add fields to start measuring.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ..._rows.map((row) => _ValueRow(
                row: row,
                controller: _controllerFor(row.fieldId),
                onRemove: row.removable ? () => _removeRow(row) : null,
              )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _pickAdHocField(allFields),
              icon: const Icon(Icons.add),
              label: const Text('Add field'),
            ),
          ),
          const SizedBox(height: 12),
          // The dictionary is numbers-only, so this box carries everything
          // that isn't a number — and it prints in the MEASUREMENTS block of
          // the tailor's work order. The helper stays visible while typing;
          // a hint alone would vanish on the first keystroke, which defeats a
          // prompt meant to work as a checklist.
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Slim fit, no break at the ankle. '
                  'Left shoulder drops ~1in.',
              helperText: 'Fit preference, style notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Save changes' : 'Save measurements'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(measurementFieldsProvider);
    final templatesAsync = ref.watch(measurementTemplatesProvider);
    final title = widget.isEditing ? 'Edit measurements' : 'New measurements';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => ref.invalidate(measurementFieldsProvider),
        ),
        data: (fields) => templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => AsyncErrorView(
            error: err,
            onRetry: () async => ref.invalidate(measurementTemplatesProvider),
          ),
          data: (templates) {
            if (!widget.isEditing) {
              return _buildForm(context, fields, templates);
            }
            final setAsync =
                ref.watch(measurementSetByIdProvider(widget.setId!));
            return setAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncErrorView(
                error: err,
                onRetry: () async =>
                    ref.invalidate(measurementSetByIdProvider(widget.setId!)),
              ),
              data: (set) {
                _prefillFromSet(set, fields, templates);
                return _buildForm(context, fields, templates);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.row,
    required this.controller,
    this.onRemove,
  });

  final _RowSpec row;
  final TextEditingController controller;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isNumber = row.valueType == 'number';
    final label = row.isRequired ? '${row.label} *' : row.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: isNumber
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : null,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixText: (row.unit != 'none') ? row.unit : null,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
