import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/order.dart';
import '../state/client_orders_providers.dart';

/// Embeddable "Orders" block for the client detail screen. Lists this
/// client's orders newest-first, with the same header + action-button
/// pattern the Guests and Measurements sections use. Tapping a row opens
/// the order detail; the icon button starts a new order pre-filled with
/// this client.
class ClientOrdersSection extends ConsumerWidget {
  const ClientOrdersSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(clientOrdersProvider(clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Orders', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'New order',
              onPressed: () => context.push('/orders/new', extra: clientId),
            ),
          ],
        ),
        ordersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => AsyncErrorView(
            error: err,
            compact: true,
            onRetry: () async => ref.invalidate(clientOrdersProvider(clientId)),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No orders yet'),
              );
            }
            return Column(
              children: [for (final o in orders) _OrderRow(order: o)],
            );
          },
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final due = order.dueDate;
    final dueLabel = '${due.day.toString().padLeft(2, '0')}/'
        '${due.month.toString().padLeft(2, '0')}/${due.year}';
    final total = order.totalAmount.toStringAsFixed(0);
    final paid = order.paymentStatus;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/orders/${order.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(order.orderNumber,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(width: 8),
                      _StatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due $dueLabel  ·  ₦$total  ·  ${paymentStatusLabel(paid)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        orderStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
