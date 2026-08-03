import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/feedback.dart';
import '../data/payment_repository.dart';
import 'money_sheet_parts.dart';

/// Collects a single payment and records it. Returns `true` via
/// `Navigator.pop` on success so the caller can refresh the order + history;
/// stays open and shows the message via a top snackbar on failure.
///
/// **The amount field no longer hard-blocks an over-balance figure.** It used
/// to reject anything above the outstanding balance in the validator, which
/// meant the only thing a shop could do with a client who handed over extra
/// was type a smaller number and lose the record of what actually changed
/// hands. Now an excess opens the typo-or-tip dialog: the money is either a
/// mistake to correct or a gratuity to record, and both are answerable.
class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.orderId,
    required this.maxAmount,
    required this.orderTotal,
    required this.dateFloor,
  });

  final String orderId;

  /// The order's current outstanding balance. Not a hard cap any more — the
  /// ceiling for the *payment* portion, with anything above it routed to the
  /// tip question.
  final double maxAmount;

  /// Used only to decide whether an excess is plausibly a tip. A ₦855,000
  /// "tip" on a ₦95,000 job is a typo with certainty.
  final double orderTotal;

  /// Earliest date this payment may carry — see [paymentFloorFor].
  final DateTime dateFloor;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

/// What the user decided the excess was.
enum _ExcessChoice { typo, tip }

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  String _method = 'cash';
  DateTime? _paidAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default to settling the balance in full — the common case.
    _amountController =
        TextEditingController(text: formatAmount(widget.maxAmount));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Strips the grouping separators the field is pre-filled with, so a user
  /// who doesn't touch the amount doesn't submit `95,000` and fail to parse.
  double? _parseAmount(String? raw) =>
      double.tryParse((raw ?? '').replaceAll(',', '').trim());

  String? _validateAmount(String? raw) {
    final value = _parseAmount(raw);
    if (value == null || value <= 0) return 'Enter an amount greater than 0';
    // No upper bound here on purpose. Over-balance is a question, not an
    // error, and it's asked in _submit.
    return null;
  }

  /// Asks what an over-balance amount was. Returns null if the user backed
  /// out, in which case the sheet stays open with the figure untouched.
  Future<_ExcessChoice?> _askAboutExcess(double excess) async {
    // Above a whole order's value, a "tip" stops being a plausible reading.
    // Offering it there would let one mis-tap mint a phantom gratuity that
    // then has to be explained to whoever reconciles the books.
    final tipPlausible = excess <= widget.orderTotal;

    var choice = _ExcessChoice.typo; // pre-selected, deliberately
    return showDialog<_ExcessChoice>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("That's ${formatNaira(excess)} more than the balance."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The balance on this order is '
                '${formatNaira(widget.maxAmount)}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              RadioListTile<_ExcessChoice>(
                contentPadding: EdgeInsets.zero,
                value: _ExcessChoice.typo,
                groupValue: choice,
                onChanged: (v) => setDialogState(() => choice = v!),
                title: const Text("It's a typo"),
                subtitle: const Text('Let me fix the amount'),
              ),
              if (tipPlausible)
                RadioListTile<_ExcessChoice>(
                  contentPadding: EdgeInsets.zero,
                  value: _ExcessChoice.tip,
                  groupValue: choice,
                  onChanged: (v) => setDialogState(() => choice = v!),
                  title: const Text("It's a tip"),
                  subtitle: Text(
                    'Record ${formatNaira(widget.maxAmount)} as payment '
                    'and ${formatNaira(excess)} as a tip',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, choice),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final entered = _parseAmount(_amountController.text)!;

    var amount = entered;
    var tip = 0.0;

    if (entered > widget.maxAmount + 0.005) {
      final excess = entered - widget.maxAmount;
      final choice = await _askAboutExcess(excess);
      // Backed out, or chose to fix the number: leave the sheet as it is with
      // the figure intact so they can edit rather than retype.
      if (choice != _ExcessChoice.tip || !mounted) return;
      amount = widget.maxAmount;
      tip = excess;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(paymentRepositoryProvider).record(
            widget.orderId,
            amount: amount,
            tipAmount: tip,
            method: _method,
            notes: _notesController.text.trim(),
            paidAt: _paidAt,
          );
      if (mounted) {
        showSuccessSnackbar(
          context,
          tip > 0 ? 'Payment and tip recorded' : 'Payment recorded',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorMessage(context, messageForMoneyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              Text('Record payment',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Outstanding balance: ${formatNaira(widget.maxAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateAmount,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: [
                  for (final m in kPaymentMethods)
                    DropdownMenuItem(
                        value: m, child: Text(paymentMethodLabel(m))),
                ],
                onChanged: _submitting
                    ? null
                    : (v) {
                        if (v != null) setState(() => _method = v);
                      },
              ),
              MoneyDateField(
                value: _paidAt,
                floor: widget.dateFloor,
                enabled: !_submitting,
                onChanged: (v) => setState(() => _paidAt = v),
              ),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Record payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
