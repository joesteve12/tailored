import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_field.dart';
import '../state/dictionary_admin_notifiers.dart';
import '../utils/dictionary_errors.dart';

/// Units a field can be measured in. Nigerian tailors work in inches, so that's
/// the default. 'none' covers counts and other unitless numbers.
const _units = <String, String>{
  'inch': 'Inches',
  'cm': 'Centimetres',
  'none': 'No unit',
};

/// Create or edit one entry in the shop's measurement dictionary. Pass
/// [fieldId] to edit; omit it to create.
///
/// The field's `key` (the backend's stable machine name, unique per shop,
/// frozen at creation) is deliberately invisible here. It's derived from the
/// label on create — the same normalisation the backend applies — and never
/// shown or edited afterwards. Owners think in labels; the key is a
/// data-integrity device, not a feature. Duplicates are caught client-side
/// against the loaded dictionary before submitting, with the backend's
/// unique constraint as the net for anything stale.
///
/// New fields are always numbers. Non-numeric instructions — fit preference,
/// style, body notes — go in the measurement set's `notes` box, which prints on
/// the tailor's work order. Older shops may still hold text fields from the
/// original seed; those are shown read-only rather than hidden, so they can be
/// recognised and archived.
class MeasurementFieldFormScreen extends ConsumerStatefulWidget {
  const MeasurementFieldFormScreen({super.key, this.fieldId});

  final String? fieldId;

  bool get isEditing => fieldId != null;

  @override
  ConsumerState<MeasurementFieldFormScreen> createState() =>
      _MeasurementFieldFormScreenState();
}

