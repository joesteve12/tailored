import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/order_addon.dart';

/// Collects a chargeable extra. Returns an [AddonDraft] via `Navigator.pop`,
/// or null if dismissed — the caller owns the mutation so this sheet stays a
/// pure form and can serve both add and edit.
///
/// Pass [existing] to edit. The submit label and title follow from it.
class AddonFormSheet extends StatefulWidget {
  const AddonFormSheet({super.key, this.existing});

  final OrderAddon? existing;

  @override
  State<AddonFormSheet> createState() => _AddonFormSheetState();
}

/// What the sheet collected. Deliberately not an [OrderAddon] — that mirrors
/// a server response and carries an id and a createdAt this form has no
/// business inventing.
class AddonDraft {
  const AddonDraft({
    required this.label,
    required this.amount,
    required this.quantity,
    required this.notes,
  });

  final String label;
  final double amount;
  final int quantity;
  final String notes;
}

/// Common charges, offered as chips. Typing "Delivery" by hand on every order
/// invites "delivery", "Delivery ", and "Deliv" — three labels the owner then
/// can't group when scanning what they charge for.
const List<String> _commonLabels = [
  'Delivery',
  'Rush fee',
  'Embroidery',
  'Extra lining',
  'Home visit',
];

class _AddonFormSheetState extends State<AddonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : _plain(existing.amount),
    );
    _quantityController =
        TextEditingController(text: (existing?.quantity ?? 1).toString());
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateLabel(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Give this charge a name';
    if (value.length > 100) return 'Keep it under 100 characters';
    return null;
  }

  /// Zero and negatives are blocked here as well as by the backend. A
  /// negative addon would be a second discount mechanism running alongside
  /// the real one with none of the same caps, and the two would disagree
  /// within a week. Discounts go through the discount field.
  String? _validateAmount(String? raw) {
    final value = double.tryParse((raw ?? '').replaceAll(',', '').trim());
    if (value == null || value <= 0) return 'Enter an amount greater than 0';
    return null;
  }

  String? _validateQuantity(String? raw) {
    final value = int.tryParse((raw ?? '').trim());
    if (value == null || value < 1) return 'At least 1';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AddonDraft(
        label: _labelController.text.trim(),
        amount: double.parse(
            _amountController.text.replaceAll(',', '').trim()),
        quantity: int.parse(_quantityController.text.trim()),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? 'Edit charge' : 'Add a charge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Delivery, a rush fee, embroidery — anything billed that '
                "isn't an outfit.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appTokens.mutedForeground,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Charge'),
                validator: _validateLabel,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in _commonLabels)
                    ActionChip(
                      label: Text(label),
                      onPressed: () {
                        _labelController.text = label;
                        _labelController.selection =
                            TextSelection.collapsed(offset: label.length);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateAmount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      keyboardType: TextInputType.number,
                      validator: _validateQuantity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Save charge' : 'Add charge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
