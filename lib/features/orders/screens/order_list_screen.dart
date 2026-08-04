import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/auth/models/user.dart';
import '../../../core/theme/app_tokens.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Orders'),
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
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
              _FilterSection(
                statusOptions: statusOptions,
                selectedStatus: state.orderStatus,
                selectedPriority: state.priority,
                onStatusSelected: (status) {
                  if (status == null) {
                    ref
                        .read(orderListProvider.notifier)
                        .setFilters(clearOrderStatus: true);
                  } else {
                    ref
                        .read(orderListProvider.notifier)
                        .setFilters(orderStatus: status);
                  }
                },
                onPrioritySelected: (priority) {
                  if (priority == null) {
                    ref
                        .read(orderListProvider.notifier)
                        .setFilters(clearPriority: true);
                  } else {
                    ref
                        .read(orderListProvider.notifier)
                        .setFilters(priority: priority);
                  }
                },
              ),
              Expanded(
                child: state.items.isEmpty
                    ? _EmptyState(
                        onRefresh: () =>
                            ref.read(orderListProvider.notifier).refresh(),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(orderListProvider.notifier).refresh(),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }

                            final order = state.items[index];
                            return _OrderCard(
                              orderNumber: order.orderNumber,
                              clientName: order.clientName,
                              dueDate: order.dueDate,
                              paymentStatus: order.paymentStatus,
                              paymentStatusLabel:
                                  paymentStatusLabel(order.paymentStatus),
                              status: order.status,
                              statusLabel: orderStatusLabel(order.status),
                              priority: order.priority,
                              onTap: () =>
                                  context.push('/orders/${order.id}'),
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

/// Both filter rows, grouped in one lightly-tinted band so they read as a
/// single "filters" control surface rather than floating chip strips.
class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.statusOptions,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.onStatusSelected,
    required this.onPrioritySelected,
  });

  final List<String> statusOptions;
  final String? selectedStatus;
  final String? selectedPriority;
  final ValueChanged<String?> onStatusSelected;
  final ValueChanged<String?> onPrioritySelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusOptions.isNotEmpty) ...[
            _FilterRow(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selectedStatus == null,
                  onTap: () => onStatusSelected(null),
                ),
                for (final status in statusOptions)
                  _FilterChip(
                    label: orderStatusLabel(status),
                    selected: selectedStatus == status,
                    onTap: () => onStatusSelected(status),
                    dotColor: _statusMeta(status, scheme).color,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _FilterRow(
            children: [
              _FilterChip(
                label: 'Any priority',
                selected: selectedPriority == null,
                onTap: () => onPrioritySelected(null),
              ),
              for (final p in kPriorities)
                _FilterChip(
                  label: priorityLabel(p),
                  selected: selectedPriority == p,
                  onTap: () => onPrioritySelected(p),
                  dotColor: _priorityColor(p, scheme),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          selected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderNumber,
    required this.clientName,
    required this.dueDate,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.onTap,
  });

  final String orderNumber;
  final String? clientName;
  final DateTime dueDate;
  final String paymentStatus;
  final String paymentStatusLabel;
  final String status;
  final String statusLabel;
  final String priority;
  final VoidCallback onTap;

  bool get _isElevatedPriority => priority == 'high' || priority == 'urgent';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = dueDate.isBefore(DateTime.now());
    final paymentMeta = _paymentMeta(paymentStatus, scheme);
    // The client name rides on each order in the list response, so the card
    // renders it directly — no per-row client fetch. A null/blank name (older
    // rows, or a client since removed) just hides the line.
    final name = clientName?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (_isElevatedPriority) ...[
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _priorityColor(priority, scheme),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              orderNumber,
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
                          _StatusPill(status: status, label: statusLabel),
                        ],
                      ),
                      if (name.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.event_outlined,
                              size: 14,
                              color: overdue
                                  ? StatusColors.urgent
                                  : scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${_fmtDate(dueDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: overdue
                                  ? StatusColors.urgent
                                  : scheme.onSurfaceVariant,
                              fontWeight:
                                  overdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(paymentMeta.icon,
                                    size: 14, color: paymentMeta.color),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    paymentStatusLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: paymentMeta.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right,
                                    size: 20, color: scheme.outlineVariant),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Color+icon coded pill for the known status enum (pending, in progress,
/// on hold, delivered, cancelled). Falls back to a neutral outlined pill
/// for any status value outside that set, so new/unrecognized statuses
/// degrade gracefully instead of guessing a color for them.
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

/// Maps the known status enum to a color + icon. Matching is done on a
/// normalized form of the raw status value (lowercased, separators
/// stripped) so it doesn't matter whether the backend sends
/// "in_progress", "in-progress", or "In Progress". Anything outside the
/// known set returns a fallback so unrecognized statuses stay neutral
/// rather than being assigned an arbitrary color.
_StatusMeta _statusMeta(String status, ColorScheme scheme) {
  final key = status.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (key) {
    case 'pending':
      return const _StatusMeta(
          StatusColors.orderPending, Icons.schedule_rounded);
    case 'inprogress':
      return const _StatusMeta(
          StatusColors.orderInProgress, Icons.autorenew_rounded);
    case 'onhold':
      return const _StatusMeta(
          StatusColors.orderOnHold, Icons.pause_circle_rounded);
    case 'delivered':
      return const _StatusMeta(
          StatusColors.orderDelivered, Icons.check_circle_rounded);
    case 'cancelled':
    case 'canceled':
      return _StatusMeta(StatusColors.cancelled(scheme), Icons.cancel_rounded);
    default:
      return _StatusMeta(scheme.onSurfaceVariant, Icons.circle,
          isFallback: true);
  }
}

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
                  const SizedBox(height: 4),
                  Text(
                    "Create one from a client's page.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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

/// Maps the payment status to a color + icon, same normalization approach
/// as [_statusMeta] (lowercased, separators stripped) so "Paid", "PAID",
/// etc. all match the backend's paid/partial/unpaid enum. Unpaid is left
/// at the neutral color — it's the default/expected state, not a problem
/// state, so it doesn't need to draw the eye the way partial or paid do.
/// Unrecognized values fall back to the same neutral icon rather than
/// guessing a color.
class _PaymentMeta {
  const _PaymentMeta(this.color, this.icon);
  final Color color;
  final IconData icon;
}

_PaymentMeta _paymentMeta(String paymentStatus, ColorScheme scheme) {
  final key = paymentStatus.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (key) {
    case 'paid':
      return const _PaymentMeta(
          StatusColors.paymentPaid, Icons.check_circle_outline);
    case 'partial':
      return const _PaymentMeta(
          StatusColors.paymentPartial, Icons.incomplete_circle);
    case 'unpaid':
      return _PaymentMeta(scheme.onSurfaceVariant, Icons.payments_outlined);
    default:
      return _PaymentMeta(scheme.onSurfaceVariant, Icons.payments_outlined);
  }
}

Color _priorityColor(String priority, ColorScheme scheme) {
  switch (priority) {
    case 'urgent':
      return StatusColors.urgent;
    case 'high':
      return StatusColors.priorityHigh(scheme);
    default:
      return scheme.onSurfaceVariant;
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
