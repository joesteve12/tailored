import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/payment_labels.dart';
import '../../orders/models/order.dart';
import '../../orders/state/order_detail_notifier.dart';
import '../../orders/state/order_list_notifier.dart';
import '../../orders/state/status_events_providers.dart';
import '../state/payment_providers.dart';
import 'record_payment_sheet.dart';

/// The order's money summary — subtotal / discount / total / paid /
/// balance, plus the "Record payment" action. The payment *history* (and
/// the void action) used to live here too; as of Phase 1 they've moved to
/// the order-detail Activity section so this widget stays a clean, compact
/// money-facts card.
///
/// This still owns the "record a payment" flow because that action *is*
/// scoped to the money summary — you record against the balance shown
/// right above the button. After a record it refreshes the same three
/// providers the void action refreshes (payment log, order detail, orders
/// list), which happens to be exactly what the Activity section needs to
/// pick up the new row.
class PaymentSection extends ConsumerStatefulWidget {
  const PaymentSection({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<PaymentSection> {
  Order get order => widget.order;

  void _refreshAfterMutation() {
    // Kept in sync with the void action in the Activity section — record
    // and void touch the same three provider surfaces. Status events are
    // untouched by payment changes; no need to invalidate that one.
    ref.invalidate(paymentsProvider(order.id));
    ref.read(orderDetailProvider(order.id).notifier).refresh();
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  Future<void> _recordPayment() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecordPaymentSheet(
        orderId: order.id,
        maxAmount: order.balanceDue,
      ),
    );
    if (ok == true) _refreshAfterMutation();
  }

  @override
  Widget build(BuildContext context) {
    // Allow recording while there's a balance, except on a cancelled order.
    final canRecord = order.status != 'cancelled' && order.balanceDue > 0.005;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  paymentStatusLabel(order.paymentStatus),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(context, 'Subtotal', order.subtotal.toStringAsFixed(2)),
            if (order.hasDiscount)
              _row(
                context,
                'Discount${order.discountType == 'percentage' ? ' (${_trimZeros(order.discountValue)}%)' : ''}',
                '-${order.discountAmount.toStringAsFixed(2)}',
              ),
            const Divider(height: 16),
            _row(context, 'Total', order.totalAmount.toStringAsFixed(2),
                emphasize: true),
            _row(context, 'Paid', order.amountPaid.toStringAsFixed(2)),
            _row(context, 'Balance due', order.balanceDue.toStringAsFixed(2)),
            if (canRecord) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Record payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Renders a discount value without trailing ".0" (10 not 10.0; 12.5 stays).
String _trimZeros(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}
