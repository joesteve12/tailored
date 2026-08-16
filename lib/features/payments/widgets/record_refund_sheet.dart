import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/feedback.dart';
import '../data/payment_repository.dart';
import 'money_sheet_parts.dart';

/// Records money going back **out** to the client. Mirrors
/// [RecordPaymentSheet] in shape, and is deliberately styled to be
/// unmistakable from it — an operator moving fast should never confuse the
/// two, because one of them reduces what the client owes and the other hands
/// cash across the counter.
///
/// Available on cancelled orders, unlike recording a payment. Refunding a
/// deposit on a cancellation is the single most common refund a tailor
/// issues; if the sheet were blocked there the shop would have nowhere to
/// record the money at all.
class RecordRefundSheet extends ConsumerStatefulWidget {
  const RecordRefundSheet({
    super.key,
    required this.orderId,
    required this.maxAmount,
    required this.dateFloor,
    this.initialAmount,
  });

  final String orderId;

  /// The refundable figure — the order's net `amountPaid`. The backend
  /// refuses more than was ever received and names this number in the 400.
  final double maxAmount;

  final DateTime dateFloor;

  /// Pre-fills the amount. Used when the sheet is opened from the
  /// "Log a refund instead" branch of the delete-payment dialog, so the
  /// operator doesn't retype a figure they were just looking at.
  final double? initialAmount;

  @override
  ConsumerState<RecordRefundSheet> createState() => _RecordRefundSheetState();
}

class _RecordRefundSheetState extends ConsumerState<RecordRefundSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _method = 'cash';
  DateTime? _paidAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    _amountController = TextEditingController(
      text: initial == null ? '' : formatAmount(initial),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseAmount(String? raw) =>
      double.tryParse((raw ?? '').replaceAll(',', '').trim());

  String? _validateAmount(String? raw) {
    final value = _parseAmount(raw);
    if (value == null || value <= 0) return 'Enter an amount greater than 0';
    if (value > widget.maxAmount + 0.005) {
      return 'At most ${formatNaira(widget.maxAmount)} was received';
    }
    return null;
  }

  /// Blocked client-side as well as server-side. "Why did money go back out"
  /// is the one question this record exists to answer, and it's much easier
  /// to answer now than in six months when someone queries the figure.
  String? _validateReason(String? raw) {
    if ((raw ?? '').trim().isEmpty) return 'Give a reason for the refund';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(paymentRepositoryProvider).refund(
            widget.orderId,
            amount: _parseAmount(_amountController.text)!,
            method: _method,
            reason: _reasonController.text.trim(),
            notes: _notesController.text.trim(),
            paidAt: _paidAt,
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Refund recorded');
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
              Row(
                children: [
                  Icon(Icons.undo, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Refund to client',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Money leaving the shop. '
                'Received so far: ${formatNaira(widget.maxAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appTokens.mutedForeground,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Refund amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateAmount,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Order cancelled, fabric flaw, overpayment…',
                ),
                validator: _validateReason,
                maxLines: 2,
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
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Record refund'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
