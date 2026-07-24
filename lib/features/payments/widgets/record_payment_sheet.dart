import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/utils/errors.dart';
import '../../../core/widgets/feedback.dart';
import '../data/payment_repository.dart';

/// Collects a single payment and records it. Returns `true` via
/// `Navigator.pop` on success so the caller can refresh the order + history;
/// stays open and shows the message via a top snackbar on failure.
///
/// The amount is capped client-side at the outstanding balance (the backend
/// also rejects overpayment with a 400 whose detail names the balance — that
/// message is surfaced verbatim if the client-side check is ever raced).
class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.orderId,
    required this.maxAmount,
  });

  final String orderId;

  /// The order's current outstanding balance — the most that can be paid now.
  final double maxAmount;

  @override
  ConsumerState<RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  String _method = 'cash';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default to paying off the balance in full — the common case.
    _amountController =
        TextEditingController(text: widget.maxAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? raw) {
    final v = double.tryParse(raw?.trim() ?? '');
    if (v == null || v <= 0) return 'Enter an amount greater than 0';
    // Small epsilon so a full-balance payment typed back in isn't rejected
    // by float rounding.
    if (v > widget.maxAmount + 0.005) {
      return 'At most ${widget.maxAmount.toStringAsFixed(2)} (the balance)';
    }
    return null;
  }

  /// Prefer the backend's 400 "detail" string over a generic error
  /// description. That specific message names the actual outstanding
  /// balance, which is far more useful when a raced overpayment happens
  /// than the generic "Something went wrong" fallback.
  String _messageFor(Object e) {
    if (e is DioException &&
        e.response?.statusCode == 400 &&
        e.response?.data is Map &&
        (e.response!.data as Map)['detail'] is String) {
      return (e.response!.data as Map)['detail'] as String;
    }
    return describeError(e);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(paymentRepositoryProvider).record(
            widget.orderId,
            amount: double.parse(_amountController.text.trim()),
            method: _method,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Payment recorded');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorMessage(context, _messageFor(e));
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
                'Outstanding balance: ${widget.maxAmount.toStringAsFixed(2)}',
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
                    DropdownMenuItem(value: m, child: Text(paymentMethodLabel(m))),
                ],
                onChanged: _submitting
                    ? null
                    : (v) {
                        if (v != null) setState(() => _method = v);
                      },
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
