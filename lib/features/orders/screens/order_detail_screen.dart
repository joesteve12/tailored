import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/utils/fabric_labels.dart';
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

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isDeleting = false;
  bool _busy = false;

  OrderDetailNotifier get _notifier =>
      ref.read(orderDetailProvider(widget.orderId).notifier);

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
        title: const Text('Order'),
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
        data: (order) => RefreshIndicator(
          onRefresh: () => _notifier.refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _Header(order: order),
              const SizedBox(height: 16),
              // Whose order this is, and the way through to them. Sits right
              // under the header because "who is this for" is the second
              // thing you want to know after "which order is this".
              Text('Belongs to',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              OrderClientTile(clientId: order.clientId),
              const SizedBox(height: 16),
              _StatusBar(
                order: order,
                busy: _busy,
                onAdvance: _advanceStatus,
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(order.notes!),
              ],
              const SizedBox(height: 20),
              PaymentSection(order: order),
              const SizedBox(height: 20),
              // Payment history and status history both live here now. The
              // PaymentSection above keeps only the money summary and the
              // "record payment" action — the history it used to render
              // inline would otherwise be duplicated in the Payments tab.
              OrderActivitySection(order: order),
              const SizedBox(height: 12),
              OrderDocumentActions(order: order),
              const SizedBox(height: 20),
              OrderMediaSection(
                orderId: order.id,
                media: order.media,
                canAdd: order.canAddMedia,
                enabled: !order.isLocked,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Outfits',
                      style: Theme.of(context).textTheme.titleSmall),
                  if (!order.isLocked)
                    TextButton.icon(
                      onPressed: _busy ? null : () => _addItem(order),
                      icon: const Icon(Icons.add),
                      label: const Text('Add outfit'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                const Text('No outfits on this order')
              else
                for (final item in order.items)
                  _OrderItemCard(
                    orderId: order.id,
                    item: item,
                    onTap: order.isLocked
                        ? null
                        : () => _editItem(order, item),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
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
            Chip(
              label: Text(orderStatusLabel(order.status)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.flag_outlined,
                size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 4),
            Text(priorityLabel(order.priority)),
            const SizedBox(width: 16),
            Icon(Icons.event_outlined,
                size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 4),
            Text('Due ${_fmtDate(order.dueDate)}'),
          ],
        ),
      ],
    );
  }
}

/// The order-status control: a labelled current state plus a menu offering
/// only the moves the backend's transition rules permit. Terminal states
/// show a quiet "no further changes" note instead of an empty menu.
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.order,
    required this.busy,
    required this.onAdvance,
  });

  final Order order;
  final bool busy;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final transitions = allowedOrderTransitions(order.status);

    if (transitions.isEmpty) {
      return Text(
        'This order is ${orderStatusLabel(order.status).toLowerCase()} — '
        'no further status changes.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        enabled: !busy,
        onSelected: onAdvance,
        itemBuilder: (context) => [
          for (final t in transitions)
            PopupMenuItem(value: t, child: Text(orderStatusLabel(t))),
        ],
        // A plain styled container (not a nested button) so the menu's own
        // gesture handling owns the tap cleanly.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.swap_horiz, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Update status',
                  style: TextStyle(color: scheme.primary)),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(item.description!),
                        const SizedBox(height: 2),
                        Text(
                          'Qty ${item.quantity} · ${item.unitPrice.toStringAsFixed(2)} each · ${item.lineTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _ProductionChip(orderId: orderId, item: item),
                ],
              ),
              if (item.fabrics.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final f in item.fabrics)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
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
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (f.details != null && f.details!.isNotEmpty)
                                TextSpan(text: ' · ${f.details}'),
                              if (formatFabricQuantity(f.quantity, f.unit) !=
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
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
              // The snapshot the garment is cut from, expandable in place —
              // replaces the old dead "Cut from saved measurements" chip.
              // Values and notes load on first expand, not with the card.
              if (item.measurementSetId != null)
                MeasurementSnapshotSection(setId: item.measurementSetId!),
              if (item.styleReferences.isNotEmpty) ...[
                const SizedBox(height: 8),
                _StyleRefThumbs(item: item),
              ],
            ],
          ),
        ),
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color)),
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
  });

  final DateTime dueDate;
  final String notes;
  final String priority;
  final String discountType;
  final double discountValue;
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
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
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
                  DropdownMenuItem(
                      value: t, child: Text(discountTypeLabel(t))),
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