class _MeasurementFieldFormScreenState
    extends ConsumerState<MeasurementFieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _unit = 'inch';
  bool _isArchived = false;
  String _valueType = 'number';

  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Mirrors the backend's `normalize_label_to_key` so the client-side
  /// duplicate check agrees with the server (which is authoritative; this is
  /// just instant feedback). Two visibly different labels can normalise the
  /// same ("Chest round" / "Chest (round)") — exactly the near-duplicate an
  /// owner wants caught. Unicode-aware for the same reason the backend is:
  /// Yoruba/Igbo/Hausa labels ("Àyà", "Ìbàdí") must survive as themselves,
  /// not collapse into shared ASCII stubs. `\p{M}` keeps combining marks so
  /// decomposed input normalises like precomposed.
  static String _normalizeKey(String raw) {
    final lowered = raw.trim().toLowerCase();
    final letterOrMark = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);
    final buffer = StringBuffer();
    for (final ch in lowered.characters) {
      if (letterOrMark.hasMatch(ch)) {
        buffer.write(ch);
      } else if (ch == ' ' || ch == '_' || ch == '-' || ch == '/') {
        buffer.write('_');
      }
      // Everything else (punctuation, parentheses, emoji) is dropped.
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _prefill(MeasurementField field) {
    if (_prefilled) return;
    _labelController.text = field.label;
    _descriptionController.text = field.description ?? '';
    _unit = field.unit;
    _isArchived = field.isArchived;
    _valueType = field.valueType;
    _prefilled = true;
  }

  /// The label an existing field would clash with, or null if the coast is
  /// clear. Keys are kept in sync with labels server-side, so comparing
  /// derived keys IS comparing normalised labels. Checked against whatever the
  /// admin list has loaded — instant and free, but best-effort: the list may
  /// be filtered to active-only, and it can be stale. The backend (with its
  /// own owner-facing message) is the real guarantee; this just catches the
  /// common case before a round trip. Self is excluded so re-saving a field
  /// under its own name doesn't collide with itself.
  String? _duplicateLabel(String key) {
    final loaded = ref.read(fieldAdminListProvider).valueOrNull;
    if (loaded == null) return null;
    for (final f in loaded) {
      if (f.id == widget.fieldId) continue;
      if (f.key == key) return f.label;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final label = _labelController.text.trim();
    final derivedKey = _normalizeKey(label);

    // Renames get the same guards as creates: the backend re-derives the key
    // from the new label, so renaming INTO an existing name is a collision
    // too. (A rename also FREES the old name — the key follows the label.)
    if (derivedKey.isEmpty) {
      // A label of pure punctuation/emoji normalises to nothing; catch it here
      // with a human message instead of a validator's.
      showErrorMessage(context, 'Use letters or numbers in the name');
      return;
    }
    final clash = _duplicateLabel(derivedKey);
    if (clash != null) {
      showErrorMessage(context, "You already have a field called '$clash'");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(measurementRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateField(
          widget.fieldId!,
          label: label,
          unit: _unit,
          description: _descriptionController.text.trim(),
          isArchived: _isArchived,
        );
      } else {
        await repo.createField(
          label: label,
          unit: _unit,
          description: _descriptionController.text.trim(),
        );
      }
      invalidateMeasurementDictionary(ref);
      await ref.read(fieldAdminListProvider.notifier).refresh();
      if (!mounted) return;
      showSuccessSnackbar(
        context,
        widget.isEditing ? 'Field saved' : 'Field added',
      );
      context.pop();
    } catch (err) {
      if (mounted) {
        // Duplicate keys and the value-type guard both come back as 400s whose
        // message is the whole point — show it, don't flatten it.
        showErrorMessage(context, describeDictionaryError(err));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final usage = ref.read(fieldTemplateUsageProvider).valueOrNull;
    final templates = usage?[widget.fieldId!] ?? const <String>[];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this field?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deleting removes the field entirely. If any measurement has ever '
              'been recorded against it, the delete will be refused — archive it '
              'instead.',
            ),
            if (templates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'It will also be removed from ${templates.length} '
                'template${templates.length == 1 ? '' : 's'}: '
                '${templates.join(', ')}.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ],
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
      await ref.read(measurementRepositoryProvider).deleteField(widget.fieldId!);
      invalidateMeasurementDictionary(ref);
      await ref.read(fieldAdminListProvider.notifier).refresh();
      if (!mounted) return;
      showSuccessSnackbar(context, 'Field deleted');
      context.pop();
    } catch (err) {
      if (mounted) showErrorMessage(context, describeDictionaryError(err));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return _buildScaffold(context);

    final fieldAsync = ref.watch(fieldByIdProvider(widget.fieldId!));
    return fieldAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit field')),
        body: AsyncErrorView(
          error: err,
          onRetry: () async => ref.invalidate(fieldByIdProvider(widget.fieldId!)),
        ),
      ),
      data: (field) {
        _prefill(field);
        return _buildScaffold(context);
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final usage = ref.watch(fieldTemplateUsageProvider).valueOrNull;
    final templates =
        widget.isEditing ? (usage?[widget.fieldId!] ?? const <String>[]) : const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit field' : 'New field'),
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
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Agbada length',
                helperText: 'What the tailor sees on the form and the work order',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a label' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final entry in _units.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            // Only surfaces for fields created before the dictionary went
            // numbers-only. Read-only: switching the type of a field that has
            // captured values would strand them in the wrong column, and the
            // backend refuses it anyway.
            if (widget.isEditing && _valueType == 'text') ...[
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Value type',
                  border: OutlineInputBorder(),
                  helperText:
                      'A text field from an earlier version. New fields are numbers — '
                      'use the notes box on a measurement for anything written.',
                ),
                child: const Text('Text'),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Measure from the shoulder seam to the hem',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isArchived,
                title: const Text('Archived'),
                subtitle: const Text(
                  'Hidden from new measurements and templates. Everything already '
                  'recorded against it stays exactly as it is.',
                ),
                onChanged: (v) => setState(() => _isArchived = v),
              ),
              if (templates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Used in: ${templates.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appTokens.mutedForeground,
                        ),
                  ),
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
                  : Text(widget.isEditing ? 'Save changes' : 'Add field'),
            ),
          ],
        ),
      ),
    );
  }
}
