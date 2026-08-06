import 'dart:async';

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
import '../state/order_list_state.dart';
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
    // Drives the filter icon's badge and the sheet even while a refetch is in
    // flight — copyWithPrevious keeps the last state visible during loading.
    final currentState = listState.valueOrNull;
    final activeCount = currentState == null
        ? 0
        : (currentState.orderStatus != null ? 1 : 0) +
            (currentState.priority != null ? 1 : 0);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        // Title, search field and filter icon share one row; the search
        // field expands so it and the icon sit against the right edge.
        title: Row(
          children: [
            Text(
              'Orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
            // The gap between the title and the search lives here: Expanded
            // eats the slack, and Align pins a width-capped field to the
            // right of it — so on a wide screen the field + icon sit on the
            // right, while on a phone the field just shrinks to fit instead
            // of overflowing (the 240 cap keeps it from stretching).
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: const _OrderSearchField(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _FilterIconButton(
              activeCount: activeCount,
              onOpen: currentState == null
                  ? null
                  : () => _openFilters(
                        context,
                        currentState,
                        _orderStatusOptions(currentState),
                      ),
            ),
          ],
        ),
      ),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.read(orderListProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return _EmptyState(
              isFiltered: state.query != null || state.hasActiveFilters,
              onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final order = state.items[index];
                return _OrderCard(
                  orderNumber: order.orderNumber,
                  clientName: order.clientName,
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

  Future<void> _openFilters(
    BuildContext context,
    OrderListState state,
    List<String> statusOptions,
  ) async {
    final result = await showModalBottomSheet<_OrderFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OrderFilterSheet(
        statusOptions: statusOptions,
        selectedStatus: state.orderStatus,
        selectedPriority: state.priority,
        sortBy: state.sortBy,
      ),
    );
    if (result == null || !mounted) return;
    // Null on any field means "cleared"; the matching clear* flag makes that
    // explicit so it's not confused with "left untouched".
    ref.read(orderListProvider.notifier).setFilters(
          orderStatus: result.status,
          clearOrderStatus: result.status == null,
          priority: result.priority,
          clearPriority: result.priority == null,
          sortBy: result.sortBy,
          clearSortBy: result.sortBy == null,
        );
  }
}

/// The statuses present in the currently-loaded orders, sorted. Drives the
/// status chips in [_OrderFilterSheet] — same don't-guess-the-vocabulary
/// stance as before: show what the data actually contains.
List<String> _orderStatusOptions(OrderListState state) =>
    {for (final order in state.items) order.status}.toList()..sort();

/// Priorities offered as filters — only the elevated ones. low/normal aren't
/// worth a filter chip (an order being "normal" isn't something you hunt
/// for), so filtering is limited to high/urgent. The full [kPriorities] list
/// still drives the priority *selector* on the order form.
const List<String> _priorityFilterOptions = ['high', 'urgent'];

/// The compacted filter control: an icon-only button that opens
/// [_OrderFilterSheet]. A count badge appears when status/priority filters
/// are active, and the icon tints primary. `onOpen` is null until the first
/// load lands (nothing to filter yet).
class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.activeCount, required this.onOpen});

  final int activeCount;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = activeCount > 0;
    return IconButton(
      tooltip: 'Filters & sort',
      onPressed: onOpen,
      icon: Badge.count(
        count: activeCount,
        isLabelVisible: active,
        child: Icon(
          Icons.tune,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Rounded search field that lives in the app bar. Debounces keystrokes
/// (400ms) before hitting `/orders/search` via the notifier, matching the
/// client-picker's debounce feel, and shows a clear button once there's
/// text.
class _OrderSearchField extends ConsumerStatefulWidget {
  const _OrderSearchField();

  @override
  ConsumerState<_OrderSearchField> createState() => _OrderSearchFieldState();
}

class _OrderSearchFieldState extends ConsumerState<_OrderSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    ref.read(orderListProvider.notifier).setQuery(value).catchError((_) {
      if (!mounted) return;
      showErrorMessage(context, 'Search failed');
    });
  }

  void _onChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _submit(value));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _hasText = false);
    _submit('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: _onChanged,
        onSubmitted: (value) {
          _debounce?.cancel();
          _submit(value);
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search orders',
          prefixIcon: Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 40),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

/// What [_OrderFilterSheet] hands back on Apply. A null field means that
/// filter is cleared (for [sortBy], null means the default "Newest first"
/// ordering, i.e. no `sort_by` param).
class _OrderFilterResult {
  const _OrderFilterResult({this.status, this.priority, this.sortBy});

  final String? status;
  final String? priority;
  final String? sortBy;
}

/// The bottom sheet holding the status / priority / sort controls that used
/// to live as two always-visible chip rows. Edits a local draft and only
/// commits on Apply, so tapping around doesn't refetch on every change the
/// way the inline chips did.
class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({
    required this.statusOptions,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.sortBy,
  });

  final List<String> statusOptions;
  final String? selectedStatus;
  final String? selectedPriority;
  final String? sortBy;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late String? _status = widget.selectedStatus;
  late String? _priority = widget.selectedPriority;
  // Normalized so the default sort is always represented as null, matching
  // what the state/endpoint expect ("no sort_by param").
  late String? _sortBy =
      widget.sortBy == 'created_at' ? null : widget.sortBy;

  bool get _isDirty => _status != null || _priority != null || _sortBy != null;

  void _reset() => setState(() {
        _status = null;
        _priority = null;
        _sortBy = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters & sort',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _isDirty ? _reset : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.statusOptions.isNotEmpty) ...[
              const _SheetGroupLabel('Status'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                  for (final status in widget.statusOptions)
                    _FilterChip(
                      label: orderStatusLabel(status),
                      selected: _status == status,
                      onTap: () => setState(() => _status = status),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            const _SheetGroupLabel('Priority'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Any priority',
                  selected: _priority == null,
                  onTap: () => setState(() => _priority = null),
                ),
                for (final p in _priorityFilterOptions)
                  _FilterChip(
                    label: priorityLabel(p),
                    selected: _priority == p,
                    onTap: () => setState(() => _priority = p),
                    dotColor: _priorityColor(p, scheme),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _SheetGroupLabel('Sort by'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in kOrderSortOptions)
                  _FilterChip(
                    label: orderSortLabel(opt),
                    selected: (_sortBy ?? 'created_at') == opt,
                    onTap: () => setState(
                      () => _sortBy = opt == 'created_at' ? null : opt,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _OrderFilterResult(
                    status: _status,
                    priority: _priority,
                    sortBy: _sortBy,
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGroupLabel extends StatelessWidget {
  const _SheetGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
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
    case 'ready':
      return const _StatusMeta(StatusColors.orderReady, Icons.task_alt_rounded);
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
  const _EmptyState({required this.onRefresh, this.isFiltered = false});

  final Future<void> Function() onRefresh;

  /// When a search term or filter is active, an empty list means "nothing
  /// matched" rather than "no orders exist" — the copy switches accordingly.
  final bool isFiltered;

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
                  Icon(
                    isFiltered
                        ? Icons.search_off_outlined
                        : Icons.inventory_2_outlined,
                    size: 48,
                    color: scheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFiltered ? 'No matching orders' : 'No orders yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFiltered
                        ? 'Try a different search or clear the filters.'
                        : "Create one from a client's page.",
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
