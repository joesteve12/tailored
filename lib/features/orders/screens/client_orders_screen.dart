import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/skeleton.dart';
import '../state/client_orders_providers.dart';
import '../widgets/order_card.dart';

/// The full, scroll-to-load-more order history for one client — reached from
/// the "View all" link on the client detail screen's Orders section.
///
/// Deliberately a plain paginated list with no search or filters: those knobs
/// live on the global Orders tab. This screen is just "every order for this
/// client, newest first", scoped through [clientOrdersPagedProvider] so it
/// never touches the bottom-nav tab's filter state.
class ClientOrdersScreen extends ConsumerStatefulWidget {
  const ClientOrdersScreen({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends ConsumerState<ClientOrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      ref
          .read(clientOrdersPagedProvider(widget.clientId).notifier)
          .loadMore()
          .catchError((_) {
        if (!mounted) return;
        showErrorMessage(context, 'Could not load more orders');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(clientOrdersPagedProvider(widget.clientId));
    final scheme = Theme.of(context).colorScheme;

    // The list rows denormalise the client name, so the first loaded order
    // supplies the title without a separate client fetch. Falls back to a
    // generic title before the first page lands (or if the name is absent).
    final orders = listState.valueOrNull?.items ?? const [];
    final clientName =
        orders.isNotEmpty ? (orders.first.clientName?.trim() ?? '') : '';
    final title = clientName.isNotEmpty ? "$clientName's orders" : 'Orders';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: listState.when(
        loading: () => const SkeletonList(
          scrollable: true,
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
          separatorHeight: 10,
          itemBuilder: _orderSkeletonRow,
        ),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref
              .read(clientOrdersPagedProvider(widget.clientId).notifier)
              .refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return _EmptyState(
              onRefresh: () => ref
                  .read(clientOrdersPagedProvider(widget.clientId).notifier)
                  .refresh(),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(clientOrdersPagedProvider(widget.clientId).notifier)
                .refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final order = state.items[index];
                return OrderCard(
                  orderNumber: order.orderNumber,
                  subtitle: formatNaira(order.totalAmount),
                  dueDate: order.dueDate,
                  paymentStatus: order.paymentStatus,
                  paymentStatusLabel: paymentStatusLabel(order.paymentStatus),
                  status: order.status,
                  statusLabel: orderStatusLabel(order.status),
                  priority: order.priority,
                  onTap: () => context.push('/orders/${order.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Loading placeholder for one order row — mirrors [OrderCard]'s shape, same
/// as the Orders tab's skeleton.
Widget _orderSkeletonRow(BuildContext context, int index) => const SkeletonTile(
      hasLeading: false,
      lineCount: 3,
      hasTrailing: true,
      padding: EdgeInsets.fromLTRB(14, 12, 10, 12),
    );

/// Shown only in the edge case where the client's orders vanish between
/// opening this screen and the fetch landing (e.g. all deleted elsewhere) —
/// the "View all" link that leads here is itself gated on there being more
/// orders than the section preview.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: scheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
