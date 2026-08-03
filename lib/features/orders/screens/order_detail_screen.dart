import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../documents/widgets/order_document_actions.dart';
import '../../payments/widgets/payment_section.dart';
import '../data/order_repository.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../../tasks/tasks_paths.dart';
import '../state/order_detail_notifier.dart';
import '../state/order_list_notifier.dart';
import '../widgets/order_activity_section.dart';
import '../widgets/order_client_tile.dart';
import '../widgets/order_addons_section.dart';
import '../widgets/order_item_edit_sheet.dart';
import '../widgets/order_item_form_sheet.dart';
import '../widgets/order_media_section.dart';
import '../widgets/measurement_snapshot_section.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';

/// The order's home screen, brought to parity with the restructured backend.
/// Beyond the old due-date/notes/payment view it now drives: the order-level
/// status flow (only the transitions the backend accepts are offered),
/// priority, the discount/subtotal/total breakdown, order media, and full
/// item add / edit / delete with fabric images, style references, the
/// production-status flow, the measurement snapshot, and a read-only view of
/// who's assigned (the assignment *editor* is Phase 7).
///
/// Granular edits don't blank the screen: OrderDetailNotifier's mutation
/// methods swap in the new Order without a loading flip, and `when` is told
/// to keep showing data through a refresh. Each action carries its own busy
/// state and reports failures via SnackBar, leaving the current order on
/// screen. A delivered/cancelled order is locked — edit affordances are
/// hidden rather than left to fail server-side.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  bool _busy = false;

  // Overview / Outfits / Activity / Media, instead of one long scroll.
  // Priority, due date, the client link, and the status chip (tap it to
  // change status) live in a fixed block above the tabs so they stay
  // visible no matter which tab is open.
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  OrderDetailNotifier get _notifier =>
      ref.read(orderDetailProvider(widget.orderId).notifier);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Keep the orders list in sync after anything that changes a list-visible
  /// field (status, totals, priority, due date). Best-effort — a stale list
  /// shouldn't surface an error on this screen.
  void _refreshList() {
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  /// Marking an order 'ready' while garments are still in production is
  /// allowed — a tailor may legitimately hand an order over early — but it's
  /// worth a second look, so we name the unfinished items and ask.
  ///
  /// Returns true if the change should go ahead. Only 'ready' is gated; every
  /// other transition passes straight through.
  ///
  /// In practice this dialog fires on *most* manual "Ready" presses, and that
  /// is by design: when every item is done the backend advances the order to
  /// 'ready' by itself, so reaching for the menu usually means items are in
  /// fact unfinished and the owner is deliberately overriding.
  Future<bool> _confirmReadyWithUnfinishedItems(String target) async {
    if (target != 'ready') return true;

    final order = ref.read(orderDetailProvider(widget.orderId)).valueOrNull;
    if (order == null) return true;

    final unfinished =
        order.items.where((i) => !i.production.done).toList(growable: false);
    if (unfinished.isEmpty) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Outfits still in production'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unfinished.length == 1
                  ? 'One garment is not finished yet:'
                  : '${unfinished.length} garments are not finished yet:',
            ),
            const SizedBox(height: 8),
            for (final i in unfinished)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${i.garmentType} — ${i.production.label.toLowerCase()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 12),
            const Text('Mark the whole order ready anyway?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark ready'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _advanceStatus(String target) async {
    if (!await _confirmReadyWithUnfinishedItems(target)) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await _notifier.updateStatus(target);
      _refreshList();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not update status');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addItem(Order order) async {
    final input = await showModalBottomSheet<OrderItemInput>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => OrderItemFormSheet(clientId: order.clientId),
    );
    if (input == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _notifier.addItem(input);
      _refreshList();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not add outfit');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editItem(Order order, OrderItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => OrderItemEditSheet(
        orderId: widget.orderId,
        item: item,
        clientId: order.clientId,
      ),
    );
    // The sheet committed its own changes via the notifier; sync the list
    // since totals or item status may have moved.
    _refreshList();
  }

  Future<void> _editDetails(Order order) async {
    final result = await showDialog<_DetailsEdit>(
      context: context,
      builder: (context) => _EditDetailsDialog(order: order),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _notifier.updateDetails(
        dueDate: result.dueDate,
        notes: result.notes,
        priority: result.priority,
        discountType: result.discountType,
        discountValue: result.discountValue,
        discountIncludesAddons: result.discountIncludesAddons,
      );
      _refreshList();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Update failed');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(orderRepositoryProvider).delete(widget.orderId);
      await ref.read(orderListProvider.notifier).refresh();
      if (mounted) {
        showSuccessSnackbar(context, 'Order deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        showErrorSnackbar(context, e, action: 'Delete failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final currentOrder = orderAsync.valueOrNull;
    final locked = currentOrder?.isLocked ?? false;
    // Backend only allows deleting orders that are pending or cancelled.
    final canDelete = currentOrder != null &&
        (currentOrder.status == 'pending' ||
            currentOrder.status == 'cancelled');

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          if (currentOrder != null && !locked)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit details',
              onPressed: _busy ? null : () => _editDetails(currentOrder),
            ),
          if (canDelete)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: orderAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => _notifier.refresh(),
        ),
        data: (order) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // The order header (locked banner, order number, status chip,
            // client tile, priority/due date) now scrolls away with the
            // rest of the page — only the TabBar below it stays pinned.
            // SliverOverlapAbsorber/Injector is boilerplate NestedScrollView
            // requires to keep the pinned header's height from double-
            // counting against each tab's own scroll offset.
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.isLocked) ...[
                        _LockedBanner(status: order.status),
                        const SizedBox(height: 12),
                      ],
                      _Header(
                        order: order,
                        busy: _busy,
                        onAdvance: _advanceStatus,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Outfits'),
                    Tab(text: 'Activity'),
                    Tab(text: 'Media'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                order: order,
                onRefresh: () => _notifier.refresh(),
              ),
              _OutfitsTab(
                order: order,
                busy: _busy,
                onRefresh: () => _notifier.refresh(),
                onAddItem: () => _addItem(order),
                onEditItem: (item) => _editItem(order, item),
              ),
              _ActivityTab(
                order: order,
                onRefresh: () => _notifier.refresh(),
              ),
              _MediaTab(
                order: order,
                onRefresh: () => _notifier.refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown only when [order.isLocked]. Edit affordances quietly disappearing
/// elsewhere on this screen used to be the only signal that the order was
/// closed — this makes the reason explicit instead of leaving people to
/// infer it from a missing pencil icon.
/// Standard NestedScrollView boilerplate: wraps the TabBar so it can sit in
/// a SliverPersistentHeader and stay pinned while the header above it (order
/// number, status, client, priority/due date) scrolls away normally.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

/// Shared scroll body for each tab's content: a SliverOverlapInjector (the
/// other half of the SliverOverlapAbsorber wrapping the header above) plus
/// the tab's own content as a sliver list — this is what lets each tab
/// scroll independently while NestedScrollView keeps the pinned TabBar's
/// height correctly accounted for.
class _TabScrollView extends StatelessWidget {
  const _TabScrollView({required this.onRefresh, required this.children});

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: scheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This order is ${orderStatusLabel(status).toLowerCase()} and '
              'closed to further edits.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// Client, notes, add-ons, and the money breakdown / payment action. This is
/// "everything about the deal" as opposed to "everything about the
/// garments" (Outfits tab) or "everything that happened" (Activity tab).
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.order, required this.onRefresh});

  final Order order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      onRefresh: onRefresh,
      children: [
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          Text('Notes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(order.notes!),
          const SizedBox(height: 20),
        ],
        // Extra charges sit right above the money card: they're the
        // other half of what the total is made of, and reading them
        // straight before the total is what makes the Garments/Extras
        // split legible.
        OrderAddonsSection(order: order),
        const SizedBox(height: 12),
        PaymentSection(order: order),
      ],
    );
  }
}

