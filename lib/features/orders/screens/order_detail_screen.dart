import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/fabric_labels.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/quote_note.dart';
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
import '../widgets/order_details_edit_sheet.dart';
import '../widgets/order_item_edit_sheet.dart';
import '../widgets/order_item_form_sheet.dart';
import '../widgets/order_media_section.dart';
import '../widgets/measurement_snapshot_section.dart';

import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/video_thumbnail.dart';
import '../../../core/widgets/video_viewer.dart';

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
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialTab = 0,
    this.highlightItemId,
  });

  final String orderId;

  /// Which section tab opens first: 0 Overview, 1 Outfits, 2 Activity,
  /// 3 Media. Deep links (e.g. a production task's header tapping through
  /// to "see the outfit") pass 1 so the garment list is what you land on.
  final int initialTab;

  /// When set (paired with the Outfits tab), that item's card is scrolled
  /// into view and briefly pulsed once the list is on screen — so a
  /// tap-through from a task lands on the exact garment, not just the list.
  final String? highlightItemId;

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
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 3),
  );

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
                  ? 'One outfit is not finished yet:'
                  : '${unfinished.length} outfits are not finished yet:',
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
    // Slides up from the bottom now, rather than a centre dialog. Discount is
    // no longer edited here — it lives on the payment ticket in the Overview
    // tab — so this sheet carries only due date, priority, and notes.
    final result = await showModalBottomSheet<OrderDetailsEdit>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => OrderDetailsEditSheet(order: order),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _notifier.updateDetails(
        dueDate: result.dueDate,
        notes: result.notes,
        priority: result.priority,
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
        title: Text(currentOrder?.orderNumber ?? ''),
        actions: [
          // Status lives in the app bar now (it used to sit beside the order
          // number in the scrolling header). Still the status control — tapping
          // it opens the same allowed-transition menu.
          if (currentOrder != null) ...[
            _StatusChip(
              order: currentOrder,
              busy: _busy,
              onAdvance: _advanceStatus,
            ),
            const SizedBox(width: 4),
          ],
          // Edit and delete are folded into a single "more actions" overflow
          // so the app bar stays light beside the status pill. The menu only
          // appears when at least one of its actions is available; a delete in
          // flight swaps the icon for a spinner (its old inline feedback).
          if ((currentOrder != null && !locked) || canDelete)
            PopupMenuButton<String>(
              enabled: !_busy && !_isDeleting,
              tooltip: 'More actions',
              icon: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editDetails(currentOrder!);
                  case 'delete':
                    _confirmDelete();
                }
              },
              itemBuilder: (context) => [
                if (currentOrder != null && !locked)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit details'),
                      ],
                    ),
                  ),
                if (canDelete)
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 10),
                        Text('Delete order',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
              ],
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
                      _Header(order: order),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedTabBarDelegate(_tabController),
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
                highlightItemId: widget.highlightItemId,
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
/// Standard NestedScrollView boilerplate: wraps the pill tab bar so it can sit
/// in a SliverPersistentHeader and stay pinned while the header above it (order
/// number, status, client, priority/due date) scrolls away normally. The
/// extent is fixed (the pill bar has a constant height) rather than read off a
/// TabBar's preferredSize, since the bar is now a custom segmented control.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate(this.controller);

  final TabController controller;

  // The 8px gap above the pill (so it clears the app bar when pinned) + the
  // pill track (44) + the 8px gap below it before tab content begins.
  static const double _extent = 8 + _PillTabBar.trackHeight + 8;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _PillTabBar(controller: controller),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}

/// The order's section switcher, styled as a segmented pill control rather
/// than Material's underline TabBar: a tan `sidebarAccent` track holding four
/// equal segments, the selected one filled with the terracotta
/// `sidebarPrimary` and its cream foreground. Each segment pairs an icon with
/// its label on one row. All colors come from the sidebar token family so the
/// control reads as the app's warm chrome and tracks light/dark automatically.
class _PillTabBar extends StatelessWidget {
  const _PillTabBar({required this.controller});

  final TabController controller;

  /// Outer track height: segment (36) + the 4px inset on each side.
  static const double trackHeight = 44;
  static const double _inset = 4;
  static const double _segmentHeight = trackHeight - _inset * 2;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final pillRadius = BorderRadius.circular(t.radiusMd);
    return Container(
      height: trackHeight,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: t.sidebarAccent,
        borderRadius: BorderRadius.circular(t.radiusLg),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        indicator:
            BoxDecoration(color: t.sidebarPrimary, borderRadius: pillRadius),
        splashBorderRadius: pillRadius,
        dividerColor: Colors.transparent,
        labelColor: t.sidebarPrimaryForeground,
        unselectedLabelColor: t.sidebarForeground,
        labelStyle: TextStyle(fontSize: 12, fontWeight: t.fontWeightMedium),
        unselectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: t.fontWeightNormal),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: const [
          _PillTab(label: 'Overview'),
          _PillTab(label: 'Outfits'),
          _PillTab(label: 'Activity'),
          _PillTab(label: 'Media'),
        ],
      ),
    );
  }
}

