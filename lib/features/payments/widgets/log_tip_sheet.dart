import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/feedback.dart';
import '../data/payment_repository.dart';
import 'money_sheet_parts.dart';

/// Records a tip on its own — the client collects, is delighted, and hands
/// over a dash. Submits `amount: 0, tipAmount: entered`.
///
/// This is why the sheet exists separately from [RecordPaymentSheet]: the
/// main use case is a **fully paid** order, where there is no balance left to
/// attach a tip to and the "Record payment" button isn't even shown. It's
/// also available on an overpaid one, since a client who was owed a small
/// refund and waved it away is exactly the situation a tip records.
///
/// A tip never touches `totalAmount`, `amountPaid` or `paymentStatus`. The
/// copy says so out loud, because the one thing an operator will assume is
/// that money entered here reduces what's owed.
class LogTipSheet extends ConsumerStatefulWidget {
  const LogTipSheet({
    super.key,
    required this.orderId,
    required this.orderTotal,
    required this.dateFloor,
  });

  final String orderId;

  /// The backend caps a tip at the order total — a tip larger than the whole
  /// job is a mistyped amount far more often than it is generosity.
  final double orderTotal;

  final DateTime dateFloor;

  @override
  ConsumerState<LogTipSheet> createState() => _LogTipSheetState();
}

class _LogTipSheetState extends ConsumerState<LogTipSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _method = 'cash';
  DateTime? _paidAt;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseAmount(String? raw) =>
      double.tryParse((raw ?? '').replaceAll(',', '').trim());

  String? _validateAmount(String? raw) {
    final value = _parseAmount(raw);
    if (value == null || value <= 0) return 'Enter an amount greater than 0';
    if (value > widget.orderTotal + 0.005) {
      return "That's more than the whole order — check the amount";
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(paymentRepositoryProvider).record(
            widget.orderId,
            amount: 0,
            tipAmount: _parseAmount(_amountController.text)!,
            method: _method,
            notes: _notesController.text.trim(),
            paidAt: _paidAt,
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Tip recorded');
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
    final scheme = Theme.of(context).colorScheme;

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
              Text('Log a tip', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                "A tip is recorded separately and doesn't change what's owed.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Tip amount'),
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
              FilledButton.tonal(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log tip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