/// Status history and document actions — "everything that happened on this
/// order," as distinct from its current state (fixed header) or its
/// contents (Outfits tab).
class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.order, required this.onRefresh});

  final Order order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      onRefresh: onRefresh,
      children: [
        OrderActivitySection(order: order),
        const SizedBox(height: 12),
        OrderDocumentActions(order: order),
      ],
    );
  }
}

/// The garment list, promoted out from the bottom of a long scroll to its
/// own tab. This is the substance of the order — it shouldn't take six
/// section-scrolls to reach.
class _OutfitsTab extends StatelessWidget {
  const _OutfitsTab({
    required this.order,
    required this.busy,
    required this.onRefresh,
    required this.onAddItem,
    required this.onEditItem,
  });

  final Order order;
  final bool busy;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddItem;
  final ValueChanged<OrderItem> onEditItem;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      onRefresh: onRefresh,
      children: [
        if (!order.isLocked)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy ? null : onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Add outfit'),
            ),
          ),
        if (order.items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: Text('No outfits on this order')),
          )
        else
          for (final item in order.items)
            _OrderItemCard(
              orderId: order.id,
              item: item,
              onTap: order.isLocked ? null : () => onEditItem(item),
            ),
      ],
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab({required this.order, required this.onRefresh});

  final Order order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      onRefresh: onRefresh,
      children: [
        OrderMediaSection(
          orderId: order.id,
          media: order.media,
          canAdd: order.canAddMedia,
          enabled: !order.isLocked,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.order,
    required this.busy,
    required this.onAdvance,
  });

  final Order order;
  final bool busy;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final isRush = _isElevatedPriority(order.priority);
    final scheme = Theme.of(context).colorScheme;
    final priorityColor =
        isRush ? _priorityColor(order.priority, scheme) : scheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(order.orderNumber,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            _StatusChip(
              order: order,
              busy: busy,
              onAdvance: onAdvance,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // The client tile already carries its own name display and
        // tap-through to the client detail screen — reused here directly
        // rather than duplicating that link logic, since this file doesn't
        // have visibility into how OrderClientTile resolves clientId to a
        // name. This replaces the old separate "Belongs to" section in the
        // Overview tab; the order-client relationship is always-visible
        // header info now, not something you scroll to find.
        OrderClientTile(clientId: order.clientId),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isRush ? Icons.flag : Icons.flag_outlined,
              size: 16,
              color: priorityColor,
            ),
            const SizedBox(width: 4),
            Text(
              priorityLabel(order.priority),
              style: isRush
                  ? TextStyle(
                      color: priorityColor, fontWeight: FontWeight.w600)
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(Icons.event_outlined, size: 16, color: scheme.outline),
            const SizedBox(width: 4),
            Text('Due ${_fmtDate(order.dueDate)}'),
          ],
        ),
      ],
    );
  }
}

