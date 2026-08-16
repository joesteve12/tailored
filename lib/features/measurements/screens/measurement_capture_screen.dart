import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_error_view.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../models/measurement_set.dart';
import '../models/measurement_template.dart';
import '../state/measurement_dictionary_providers.dart';
import '../state/measurement_list_notifier.dart';
import '../state/measurement_set_providers.dart';

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
  // Name of the currently selected template, kept so a blank label can default
  // to it on save. A set is identified by its label; the template is only a
  // prefill convenience, so "no label" falls back to the template's name.
  String? _templateName;
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
    _templateName = template?.name;
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
          // A template is prefill, not a lock: its optional fields can be
          // removed like any ad-hoc field. Only *required* fields stay pinned —
          // those the shop insists on, and the backend enforces on create.
          removable: !tf.isRequired,
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
        // The backend stores every measurement as NUMERIC(6, 2) — magnitude
        // under 10,000 — regardless of field or unit. Past that it doesn't
        // reject the value, it 500s (a raw Postgres overflow reaching the app
        // as an unhandled exception). A mistyped extra digit is the realistic
        // way this happens, so catch it here with a message the user can act
        // on instead of a failed save and a stack trace in the server log.
        if (v.abs() >= 10000) {
          if (mounted) {
            showErrorMessage(
              context,
              '${row.label}: that value looks too large — check for a typo',
            );
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
      // A set is identified by its label. If the user left it blank, fall back
      // to the selected template's name so the list still shows something
      // meaningful (e.g. "Agbada") rather than just a date.
      final typedLabel = _labelController.text.trim();
      final label = typedLabel.isNotEmpty ? typedLabel : (_templateName ?? '');
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Label and template are one control now: type a name for the set, or
          // pick a template — which both prefills the fields and fills the name.
          // (They served near-identical purposes as two separate inputs.) The
          // name stays freely editable after a template is chosen, and a blank
          // name falls back to the template's on save.
          DropdownMenu<String>(
            controller: _labelController,
            expandedInsets: EdgeInsets.zero,
            requestFocusOnTap: true,
            enableFilter: false,
            enableSearch: false,
            label: const Text('Name'),
            hintText: 'Name this set, or pick a template',
            leadingIcon: const Icon(Icons.straighten),
            dropdownMenuEntries: [
              for (final t in templates)
                DropdownMenuEntry<String>(value: t.id, label: t.name),
            ],
            onSelected: (id) {
              _templateId = id;
              final tpl =
                  id == null ? null : _findById(templates, (t) => t.id == id);
              _applyTemplate(tpl, allFields);
            },
          ),
          const SizedBox(height: 20),
          if (_rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Fields',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.appTokens.mutedForeground,
                    ),
              ),
            ),
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

  /// Display form of a unit for the field's suffix — "inch" reads better as
  /// the actual symbol than spelled out next to a number.
  static String _unitSuffix(String unit) {
    switch (unit) {
      case 'inch':
        return '″';
      case 'none':
        return '';
      default:
        return unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final isNumber = row.valueType == 'number';
    final unitSuffix = _unitSuffix(row.unit);

    // The field name reads like a line on a measurement sheet; the value is a
    // compact filled pill on the right with the unit trailing it. This suits
    // quick number entry far better than a column of full-width outlined boxes.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: row.label,
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  if (row.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isNumber ? 100 : 150,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: isNumber
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : null,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: tokens.inputBackground,
                hintText: isNumber ? '0' : null,
                // A fixed-width suffix slot, not suffixText: suffixText sizes
                // itself to each unit's glyph width, so "cm" (2 chars) and the
                // inch mark "″" (1 char) push the number to different x
                // positions per row. Pinning the slot width — reserved even for
                // unitless fields — keeps every number's right edge, and every
                // unit, in the same column top to bottom. suffixIcon (unlike a
                // manually-toggled overlay) always renders, focused or not.
                suffixIcon: SizedBox(
                  width: 30,
                  child: Text(
                    unitSuffix,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.mutedForeground,
                        ),
                  ),
                ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 30, minHeight: 0),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Fixed-width action slot. Without it, the differing widths of the
          // remove button, the lock icon and empty space would each shift the
          // value pill to a slightly different x — the rows would read as
          // crooked. A fixed slot keeps every pill aligned regardless of what
          // (if anything) sits in the action position.
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Center(
              child: onRemove != null
                  ? IconButton(
                      tooltip: 'Remove',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onRemove,
                    )
                  // A required field can't be removed; a small lock in the
                  // action slot explains the absence rather than leaving a gap.
                  : row.isRequired
                      ? Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: tokens.mutedForeground,
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