/// One segment of [_PillTabBar]: a centered label. Color flips with the
/// segment's selected state via the TabBar's label colors.
class _PillTab extends StatelessWidget {
  const _PillTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: _PillTabBar._segmentHeight,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
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
          Icon(Icons.lock_outline, size: 16, color: context.appTokens.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This order is ${orderStatusLabel(status).toLowerCase()} and '
              'closed to further edits.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.appTokens.mutedForeground),
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
          QuoteNote(text: order.notes!),
          const SizedBox(height: 20),
        ],
        // Extra charges are managed inside the payment card now — the ticket
        // itemizes them with add/edit/remove — so the money and the charges
        // that make it up live in one place instead of two stacked cards.
        PaymentSection(order: order),
        const SizedBox(height: 12),
        OrderDocumentActions(order: order),
      ],
    );
  }
}

/// Status history — "everything that happened on this order," as distinct
/// from its current state (fixed header) or its contents (Outfits tab).
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
    this.highlightItemId,
  });

  final Order order;
  final bool busy;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddItem;
  final ValueChanged<OrderItem> onEditItem;
  final String? highlightItemId;

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
            _HighlightOnArrival(
              active: item.id == highlightItemId,
              builder: (highlight) => _OrderItemCard(
                orderId: order.id,
                item: item,
                onTap: order.isLocked ? null : () => onEditItem(item),
                highlight: highlight,
              ),
            ),
      ],
    );
  }
}

/// When its card is the deep-link target, scrolls it into view on first
/// frame and drives a 0→1→0 pulse the card paints as a primary ring — a
/// "here it is" cue that then fades out of the way rather than lingering as
/// a selection. Inactive, it just builds the card once with no ring and no
/// animation cost.
class _HighlightOnArrival extends StatefulWidget {
  const _HighlightOnArrival({required this.active, required this.builder});

  final bool active;
  final Widget Function(double highlight) builder;

  @override
  State<_HighlightOnArrival> createState() => _HighlightOnArrivalState();
}

class _HighlightOnArrivalState extends State<_HighlightOnArrival>
    with SingleTickerProviderStateMixin {
  // Nullable, and created ONLY for the active card. A `late final ... =
  // AnimationController(vsync: this)` would be lazily built the first time
  // it's touched — and for every non-target card that first touch is
  // `dispose()`, which spins up a Ticker (an inherited-widget lookup) on an
  // already-deactivated element and throws "deactivated widget's ancestor is
  // unsafe". Building it eagerly here, only when needed, avoids that entirely.
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.active) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _controller = controller;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.12,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // The card left the tree mid-scroll (e.g. a tab swipe) — the ancestor
        // Scrollable is gone; just skip the scroll and let the pulse run.
      }
      if (mounted) controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.builder(0);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Rise fast (first quarter), then ease back to nothing.
        final v = controller.value;
        final intensity =
            (v < 0.25 ? v / 0.25 : 1 - (v - 0.25) / 0.75).clamp(0.0, 1.0);
        return widget.builder(intensity);
      },
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
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isRush = _isElevatedPriority(order.priority);
    final scheme = Theme.of(context).colorScheme;
    final mutedForeground = context.appTokens.mutedForeground;
    final priorityColor =
        isRush ? _priorityColor(order.priority, scheme) : mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order number and status moved to the app bar; the header now leads
        // with the client tile.
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
                  ? TextStyle(color: priorityColor, fontWeight: FontWeight.w600)
                  : null,
            ),
            const SizedBox(width: 16),
            Icon(Icons.event_outlined, size: 16, color: mutedForeground),
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
      return StatusColors.urgent;
    case 'high':
      return StatusColors.priorityHigh(scheme);
    default:
      return scheme.outlineVariant;
  }
}

