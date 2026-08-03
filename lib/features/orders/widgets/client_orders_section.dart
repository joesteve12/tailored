import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/order_labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/order.dart';
import '../state/client_orders_providers.dart';

/// Embeddable "Orders" block for the client detail screen. Lists this
/// client's orders newest-first, with the same header + action-button
/// pattern the Guests and Measurements sections use. Tapping a row opens
/// the order detail; the icon button starts a new order pre-filled with
/// this client.
///
/// Row styling (status pill colors/icons, payment icon+label, card
/// treatment) intentionally mirrors `_OrderCard` in order_list_screen.dart
/// so an order looks the same whether it's seen from the main Orders tab
/// or from inside a client. The status/payment meta helpers below are a
/// deliberate duplication of that file's — if a third place ever needs the
/// same mapping, pull them into a shared `order_status_meta.dart` instead
/// of copying a third time.
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                tooltip: 'New order',
                onPressed: () => context.push('/orders/new', extra: clientId),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primaryContainer.withOpacity(0.35),
                  foregroundColor: scheme.primary,
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
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
          data: (orders) {
            if (orders.isEmpty) {
              return _SectionSurface(
                scheme: scheme,
                child: const _EmptyOrders(),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _OrderRow(order: orders[i]),
                ],
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

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final due = order.dueDate;
    final overdue = due.isBefore(DateTime.now());
    final dueLabel = '${_shortMonths[due.month - 1]} ${due.day}';
    final total = formatNaira(order.totalAmount);
    final paymentMeta = _paymentMeta(order.paymentStatus, scheme);
    final isElevatedPriority =
        order.priority == 'high' || order.priority == 'urgent';
    final priorityColor =
        isElevatedPriority ? _priorityColor(order.priority, scheme) : null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/orders/${order.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isElevatedPriority)
                  Container(width: 4, color: priorityColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Identity + status: the two things worth scanning first.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                order.orderNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StatusPill(
                              status: order.status,
                              label: orderStatusLabel(order.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Price gets its own line — it's the second most
                        // important fact on the card and was previously
                        // the same visual weight as payment status.
                        Text(
                          total,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // One consistent chip language for all order
                        // metadata, instead of three different text
                        // treatments competing for attention.
                        Row(
                          children: [
                            _MetaChip(
                              icon: paymentMeta.icon,
                              label:
                                  paymentStatusLabel(order.paymentStatus),
                              color: paymentMeta.color,
                            ),
                            const Spacer(),
                            _MetaChip(
                              icon: Icons.event_outlined,
                              label: 'Due $dueLabel',
                              color: overdue
                                  ? const Color(0xFFEA580C)
                                  : scheme.onSurfaceVariant,
                              emphasized: overdue,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right,
                                size: 20, color: scheme.outlineVariant),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored pill used for payment status, due date, and priority —
/// one shared visual language for order metadata instead of three
/// different treatments (plain icon+text x2, standalone tag x1).
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(emphasized ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Color+icon coded pill for the known status enum (pending, in progress,
/// on hold, delivered, cancelled). Falls back to a neutral outlined pill
/// for any status value outside that set, so new/unrecognized statuses
/// degrade gracefully instead of guessing a color for them. Kept in sync
/// with `_StatusPill` in order_list_screen.dart.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = _statusMeta(status, scheme);

    if (meta.isFallback) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 12, color: meta.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: meta.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta(this.color, this.icon, {this.isFallback = false});
  final Color color;
  final IconData icon;
  final bool isFallback;
}

/// Maps the known status enum to a color + icon, matching normalization
/// (lowercased, separators stripped) and palette used in
/// order_list_screen.dart's `_statusMeta`.
_StatusMeta _statusMeta(String status, ColorScheme scheme) {
  final key = status.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (key) {
    case 'pending':
      return _StatusMeta(const Color(0xFFB8860B), Icons.schedule_rounded);
    case 'inprogress':
      return _StatusMeta(const Color(0xFF2563EB), Icons.autorenew_rounded);
    case 'onhold':
      return _StatusMeta(const Color(0xFF7C3AED), Icons.pause_circle_rounded);
    case 'delivered':
      return _StatusMeta(const Color(0xFF16A34A), Icons.check_circle_rounded);
    case 'cancelled':
    case 'canceled':
      return _StatusMeta(scheme.error, Icons.cancel_rounded);
    default:
      return _StatusMeta(scheme.onSurfaceVariant, Icons.circle,
          isFallback: true);
  }
}

/// Maps the payment status to a color + icon, mirroring `_paymentMeta` in
/// order_list_screen.dart. Unpaid stays neutral — it's the default state,
/// not a problem state.
class _PaymentMeta {
  const _PaymentMeta(this.color, this.icon);
  final Color color;
  final IconData icon;
}

_PaymentMeta _paymentMeta(String paymentStatus, ColorScheme scheme) {
  final key = paymentStatus.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (key) {
    case 'paid':
      return const _PaymentMeta(Color(0xFF16A34A), Icons.check_circle_outline);
    case 'partial':
      return const _PaymentMeta(Color(0xFFB8860B), Icons.incomplete_circle);
    case 'unpaid':
      return _PaymentMeta(scheme.onSurfaceVariant, Icons.payments_outlined);
    default:
      return _PaymentMeta(scheme.onSurfaceVariant, Icons.payments_outlined);
  }
}

/// Color for the priority accent bar and chip — mirrors `_priorityColor`
/// in order_list_screen.dart. Only 'high' and 'urgent' are ever elevated
/// (see `isElevatedPriority` in `_OrderRow`), so this is only ever called
/// for those two values.
Color _priorityColor(String priority, ColorScheme scheme) {
  switch (priority) {
    case 'urgent':
      return const Color(0xFFEA580C);
    case 'high':
      return scheme.error;
    default:
      return scheme.onSurfaceVariant;
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
