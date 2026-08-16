import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/feedback.dart';
import '../models/order.dart';
import '../models/order_addon.dart';
import '../state/order_detail_notifier.dart';
import '../state/order_list_notifier.dart';
import 'addon_form_sheet.dart';

/// Extra charges on the order — delivery, a rush fee, embroidery. Sits below
/// the items list on the order-detail screen.
///
/// Kept visually distinct from the outfits list on purpose. These are money,
/// not production: nothing here creates a task, assigns an employee, or moves
/// the order's status, and an operator should never have to wonder whether
/// adding a delivery fee just put a `ready` order back into the workroom.
///
/// Read-only rather than hidden once the order is locked. A delivered order's
/// delivery fee is exactly the kind of thing someone goes looking for later,
/// and hiding it would make the money card's Extras row unexplainable.
class OrderAddonsSection extends ConsumerStatefulWidget {
  const OrderAddonsSection({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderAddonsSection> createState() =>
      _OrderAddonsSectionState();
}

class _OrderAddonsSectionState extends ConsumerState<OrderAddonsSection> {
  /// Id of the addon being mutated, for a per-row spinner. Null while idle.
  String? _busyId;
  bool _adding = false;

  Order get order => widget.order;

  OrderDetailNotifier get _notifier =>
      ref.read(orderDetailProvider(order.id).notifier);

  /// Addon mutations return the full order, which the notifier adopts — so
  /// the money card repaints from the same round trip. Only the orders list
  /// needs a separate nudge, since a changed total moves what it displays.
  void _syncList() {
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  Future<void> _add() async {
    final draft = await showModalBottomSheet<AddonDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddonFormSheet(),
    );
    if (draft == null || !mounted) return;

    setState(() => _adding = true);
    try {
      await _notifier.addAddon(
        label: draft.label,
        amount: draft.amount,
        quantity: draft.quantity,
        notes: draft.notes.isEmpty ? null : draft.notes,
      );
      _syncList();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not add charge');
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _edit(OrderAddon addon) async {
    final draft = await showModalBottomSheet<AddonDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddonFormSheet(existing: addon),
    );
    if (draft == null || !mounted) return;

    setState(() => _busyId = addon.id);
    try {
      await _notifier.updateAddon(
        addon.id,
        label: draft.label,
        amount: draft.amount,
        quantity: draft.quantity,
        notes: draft.notes,
      );
      _syncList();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not update charge');
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(OrderAddon addon) async {
    // Warn about credit, don't block it. Removing a charge from a paid order
    // legitimately puts it into credit; the shop refunds when it suits them.
    final createsCredit =
        order.amountPaid > order.totalAmount - addon.lineTotal + 0.005;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${addon.label}?'),
        content: Text(
          createsCredit
              ? "This order's total drops to "
                  '${formatNaira(order.totalAmount - addon.lineTotal)}. '
                  "You've received ${formatNaira(order.amountPaid)}, so "
                  '${formatNaira(order.amountPaid - (order.totalAmount - addon.lineTotal))} '
                  'will be owed back to the client. You can refund it later '
                  'from the payment card.'
              : 'This charge will be removed and the total recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = addon.id);
    try {
      await _notifier.deleteAddon(addon.id);
      _syncList();
      if (mounted) showSuccessSnackbar(context, 'Charge removed');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not remove charge');
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = order.isLocked;
    final addons = order.addons;

    // Nothing to show and nothing to add: stay out of the way entirely.
    if (locked && addons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Extra charges',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              if (!locked)
                _adding
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: _add,
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add charge',
                        style: IconButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(color: scheme.primary, width: 1.4),
                          shape: const CircleBorder(),
                          minimumSize: const Size(34, 34),
                          maximumSize: const Size(34, 34),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
            ],
          ),
          if (addons.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No extra charges',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appTokens.mutedForeground,
                    ),
              ),
            )
          else ...[
            // The one tear: perforation-style rule that separates the header
            // from the charges, echoing a ticket stub rather than a plain
            // Material divider.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _PerforatedDivider(color: scheme.outlineVariant),
            ),
            for (var i = 0; i < addons.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 17,
                  thickness: 1,
                  color: scheme.outlineVariant.withOpacity(0.5),
                ),
              _AddonRow(
                addon: addons[i],
                locked: locked,
                busy: _busyId == addons[i].id,
                onEdit: () => _edit(addons[i]),
                onDelete: () => _delete(addons[i]),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Text('Total',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                  const Spacer(),
                  SizedBox(
                    width: _AddonRow.priceWidth,
                    child: Text(
                      formatNaira(order.addonsTotal),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(width: _AddonRow.actionsWidth),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A dashed hairline in the app's outline color — stands in for the
/// perforated tear line between a ticket's stub and its body. Cheap to
/// paint, doesn't depend on the header's rendered height, and respects
/// whatever width the card is given.
class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashPainter(color: color),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  static const double _dashWidth = 4;
  static const double _gapWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + _dashWidth, 0), paint);
      x += _dashWidth + _gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.addon,
    required this.locked,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final OrderAddon addon;
  final bool locked;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Shared with the card's Total row so every amount in the card — each
  /// charge and the sum — lands in the same right-aligned column.
  static const double priceWidth = 64;

  /// Reserved even on locked rows (just left empty) so the price column
  /// stays put whether or not a row happens to show action icons.
  static const double actionsWidth = 68;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon.label,
                    style: Theme.of(context).textTheme.bodyMedium),
                // Only spell out the multiplication when there is one.
                if (addon.quantity > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${addon.quantity} × ${formatNaira(addon.amount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appTokens.mutedForeground,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                  ),
                if (addon.notes != null && addon.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      addon.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _AddonRow.priceWidth,
            child: Text(
              formatNaira(addon.lineTotal),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          SizedBox(
            width: _AddonRow.actionsWidth,
            height: 30,
            child: locked
                ? null
                : busy
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit charge',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(30, 30),
                              maximumSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            tooltip: 'Remove charge',
                            style: IconButton.styleFrom(
                              foregroundColor: scheme.error,
                              minimumSize: const Size(30, 30),
                              maximumSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