/// The status pill is both the current-status *display* and the status
/// *control*. It always shows the current status — a color-coded tinted pill
/// (the same StatusColors palette the order list uses, so a status reads the
/// same everywhere). Tapping it opens the allowed-transition menu, where the
/// one "happy path" forward move ([primaryOrderTransition]) is a filled
/// colored row pinned to the top, the sideways moves sit below it as plain
/// rows, and Cancel is divided off at the bottom in the error tone.
///
/// Unknown statuses fall back to a neutral outlined pill rather than guessing
/// a color. When there are no allowed transitions (a terminal state, or an
/// unknown one), the pill is static — no chevron, no menu — instead of
/// opening an empty list.
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
    final meta = _statusMeta(status, scheme);
    final transitions = allowedOrderTransitions(status);

    final pill = _pill(meta, hasMenu: transitions.isNotEmpty);
    if (transitions.isEmpty) return pill;

    return PopupMenuButton<String>(
      enabled: !busy,
      onSelected: onAdvance,
      tooltip: 'Change status',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => _menuItems(status, transitions, scheme),
      child: pill,
    );
  }

  /// The always-visible current-status display.
  Widget _pill(_StatusMeta meta, {required bool hasMenu}) {
    if (meta.isFallback) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: meta.color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          orderStatusLabel(order.status),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: meta.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 5),
          Text(
            orderStatusLabel(order.status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: meta.color,
            ),
          ),
          if (hasMenu) ...[
            const SizedBox(width: 2),
            if (busy)
              SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: meta.color),
              )
            else
              Icon(Icons.expand_more, size: 16, color: meta.color),
          ],
        ],
      ),
    );
  }

  /// Primary move first (filled), then the sideways moves, then Cancel
  /// divided off. Built off the same allowed-transition list — this only
  /// arranges it, the backend still owns what's permitted.
  List<PopupMenuEntry<String>> _menuItems(
    String status,
    List<String> transitions,
    ColorScheme scheme,
  ) {
    final primary = primaryOrderTransition(status);
    final entries = <PopupMenuEntry<String>>[];

    if (primary != null && transitions.contains(primary)) {
      final pm = _statusMeta(primary, scheme);
      entries.add(PopupMenuItem<String>(
        value: primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: pm.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                orderTransitionActionLabel(status, primary),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ));
    }

    final secondary = transitions
        .where((t) => t != primary && t != 'cancelled')
        .toList(growable: false);
    for (final t in secondary) {
      final m = _statusMeta(t, scheme);
      entries.add(PopupMenuItem<String>(
        value: t,
        child: Row(
          children: [
            Icon(m.icon, size: 18, color: m.color),
            const SizedBox(width: 10),
            Text(orderTransitionActionLabel(status, t)),
          ],
        ),
      ));
    }

    if (transitions.contains('cancelled')) {
      if (entries.isNotEmpty) entries.add(const PopupMenuDivider());
      entries.add(PopupMenuItem<String>(
        value: 'cancelled',
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: scheme.error),
            const SizedBox(width: 10),
            Text(
              orderTransitionActionLabel(status, 'cancelled'),
              style: TextStyle(color: scheme.error),
            ),
          ],
        ),
      ));
    }

    return entries;
  }
}

/// Color + icon for an order status. Mirrors the mapping in
/// order_list_screen.dart (and client_orders_section.dart) so a status reads
/// the same wherever it's shown; matching is on a normalized key so wire
/// variants ("in_progress" / "in-progress" / "In Progress") all land. Unknown
/// values return a neutral fallback rather than an arbitrary color.
class _StatusMeta {
  const _StatusMeta(this.color, this.icon, {this.isFallback = false});
  final Color color;
  final IconData icon;
  final bool isFallback;
}

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
    this.highlight = 0.0,
  });

  final String orderId;
  final OrderItem item;
  final VoidCallback? onTap;

  /// 0→1 intensity of the deep-link "here it is" ring, driven by
  /// [_HighlightOnArrival]. 0 (the default) paints no ring.
  final double highlight;

  // Fabric rows, the measurement snapshot, and style-ref thumbnails are all
  // real detail people want, but not on every glance down the list — with
  // 4-5 garments per order and 2+ fabrics each, rendering all of it inline
  // always made this the longest part of the page. It's now collapsed
  // behind "Details", off by default, so the list is scannable and the
  // detail is one tap away instead of unavoidable scroll weight.
  bool get _hasExpandableDetails =>
      item.fabrics.isNotEmpty ||
      item.measurementSetIds.isNotEmpty ||
      item.styleReferences.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.appTokens.mutedForeground;

    // Two independent tap targets share the card: the header opens the item
    // editor (disabled when the order is locked, i.e. onTap == null), and the
    // status bar below always opens the production task (or the create-task
    // flow). Nesting them as siblings in a Column — rather than one InkWell
    // wrapping everything — keeps the gestures from swallowing each other.
    final header = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutfitThumb(item: item),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.garmentType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatNaira(item.lineTotal),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        item.recipient.isGuest
                            ? Icons.person_outline
                            : Icons.account_circle_outlined,
                        size: 14,
                        color: muted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${item.recipient.isGuest ? 'For a guest' : 'For the client'}  ·  Qty ${item.quantity} · ${formatNaira(item.unitPrice)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
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
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: highlight > 0
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: highlight),
                width: 2,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          // Details (fabrics, measurement snapshot, style refs) sits between
          // the header and the status footer so the tinted strip stays the
          // card's true bottom edge — expanding Details grows the card
          // upward of the footer, never below it.
          if (_hasExpandableDetails)
            Theme(
            // Strip the default divider lines an ExpansionTile draws above
            // and below itself — they read as a stray rule inside the card.
            // The ListTileTheme collapses the tile's intrinsic ~56px height
            // down to roughly half that — ExpansionTile's own `tilePadding`
            // controls the row's padding, not the minimum height a plain
            // ListTile reserves internally.
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              listTileTheme: const ListTileThemeData(
                dense: true,
                minVerticalPadding: 0,
                visualDensity: VisualDensity(vertical: -4),
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text('Details',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.appTokens.mutedForeground,
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
                                  color: context.appTokens.mutedForeground),
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
                    // The snapshots the garment is cut from — one section per
                    // linked set (a top + skirt outfit shows both). Values and
                    // notes load on first expand, not with the card.
                    for (final sid in item.measurementSetIds)
                      MeasurementSnapshotSection(setId: sid),
                    if (item.styleReferences.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _StyleRefThumbs(item: item),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _OutfitStatusBar(orderId: orderId, item: item),
        ],
      ),
    );
  }
}

