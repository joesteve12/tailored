import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/models/user.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../state/order_list_notifier.dart';
import '../widgets/client_picker_sheet.dart';

import '../../../core/widgets/feedback.dart';
/// Status filter chips show whatever statuses the loaded orders actually
/// contain (rendered through [orderStatusLabel]) rather than a hardcoded
/// set — the same don't-guess-the-vocabulary stance the model takes. The
/// priority filter, by contrast, uses the fixed [kPriorities] list since
/// that vocabulary is closed and small.
class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
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
      ref.read(orderListProvider.notifier).loadMore().catchError((_) {
        if (!mounted) return;
        showErrorMessage(context, 'Could not load more orders');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(
      authStateProvider.select((state) => state.valueOrNull),
      (previous, next) {
        if (previous?.id != next?.id) {
          ref.read(orderListProvider.notifier).refresh().catchError((_) {});
        }
      },
    );

    final listState = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.read(orderListProvider.notifier).refresh(),
        ),
        data: (state) {
          final statusOptions = {
            for (final order in state.items) order.status,
          }.toList()
            ..sort();

          return Column(
            children: [
              if (statusOptions.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _chip(
                        label: 'All',
                        selected: state.orderStatus == null,
                        onSelected: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(clearOrderStatus: true),
                      ),
                      for (final status in statusOptions)
                        _chip(
                          label: orderStatusLabel(status),
                          selected: state.orderStatus == status,
                          onSelected: () => ref
                              .read(orderListProvider.notifier)
                              .setFilters(orderStatus: status),
                        ),
                    ],
                  ),
                ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip(
                      label: 'Any priority',
                      selected: state.priority == null,
                      onSelected: () => ref
                          .read(orderListProvider.notifier)
                          .setFilters(clearPriority: true),
                    ),
                    for (final p in kPriorities)
                      _chip(
                        label: priorityLabel(p),
                        selected: state.priority == p,
                        onSelected: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(priority: p),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: state.items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No orders yet.\nCreate one from a client\'s page.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(orderListProvider.notifier).refresh(),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }

                            final order = state.items[index];
                            return ListTile(
                              title: Text(order.orderNumber),
                              subtitle: Text(
                                'Due ${_fmtDate(order.dueDate)} · ${paymentStatusLabel(order.paymentStatus)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (order.priority == 'high' ||
                                      order.priority == 'urgent') ...[
                                    _PriorityBadge(priority: order.priority),
                                    const SizedBox(width: 6),
                                  ],
                                  Chip(
                                    label: Text(orderStatusLabel(order.status)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/orders/${order.id}'),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_orders',
        onPressed: () => _pickClientAndCreateOrder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Future<void> _pickClientAndCreateOrder(BuildContext context) async {
    final clientId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ClientPickerSheet(),
    );
    if (clientId != null && mounted) {
      context.push('/orders/new', extra: clientId);
    }
  }
}

/// A small high/urgent marker on a list tile, tinted from the theme's error
/// role so it reads as "needs attention" without introducing a raw color.
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUrgent = priority == 'urgent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? scheme.errorContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 13,
            color: isUrgent
                ? scheme.onErrorContainer
                : scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 3),
          Text(
            priorityLabel(priority),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isUrgent
                      ? scheme.onErrorContainer
                      : scheme.onTertiaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
