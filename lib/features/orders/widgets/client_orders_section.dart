import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../state/client_orders_providers.dart';
import 'order_card.dart';

/// Embeddable "Orders" block for the client detail screen. Lists this
/// client's orders newest-first. Tapping a row opens the order detail;
/// starting a new order for this client is the screen-level "New order"
/// FAB, not a control in this section.
///
/// Rows render with the shared [OrderCard] so an order looks the same
/// whether it's seen from the main Orders tab or from inside a client. The
/// one difference: the card's secondary line carries the order total here
/// (the client is already the context) instead of the client name.
class ClientOrdersSection extends ConsumerWidget {
  const ClientOrdersSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(clientOrdersProvider(clientId));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(
            'Orders',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ordersAsync.when(
          loading: () => _SectionSurface(
            scheme: scheme,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
          ),
          error: (err, _) => _SectionSurface(
            scheme: scheme,
            child: AsyncErrorView(
              error: err,
              compact: true,
              onRetry: () async =>
                  ref.invalidate(clientOrdersProvider(clientId)),
            ),
          ),
          data: (response) {
            final orders = response.results;
            if (orders.isEmpty) {
              return _SectionSurface(
                scheme: scheme,
                child: const _EmptyOrders(),
              );
            }
            // This section shows only the first page; when the client has more
            // orders than that, a "View all" link opens the fully-paginated
            // client orders screen rather than trying to load-more inline.
            final hasMore = response.total > orders.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in orders)
                  OrderCard(
                    orderNumber: order.orderNumber,
                    subtitle: formatNaira(order.totalAmount),
                    dueDate: order.dueDate,
                    paymentStatus: order.paymentStatus,
                    paymentStatusLabel: paymentStatusLabel(order.paymentStatus),
                    status: order.status,
                    statusLabel: orderStatusLabel(order.status),
                    priority: order.priority,
                    onTap: () => context.push('/orders/${order.id}'),
                  ),
                if (hasMore)
                  _ViewAllOrdersButton(
                    clientId: clientId,
                    total: response.total,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Shared card shell for the loading / error / empty states so they read
/// as part of the same section as the order rows below them, instead of
/// borderless content sitting loose on the screen background.
class _SectionSurface extends StatelessWidget {
  const _SectionSurface({required this.scheme, required this.child});

  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.18)),
      ),
      child: child,
    );
  }
}

/// Footer link shown when the section is only a first-page preview of a
/// longer history — opens the fully-paginated client orders screen.
class _ViewAllOrdersButton extends StatelessWidget {
  const _ViewAllOrdersButton({required this.clientId, required this.total});

  final String clientId;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: TextButton(
        onPressed: () => context.push('/clients/$clientId/orders'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View all $total orders'),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 32, color: scheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'No orders yet',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