/// Priority enum is low / normal / high / urgent. Both of the top two get
/// the elevated (filled flag) treatment — "high" isn't urgent, but it's not
/// routine either, and a two-tier visual (routine vs elevated) reads more
/// clearly at a glance than three tiers would.
bool _isElevatedPriority(String priority) =>
    priority == 'high' || priority == 'urgent';

/// Matches the priority color scheme used in order_list_screen.dart and
/// client_orders_section.dart, so a rush order reads the same color
/// wherever it's shown.
Color _priorityColor(String priority, ColorScheme scheme) {
  switch (priority) {
    case 'urgent':
      return const Color(0xFFEA580C);
    case 'high':
      return scheme.error;
    default:
      return scheme.outline;
  }
}

/// The status chip doubles as the status control: tapping it opens the same
/// allowed-transition menu the old separate "Update status" button did.
/// Color-coded by a best-effort read of common order-status strings
/// (pending / in production / ready / delivered / cancelled) — this file
/// doesn't have access to the real status enum, so unmatched values fall
/// back to a neutral tone rather than guessing wrong. Confirm the actual
/// status strings in order_labels.dart and adjust the switch below to
/// match exactly.
///
/// When there are no allowed transitions (terminal state), the chip is
/// static — no chevron, no tap handler — rather than opening an empty
/// menu.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.order,
    required this.busy,
    required this.onAdvance,
  });

  final Order order;
  final bool busy;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = order.status;
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    if (s.contains('cancel')) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else if (s.contains('deliver')) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    } else if (s.contains('ready')) {
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
    } else if (s.contains('production') || s.contains('progress')) {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    } else {
      // pending / anything unrecognized
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
    }

    final transitions = allowedOrderTransitions(status);
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(orderStatusLabel(status)),
        if (transitions.isNotEmpty) ...[
          const SizedBox(width: 4),
          if (busy)
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(Icons.expand_more, size: 16, color: fg),
        ],
      ],
    );

    if (transitions.isEmpty) {
      return Chip(
        label: label,
        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
        backgroundColor: bg,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      );
    }

    return PopupMenuButton<String>(
      enabled: !busy,
      onSelected: onAdvance,
      itemBuilder: (context) => [
        for (final t in transitions)
          PopupMenuItem(value: t, child: Text(orderStatusLabel(t))),
      ],
      // The chip itself is the button — no separate control elsewhere on
      // screen. A plain Chip (not a nested button) so the menu's own
      // gesture handling owns the tap cleanly.
      child: Chip(
        label: label,
        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
        backgroundColor: bg,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// One item card on the detail screen: garment + derived production chip,
/// the per-line figures, fabric thumbnail, recipient, the
/// measurement-snapshot indicator, and style-reference thumbs. Tapping the
/// card opens the edit sheet (unless the order is locked, when [onTap] is
/// null and the card is display-only). The production chip is its own tap
/// target: no task yet → "Create task" (routes to the create screen);
/// task exists → opens the task detail. Production state itself is
/// read-only here — it moves only through the task screen.
class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.orderId,
    required this.item,
    this.onTap,
  });

  final String orderId;
  final OrderItem item;
  final VoidCallback? onTap;

  // Fabric rows, the measurement snapshot, and style-ref thumbnails are all
  // real detail people want, but not on every glance down the list — with
  // 4-5 garments per order and 2+ fabrics each, rendering all of it inline
  // always made this the longest part of the page. It's now collapsed
  // behind "Details", off by default, so the list is scannable and the
  // detail is one tap away instead of unavoidable scroll weight.
  bool get _hasExpandableDetails =>
      item.fabrics.isNotEmpty ||
      item.measurementSetId != null ||
      item.styleReferences.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final summaryRow = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.primaryFabricImageUrl != null &&
                item.primaryFabricImageUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => showImageViewer(
                  context,
                  urls: [item.primaryFabricImageUrl!],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.primaryFabricImageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.garmentType,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(item.description!),
                  const SizedBox(height: 2),
                  Text(
                    'Qty ${item.quantity} · ${formatNaira(item.unitPrice)} each · ${formatNaira(item.lineTotal)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  _MetaChip(
                    icon: item.recipient.isGuest
                        ? Icons.person_outline
                        : Icons.account_circle_outlined,
                    label: item.recipient.isGuest
                        ? 'For a guest'
                        : 'For the client',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ProductionChip(orderId: orderId, item: item),
          ],
        ),
      ),
    );

    if (!_hasExpandableDetails) {
      return Card(margin: const EdgeInsets.only(bottom: 8), child: summaryRow);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          summaryRow,
          Theme(
            // Strip the default divider lines an ExpansionTile draws above
            // and below itself — they read as a stray rule inside the card.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text('Details',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.fabrics.isNotEmpty)
                      for (final f in item.fabrics)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.texture_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.outline),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: f.serial,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    if (f.details != null &&
                                        f.details!.isNotEmpty)
                                      TextSpan(text: ' · ${f.details}'),
                                    if (formatFabricQuantity(
                                            f.quantity, f.unit) !=
                                        null)
                                      TextSpan(
                                          text:
                                              ' · ${formatFabricQuantity(f.quantity, f.unit)}'),
                                  ]),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    // The snapshot the garment is cut from — replaces the
                    // old dead "Cut from saved measurements" chip. Values
                    // and notes load on first expand, not with the card.
                    if (item.measurementSetId != null)
                      MeasurementSnapshotSection(setId: item.measurementSetId!),
                    if (item.styleReferences.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _StyleRefThumbs(item: item),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The item's derived production state, as a tappable chip. No task yet →
/// a "Create task" affordance; with a task → the composite label
/// ("Cutting — up next"), error-tinted when overdue, opening the task
/// detail. Never editable in place — production moves through the task
/// screen only.
class _ProductionChip extends StatelessWidget {
  const _ProductionChip({required this.orderId, required this.item});

  final String orderId;
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final production = item.production;

    if (!production.hasTask) {
      return ActionChip(
        avatar: Icon(Icons.add_task, size: 16, color: scheme.primary),
        label: const Text('Create task'),
        visualDensity: VisualDensity.compact,
        onPressed: () =>
            context.push('/orders/$orderId/items/${item.id}/task/new'),
      );
    }

    final overdue = production.isOverdue;
    return ActionChip(
      label: Text(production.label),
      labelStyle: overdue ? TextStyle(color: scheme.onErrorContainer) : null,
      backgroundColor: overdue ? scheme.errorContainer : null,
      visualDensity: VisualDensity.compact,
      onPressed: () => context.push(taskDetailPath(production.taskId!)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

class _StyleRefThumbs extends StatelessWidget {
  const _StyleRefThumbs({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    // Gallery URLs computed once so tap-index math lines up with what's
    // actually shown (videos are excluded — the viewer only handles images,
    // and video thumbs are non-tappable).
    final imageUrls = [
      for (final r in item.styleReferences)
        if (r.fileType != 'video') r.fileUrl,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final ref_ in item.styleReferences)
          GestureDetector(
            onTap: ref_.fileType == 'video'
                ? null
                : () => showImageViewer(
                      context,
                      urls: imageUrls,
                      initialIndex: imageUrls.indexOf(ref_.fileUrl),
                    ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ref_.fileType == 'video'
                  ? Container(
                      width: 44,
                      height: 44,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.play_circle_outline, size: 20),
                    )
                  : Image.network(
                      ref_.fileUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.broken_image_outlined, size: 18),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

/// Result of the edit-details dialog.
class _DetailsEdit {
  const _DetailsEdit({
    required this.dueDate,
    required this.notes,
    required this.priority,
    required this.discountType,
    required this.discountValue,
    required this.discountIncludesAddons,
  });

  final DateTime dueDate;
  final String notes;
  final String priority;
  final String discountType;
  final double discountValue;

  /// Whether the discount computes on items+addons or items alone. Null when
  /// the order has no addons — there's nothing for the choice to apply to, so
  /// the dialog doesn't ask and the field isn't sent.
  final bool? discountIncludesAddons;
}

/// Edit dialog expanded from the old due-date/notes pair to also carry
/// priority and the discount type+value, so the whole of `OrderUpdate` is
/// reachable from one place. The discount value field appears only when a
/// discount type is selected.
class _EditDetailsDialog extends StatefulWidget {
  const _EditDetailsDialog({required this.order});

  final Order order;

  @override
  State<_EditDetailsDialog> createState() => _EditDetailsDialogState();
}

class _EditDetailsDialogState extends State<_EditDetailsDialog> {
  late DateTime _dueDate;
  late final TextEditingController _notesController;
  late final TextEditingController _discountController;
  late String _priority;
  late String _discountType;
  late bool _discountIncludesAddons;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _dueDate = o.dueDate;
    _notesController = TextEditingController(text: o.notes ?? '');
    _discountController =
        TextEditingController(text: _trimZeros(o.discountValue));
    _priority = o.priority;
    _discountType = o.discountType;
    _discountIncludesAddons = o.discountIncludesAddons;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(_fmtDate(_dueDate)),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                for (final p in kPriorities)
                  DropdownMenuItem(value: p, child: Text(priorityLabel(p))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _discountType,
              decoration: const InputDecoration(labelText: 'Discount'),
              items: [
                for (final t in kDiscountTypes)
                  DropdownMenuItem(value: t, child: Text(discountTypeLabel(t))),
              ],
              onChanged: (v) => setState(() {
                _discountType = v ?? 'none';
                if (_discountType == 'none') _discountController.text = '0';
              }),
            ),
            if (_discountType != 'none') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage'
                      ? 'Discount (%)'
                      : 'Discount amount',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              // Asked only when there are addons for the answer to apply to.
              // On a plain order the choice is meaningless and the default
              // (include) is sent silently — decision 3 in the spec, and the
              // reason this prompt is here rather than on the create form,
              // where an order has no addons yet and it could never fire.
              if (widget.order.hasAddons) ...[
                const SizedBox(height: 16),
                Text(
                  'Apply this discount to extra charges too?',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'This order has ${formatNaira(widget.order.addonsTotal)} '
                  'in extras.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: true,
                  groupValue: _discountIncludesAddons,
                  onChanged: (v) =>
                      setState(() => _discountIncludesAddons = v!),
                  title: Text('Yes — discount the full '
                      '${formatNaira(widget.order.subtotal)}'),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: false,
                  groupValue: _discountIncludesAddons,
                  onChanged: (v) =>
                      setState(() => _discountIncludesAddons = v!),
                  title: Text('No — discount only the '
                      '${formatNaira(widget.order.itemsSubtotal)} in garments'),
                ),
              ],
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = _discountType == 'none'
                ? 0.0
                : (double.tryParse(_discountController.text.trim()) ?? 0.0);
            Navigator.pop(
              context,
              _DetailsEdit(
                dueDate: _dueDate,
                notes: _notesController.text.trim(),
                priority: _priority,
                discountType: _discountType,
                discountValue: value,
                discountIncludesAddons:
                    widget.order.hasAddons ? _discountIncludesAddons : null,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Renders a discount value without trailing ".0" noise (e.g. 10 not 10.0,
/// but 12.5 stays 12.5) — used in both the discount line and the edit field.
String _trimZeros(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}