/// The garment's fabric photo, or a typed placeholder tile when there's no
/// photo yet — so every card reads as a consistent object rather than some
/// with a thumbnail and some with a ragged text-only left edge. Tapping a
/// real photo opens the viewer; the placeholder is inert (the header's own
/// tap handles the item).
class _OutfitThumb extends StatelessWidget {
  const _OutfitThumb({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;
    final url = item.primaryFabricImageUrl;
    final radius = BorderRadius.circular(tokens.radiusMd);

    if (url != null && url.isNotEmpty) {
      return GestureDetector(
        onTap: () => showImageViewer(context, urls: [url]),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.network(
            url,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _placeholderTile(scheme, tokens, radius),
          ),
        ),
      );
    }
    return _placeholderTile(scheme, tokens, radius);
  }

  Widget _placeholderTile(
      ColorScheme scheme, AppTokens tokens, BorderRadius radius) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Icon(_garmentIcon(item.garmentType),
          size: 26, color: tokens.mutedForeground),
    );
  }
}

/// A rough garment-type → icon map for the placeholder tile. Best-effort
/// only: anything unrecognised falls back to the generic hanger.
IconData _garmentIcon(String garmentType) {
  final t = garmentType.toLowerCase();
  if (t.contains('gown') || t.contains('dress')) return Icons.woman;
  if (t.contains('suit') || t.contains('agbada') || t.contains('jacket')) {
    return Icons.checkroom;
  }
  return Icons.checkroom_outlined;
}

/// Full-width, color-coded production strip anchored to the bottom of the
/// card. Replaces the old cramped `ActionChip` that competed with the price
/// for horizontal space. The tint encodes the state at a glance — muted for
/// queued, warm for in-progress, green for done, the error color when
/// overdue, the primary accent for the "create task" prompt — and the whole
/// strip is the tap target (task detail, or the create-task flow).
class _OutfitStatusBar extends StatelessWidget {
  const _OutfitStatusBar({required this.orderId, required this.item});

  final String orderId;
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final production = item.production;

    late final Color tint;
    late final IconData icon;
    late final String label;
    if (!production.hasTask) {
      tint = scheme.primary;
      icon = Icons.add_task;
      label = 'Create task';
    } else if (production.isOverdue) {
      tint = scheme.error;
      icon = Icons.error_outline;
      label = production.label;
    } else if (production.done) {
      tint = StatusColors.orderDelivered;
      icon = Icons.check_circle_outline;
      label = production.label;
    } else if (production.currentStageStarted) {
      // Actively-worked stage rides the brand primary, not the orange
      // "urgent" tint — in-progress is the normal happy path, not an alarm.
      tint = scheme.primary;
      icon = Icons.autorenew_rounded;
      label = production.label;
    } else {
      tint = context.appTokens.mutedForeground;
      icon = Icons.schedule_rounded;
      label = production.label;
    }

    return InkWell(
      onTap: () => production.hasTask
          ? context.push(taskDetailPath(production.taskId!))
          : context.push('/orders/$orderId/items/${item.id}/task/new'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          border: Border(top: BorderSide(color: tint.withValues(alpha: 0.22))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: tint, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: tint),
            ],
          ),
        ),
      ),
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
                ? () => showVideoViewer(context, url: ref_.fileUrl)
                : () => showImageViewer(
                      context,
                      urls: imageUrls,
                      initialIndex: imageUrls.indexOf(ref_.fileUrl),
                    ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ref_.fileType == 'video'
                  ? SizedBox(
                      width: 44,
                      height: 44,
                      child: VideoThumbnail(url: ref_.fileUrl, badgeSize: 18),
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

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
