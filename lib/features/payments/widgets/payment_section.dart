import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/feedback.dart';
import '../../orders/models/order.dart';
import '../../orders/models/order_addon.dart';
import '../../orders/state/order_detail_notifier.dart';
import '../../orders/state/order_list_notifier.dart';
import '../../orders/widgets/addon_form_sheet.dart';
import '../../orders/widgets/discount_edit_sheet.dart';
import '../state/payment_providers.dart';
import 'log_tip_sheet.dart';
import 'money_sheet_parts.dart';
import 'record_payment_sheet.dart';
import 'record_refund_sheet.dart';

/// The order's money summary — the breakdown, plus the three money actions.
/// Payment *history* lives in the order-detail Activity section; this widget
/// stays a compact money-facts card.
///
/// Redesign notes — "claim ticket":
///
///   * The card is styled after the paper claim ticket a customer gets when
///     they drop off garments: an eyelet in the top corner, a punched
///     tear-perforation before the totals, monospace ticket numerals, and
///     dotted leader lines on the breakdown rows (label ... value), the way
///     a printed receipt sets figures. Every colour comes from the app's own
///     `ColorScheme` rather than a fixed palette, so the card sits correctly
///     in whichever theme — light or dark — the rest of the screen is in.
///   * The **payment dial** is the signature element and replaces the old
///     linear bar. It's a ring, like the porthole/gauge on the machines this
///     business runs — full sweep = 100% paid. On an overpaid order the ring
///     goes solid in the refund colour instead of clipping, so the shape
///     itself flags "money owed back" before any digit is read.
///   * The headline pairing next to the dial is *Balance due* (or *Refund
///     due*) in large ticket-mono numerals — that's the one fact that needs
///     zero parsing. The Garments/Extras/Subtotal/Discount breakdown stays
///     available underneath, but quieter, since it's the arithmetic you'd
///     audit rather than the number you'd act on.
///
/// The two states that mattered before still hold: the Garments/Extras split
/// only appears on orders with addons, and `balanceDue` / `refundDue` remain
/// mutually exclusive.
///
/// Requires a monospace family named `JetBrainsMono` (or swap the string for
/// whatever mono family the app already ships) registered in pubspec.yaml —
/// falls back to the platform default monospace otherwise, which still
/// works but loses the ticket-numeral feel.
class PaymentSection extends ConsumerStatefulWidget {
  const PaymentSection({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<PaymentSection> {
  Order get order => widget.order;

  /// Id of the charge being mutated, for a per-row spinner. Null while idle.
  String? _busyAddonId;

  /// True while a brand-new charge is being posted (spinner on the Add link).
  bool _addingAddon = false;

  /// True while a discount add/edit is being committed (spinner on the
  /// discount row's edit cue).
  bool _editingDiscount = false;

  OrderDetailNotifier get _orderNotifier =>
      ref.read(orderDetailProvider(order.id).notifier);

  void _refreshAfterMutation() {
    // Payments, refunds, tips and deletions all touch the same three
    // surfaces. Kept in sync with the delete action in the Activity section.
    // Status events are untouched by money changes.
    ref.invalidate(paymentsProvider(order.id));
    ref.read(orderDetailProvider(order.id).notifier).refresh();
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  /// The earliest date a new money row may carry, from the already-loaded
  /// history. Falls back to the order's creation date while the list is still
  /// in flight — the same floor the backend would apply with no payments on
  /// file, so a slow load can't produce a picker that offers dates the server
  /// will reject.
  DateTime get _dateFloor {
    final payments = ref.read(paymentsProvider(order.id)).valueOrNull;
    if (payments == null) return order.createdAt;
    return paymentFloorFor(payments, order);
  }

  Future<void> _open(Widget sheet) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => sheet,
    );
    if (ok == true) _refreshAfterMutation();
  }

  Future<void> _recordPayment() => _open(RecordPaymentSheet(
        orderId: order.id,
        maxAmount: order.balanceDue,
        orderTotal: order.totalAmount,
        dateFloor: _dateFloor,
      ));

  Future<void> _recordRefund() => _open(RecordRefundSheet(
        orderId: order.id,
        maxAmount: order.amountPaid,
        dateFloor: _dateFloor,
      ));

  Future<void> _logTip() => _open(LogTipSheet(
        orderId: order.id,
        orderTotal: order.totalAmount,
        dateFloor: _dateFloor,
      ));

  /// Charge mutations return the full order, which the notifier adopts — so
  /// this ticket repaints (new Extras rows, new Subtotal/Total) from the same
  /// round trip. Only the orders list needs a separate nudge, since a changed
  /// total moves what it displays.
  void _syncListAfterAddon() {
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  Future<void> _addAddon() async {
    final draft = await showModalBottomSheet<AddonDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddonFormSheet(),
    );
    if (draft == null || !mounted) return;

    setState(() => _addingAddon = true);
    try {
      await _orderNotifier.addAddon(
        label: draft.label,
        amount: draft.amount,
        quantity: draft.quantity,
        notes: draft.notes.isEmpty ? null : draft.notes,
      );
      _syncListAfterAddon();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not add charge');
      }
    } finally {
      if (mounted) setState(() => _addingAddon = false);
    }
  }

  /// Add or edit the order's discount from the ticket. Commits through
  /// `updateDetails` (discount fields only — due date/priority/notes are left
  /// untouched, since the repo omits null fields), then nudges the orders list
  /// because the total moved.
  Future<void> _editDiscount() async {
    final result = await showModalBottomSheet<DiscountEdit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DiscountEditSheet(order: order),
    );
    if (result == null || !mounted) return;

    setState(() => _editingDiscount = true);
    try {
      await _orderNotifier.updateDetails(
        discountType: result.discountType,
        discountValue: result.discountValue,
        discountIncludesAddons: result.discountIncludesAddons,
      );
      _syncListAfterAddon();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not update discount');
      }
    } finally {
      if (mounted) setState(() => _editingDiscount = false);
    }
  }

  Future<void> _editAddon(OrderAddon addon) async {
    final draft = await showModalBottomSheet<AddonDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddonFormSheet(existing: addon),
    );
    if (draft == null || !mounted) return;

    setState(() => _busyAddonId = addon.id);
    try {
      await _orderNotifier.updateAddon(
        addon.id,
        label: draft.label,
        amount: draft.amount,
        quantity: draft.quantity,
        notes: draft.notes,
      );
      _syncListAfterAddon();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not update charge');
      }
    } finally {
      if (mounted) setState(() => _busyAddonId = null);
    }
  }

  Future<void> _deleteAddon(OrderAddon addon) async {
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
                  'from this card.'
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

    setState(() => _busyAddonId = addon.id);
    try {
      await _orderNotifier.deleteAddon(addon.id);
      _syncListAfterAddon();
      if (mounted) showSuccessSnackbar(context, 'Charge removed');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not remove charge');
      }
    } finally {
      if (mounted) setState(() => _busyAddonId = null);
    }
  }

  /// `Discount (10%)`, or `Discount (10% on garments)` when the discount
  /// deliberately excludes addons.
  ///
  /// The qualifier is not optional. `discountIncludesAddons` is a stored flag
  /// that changes the total without appearing anywhere else on screen; an
  /// unlabelled discount that quietly computes on a different base than the
  /// subtotal directly above it is a support ticket waiting to be filed.
  String get _discountLabel {
    final buffer = StringBuffer('Discount');
    final isPercentage = order.discountType == 'percentage';
    if (isPercentage || !order.discountIncludesAddons) {
      buffer.write(' (');
      if (isPercentage)
        buffer.write('${trimTrailingZeros(order.discountValue)}%');
      if (!order.discountIncludesAddons) {
        if (isPercentage) buffer.write(' ');
        buffer.write('on garments');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Recording a payment needs an outstanding balance and a live order.
    final canRecord = order.status != 'cancelled' && order.balanceDue > 0.005;
    // Refunding needs money to have come in. Allowed on cancelled orders —
    // returning a deposit after a cancellation is the commonest refund there
    // is, and blocking it leaves the shop nowhere to record the money.
    final canRefund = order.amountPaid > 0.005;
    // Tips are available on any live order, fully paid ones especially.
    final canTip = order.status != 'cancelled';
    final showRefundDue = order.refundDue > 0.005;
    final accent = showRefundDue ? scheme.error : scheme.primary;
    final onAccent = showRefundDue ? scheme.onError : scheme.onPrimary;

    final ratio = order.totalAmount <= 0
        ? 0.0
        : (order.amountPaid / order.totalAmount).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The paper surface — the same tier in both themes (the card is not
    // lightened in dark mode). Depth is handled by the shadow below.
    final cardColor = scheme.surfaceContainerHigh;
    // The extruded "side" of the paper — the card colour nudged toward the
    // foreground so it reads as thickness. Because onSurface is the opposite
    // luminance of the surface, this lands darker than the card in light mode
    // and lighter in dark mode, so it contrasts with the page either way.
    final extrudeColor =
        Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.22), cardColor);

    // The card is torn paper, not a rounded panel: a jagged top and bottom
    // edge (straight sides) via _TornReceiptClipper. No border — a real
    // receipt has none.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Extruded thickness: a darker torn copy offset down-right, drawn
        // behind the card so it peeks out along the bottom-right edges.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TornExtrudePainter(color: extrudeColor, dx: 4, dy: 4),
            ),
          ),
        ),
        PhysicalShape(
          clipper: const _TornReceiptClipper(),
          clipBehavior: Clip.antiAlias,
          color: cardColor,
          // A black shadow is invisible on a near-black page, so in dark mode
          // the card is lifted by a soft LIGHT glow in the brand terracotta
          // (scheme.primary) — the elevation shadow follows the torn edge, so
          // the glow traces the tear. Light mode keeps the conventional dark
          // shadow.
          elevation: isDark ? 6 : 3,
          shadowColor: isDark
              ? scheme.primary.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.28),
          child: Container(
            // Extra top/bottom padding clears the torn strip so content never
            // collides with a tear.
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 2,
                  left: 2,
                  child: _Eyelet(
                    cardColor: cardColor,
                    brassColor: scheme.tertiary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLAIM TICKET',
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.6,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Payment',
                                style: textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          _StampBadge(
                            label: paymentStatusLabel(order.paymentStatus),
                            color: accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _PaymentDial(
                            ratio: ratio,
                            overpaid: showRefundDue,
                            trackColor: scheme.surfaceContainerHighest,
                            fillColor: accent,
                            labelColor: scheme.onSurface,
                            captionColor: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  showRefundDue ? 'Refund due' : 'Balance due',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  formatNaira(showRefundDue
                                      ? order.refundDue
                                      : order.balanceDue),
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._breakdownRows(scheme),
                      if (canRecord || canRefund || canTip) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (canRecord)
                              _TicketButton(
                                label: 'Record payment',
                                icon: Icons.payments_outlined,
                                filled: true,
                                color: scheme.primary,
                                onColor: scheme.onPrimary,
                                inkColor: scheme.onSurface,
                                borderColor: _ticketHairline(scheme),
                                onPressed: _recordPayment,
                              ),
                            if (canRefund)
                              // Promoted to a filled stub when a refund is
                              // actually owed — that's the outstanding action on
                              // the order, and it should look like one.
                              _TicketButton(
                                label: 'Record refund',
                                icon: Icons.undo,
                                filled: showRefundDue,
                                color: accent,
                                onColor: onAccent,
                                inkColor: scheme.onSurface,
                                borderColor: _ticketHairline(scheme),
                                onPressed: _recordRefund,
                              ),
                            if (canTip)
                              _TicketButton(
                                label: 'Log a tip',
                                icon: Icons.volunteer_activism_outlined,
                                filled: false,
                                color: scheme.primary,
                                onColor: scheme.onPrimary,
                                inkColor: scheme.onSurface,
                                borderColor: _ticketHairline(scheme),
                                onPressed: _logTip,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // The deckle line is drawn OVER the card (not clipped inside it) so it
        // lands exactly on the torn edge and traces every tooth tip, instead
        // of cutting their corners the way an inner-clipped stroke would.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TornEdgePainter(
                scheme.onSurface.withValues(alpha: isDark ? 0.24 : 0.16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The itemized money breakdown. Extra charges are listed here as editable
  /// ticket lines (tap a row to edit, × to remove) with an "Add charge" link,
  /// rather than collapsed into a single "Extras" figure — the money and the
  /// charges that make it up now live in one place. When the order is locked
  /// the charges stay visible but read-only and the Add link disappears.
  List<Widget> _breakdownRows(ColorScheme scheme) {
    final hasAddons = order.hasAddons;
    // When charges are itemized, every row reserves a fixed remove-column on
    // the far right: the charge rows put their × there, the computed rows
    // leave it empty. That keeps the × in one column and every amount aligned
    // in the column just left of it.
    final removeColumn = hasAddons ? _kRemoveColumn : 0.0;

    return [
      // The garments base only earns its own line once there are extras to
      // split it from; otherwise Subtotal alone says it.
      if (hasAddons)
        _leaderRow(scheme, 'Garments', formatNaira(order.itemsSubtotal),
            trailingColumn: removeColumn),
      // The extras subsection: a header carrying its own "+ Add" action, then
      // the itemized charges. Shown whenever there are charges to label or the
      // order is open enough to add one.
      if (hasAddons || !order.isLocked)
        _ExtrasHeader(
          canAdd: !order.isLocked,
          busy: _addingAddon,
          onAdd: _addAddon,
        ),
      for (final addon in order.addons)
        _AddonLeaderRow(
          addon: addon,
          locked: order.isLocked,
          busy: _busyAddonId == addon.id,
          onEdit: () => _editAddon(addon),
          onDelete: () => _deleteAddon(addon),
        ),
      _leaderRow(scheme, 'Subtotal', formatNaira(order.subtotal),
          trailingColumn: removeColumn),
      // Discount is edited here now, not in the order-edit sheet — the money it
      // changes is right above it. A live discount is a tappable row; an order
      // without one gets an "Add discount" link (unless it's locked).
      if (order.hasDiscount)
        _DiscountRow(
          label: _discountLabel,
          value: '-${formatNaira(order.discountAmount)}',
          locked: order.isLocked,
          busy: _editingDiscount,
          trailingColumn: removeColumn,
          onEdit: _editDiscount,
        )
      else if (!order.isLocked)
        _AddDiscountRow(busy: _editingDiscount, onTap: _editDiscount),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: _Perforation(color: _ticketHairline(scheme)),
      ),
      _totalsRow(scheme, 'Total', formatNaira(order.totalAmount),
          emphasize: true, valueColor: scheme.primary,
          trailingColumn: removeColumn),
      _totalsRow(scheme, 'Paid', formatNaira(order.amountPaid),
          trailingColumn: removeColumn),
    ];
  }

  /// A breakdown line set as a printed ticket item: label, dotted leader,
  /// tabular-figure value. Quieter than the totals block below it — this is
  /// the arithmetic you'd audit, not the number you'd act on. [trailingColumn]
  /// reserves the empty remove-column so the value lands in the same amount
  /// column as the editable charge rows (which fill that column with a ×).
  Widget _leaderRow(ColorScheme scheme, String label, String value,
      {double trailingColumn = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _DottedLine(color: _ticketHairline(scheme)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (trailingColumn > 0) SizedBox(width: trailingColumn),
        ],
      ),
    );
  }

  Widget _totalsRow(ColorScheme scheme, String label, String value,
      {bool emphasize = false, Color? valueColor, double trailingColumn = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: emphasize ? 15 : 13.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? scheme.onSurface,
              fontSize: emphasize ? 15 : 13.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (trailingColumn > 0) SizedBox(width: trailingColumn),
        ],
      ),
    );
  }
}

/// Width of the far-right remove (×) column. The computed rows leave it empty;
/// the charge rows fill it with their × so both the button and every amount
/// stay in fixed, aligned columns.
const double _kRemoveColumn = 28;

/// Hairline color for the ticket's dotted leaders, perforation, and button
/// borders. `outlineVariant` is too low-contrast on the warm card in light
/// mode (the lines vanish), so these use a fixed fraction of `onSurface` — dark
/// ink on the tan card in light, light ink on the dark card in dark — the same
/// approach the torn edge already uses, so it stays visible in both themes.
Color _ticketHairline(ColorScheme scheme) =>
    scheme.onSurface.withValues(alpha: 0.32);

/// One extra charge as an editable ticket line: label (with a `×N` quantity
/// hint when it applies), dotted leader, the line total in the shared amount
/// column, and a remove × in its own fixed column on the far right. Tapping
/// the row opens the edit sheet; the × removes the charge. When [locked] the
/// row is static and the × column is left empty (so the amount stays put).
class _AddonLeaderRow extends StatelessWidget {
  const _AddonLeaderRow({
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label =
        addon.quantity > 1 ? '${addon.label}  ×${addon.quantity}' : addon.label;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Label + dotted leader wrapped in ONE Expanded. Nesting them keeps
          // the loose label from leaving slack that would otherwise collect at
          // the row's end and shove the amount out of its column — the reason
          // charge amounts drifted left of the computed rows before.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Leading pencil is the "tap to edit" cue — without it the
                // charge rows read as plain text. Only when editable; it also
                // indents the charges a step under the "Extra charges" header.
                if (!locked) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Icon(Icons.edit_outlined,
                        size: 13, color: scheme.primary),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12.5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _DottedLine(color: _ticketHairline(scheme)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatNaira(addon.lineTotal),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          // Dedicated remove column, far right — empty (but still reserved)
          // when locked so the amount above stays in the same column.
          SizedBox(
            width: _kRemoveColumn,
            height: 20,
            child: locked
                ? null
                : busy
                    ? const Center(
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.close, size: 14),
                        color: scheme.error,
                        tooltip: 'Remove charge',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                            width: _kRemoveColumn, height: 20),
                      ),
          ),
        ],
      ),
    );

    // Each charge sits on a band one tier deeper than the card
    // (surfaceContainerHighest vs the card's surfaceContainerHigh), so it
    // reads as its own tappable object rather than a line of text. Only the
    // left is inset — the right stays flush so the amount column keeps lining
    // up with the computed rows.
    final band = Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: locked
          ? Padding(padding: const EdgeInsets.only(left: 8), child: row)
          : InkWell(
              onTap: onEdit,
              child: Padding(padding: const EdgeInsets.only(left: 8), child: row),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: band,
    );
  }
}

/// The discount as an editable computed row: a leading pencil cue, the
/// (already-qualified) discount label, the dotted leader, and the negative
/// amount in the shared amount column. Tapping it opens the discount sheet.
/// When [locked] the cue disappears and the row is static; while [busy] the
/// cue is a spinner so the amount column stays put.
class _DiscountRow extends StatelessWidget {
  const _DiscountRow({
    required this.label,
    required this.value,
    required this.locked,
    required this.busy,
    required this.trailingColumn,
    required this.onEdit,
  });

  final String label;
  final String value;
  final bool locked;
  final bool busy;
  final double trailingColumn;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!locked) ...[
            SizedBox(
              width: 15,
              height: 13,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(Icons.edit_outlined, size: 13, color: scheme.primary),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _DottedLine(color: _ticketHairline(scheme)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (trailingColumn > 0) SizedBox(width: trailingColumn),
        ],
      ),
    );

    if (locked) return row;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}

/// The "＋ Add discount" link shown in place of the discount row when the order
/// has none and is still open. Left-aligned so it reads as an action rather
/// than a computed figure.
class _AddDiscountRow extends StatelessWidget {
  const _AddDiscountRow({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: busy
                    ? const Center(
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(Icons.add, size: 15, color: scheme.primary),
              ),
              const SizedBox(width: 4),
              Text(
                'Add discount',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subheader for the extras subsection: an "Extra charges" label with a "+ Add"
/// action aligned to the right of the same row. The action shows only when the
/// order is open ([canAdd]) and swaps to a small spinner while a new charge is
/// posting.
class _ExtrasHeader extends StatelessWidget {
  const _ExtrasHeader({
    required this.canAdd,
    required this.busy,
    required this.onAdd,
  });

  final bool canAdd;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Text(
            'Extra charges',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (canAdd)
            busy
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 15, color: scheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
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

/// The small brass eyelet in the ticket's top-left corner — the hole a
/// string would loop through on the real thing. Purely decorative, but it's
/// the one detail that reads "tag" before any text does. `cardColor` is the
/// ring's border so it visually punches through to the card behind it.
class _Eyelet extends StatelessWidget {
  const _Eyelet({required this.cardColor, required this.brassColor});

  final Color cardColor;
  final Color brassColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: brassColor,
          border: Border.all(color: cardColor, width: 2.5),
        ),
      ),
    );
  }
}

/// Rotated, outlined badge for the payment status — reads like a rubber ink
/// stamp pressed onto the ticket rather than a soft UI pill.
class _StampBadge extends StatelessWidget {
  const _StampBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -4 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

/// The signature element. A gauge ring standing in for the porthole/dial on
/// the machines this business runs, replacing the old linear bar. On an
/// overpaid order the ring goes solid in the refund colour instead of
/// clipping at 100% — the shape flags "money owed back" before any digit is
/// read, matching the Refund due row it sits beside.
class _PaymentDial extends StatelessWidget {
  const _PaymentDial({
    required this.ratio,
    required this.overpaid,
    required this.trackColor,
    required this.fillColor,
    required this.labelColor,
    required this.captionColor,
  });

  final double ratio;
  final bool overpaid;
  final Color trackColor;
  final Color fillColor;
  final Color labelColor;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(ratio * 100).round()}%';
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _DialPainter(
              ratio: ratio,
              overpaid: overpaid,
              trackColor: trackColor,
              fillColor: fillColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentLabel,
                style: TextStyle(
                  color: overpaid ? fillColor : labelColor,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'PAID',
                style: TextStyle(
                  color: captionColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.ratio,
    required this.overpaid,
    required this.trackColor,
    required this.fillColor,
  });

  final double ratio;
  final bool overpaid;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    if (!overpaid) {
      final track = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    }

    final sweep = overpaid ? 2 * math.pi : 2 * math.pi * ratio.clamp(0.0, 1.0);
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.overpaid != overpaid ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}

/// Row of evenly spaced dots, used as the leader line between a breakdown
/// label and its value — the way a printed ticket sets `Item .... 3.50`.
class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dotSpacing = 5.0;
        final count = math.max(2, (constraints.maxWidth / dotSpacing).floor());
        return SizedBox(
          height: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                width: 1.6,
                height: 1.6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The tear-perforation before the totals block — a full-width row of small
/// punched dots, standing in for the divider on the original card.
class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dotSpacing = 10.0;
        final count = math.max(2, (constraints.maxWidth / dotSpacing).floor());
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: 3.2,
              height: 3.2,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}

/// Ticket-stub styled action button: solid ink-stamp fill for the primary
/// action on the ticket, dashed-feeling outline for the rest — so the
/// secondary actions still read as buttons rather than bare links, without
/// competing with the one that matters. `onColor` is the text/icon colour
/// used against `color` when filled (e.g. `colorScheme.onPrimary`), so
/// contrast stays correct whichever accent is passed in.
class _TicketButton extends StatelessWidget {
  const _TicketButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onColor,
    required this.inkColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final Color onColor;
  final Color inkColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final contentColor = filled ? onColor : inkColor;
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.4),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: contentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips the payment card to a torn-paper silhouette: ragged top and bottom
/// edges with straight sides. Bite depths follow a short repeating pattern so
/// the tear reads as hand-torn rather than a machine-cut zigzag.
class _TornReceiptClipper extends CustomClipper<Path> {
  const _TornReceiptClipper();

  /// Maximum vertical bite of a tear, in logical pixels.
  static const double _tooth = 9;

  /// Horizontal spacing between tear points.
  static const double _step = 12;

  static const List<double> _bites = [
    0.25,
    0.9,
    0.4,
    0.7,
    0.15,
    0.85,
    0.5,
    1.0,
    0.3,
    0.65,
    0.45,
    0.8,
  ];

  @override
  Path getClip(Size size) => buildPath(size);

  /// The closed torn silhouette. Shared with [_TornEdgePainter] so the stroked
  /// deckle line traces exactly the same tear as the clip.
  static Path buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    var i = 0;

    // Top edge, left to right.
    path.moveTo(0, _tooth * _bites[0]);
    for (double x = 0; x < w; x += _step) {
      path.lineTo(x, _tooth * _bites[i % _bites.length]);
      i++;
    }
    path.lineTo(w, _tooth * _bites[i % _bites.length]);

    // Right side straight down.
    path.lineTo(w, h - _tooth);

    // Bottom edge, right to left.
    for (double x = w; x > 0; x -= _step) {
      path.lineTo(x, h - _tooth * _bites[i % _bites.length]);
      i++;
    }
    path.lineTo(0, h - _tooth * _bites[i % _bites.length]);

    // Left side straight up, then close.
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornReceiptClipper oldClipper) => false;
}

/// Strokes a thin line along the torn silhouette so the ragged edge stays
/// legible even when the card and the page behind it are near the same tone
/// (light mode). Painted as an overlay ON the card — centred on the same tear
/// path the [PhysicalShape] clips to — so the line sits exactly on the edge
/// and traces every tooth tip rather than cutting their corners.
class _TornEdgePainter extends CustomPainter {
  const _TornEdgePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(_TornReceiptClipper.buildPath(size), paint);
  }

  @override
  bool shouldRepaint(_TornEdgePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Fills the torn silhouette in a contrasting tone, offset down-right and
/// drawn behind the card, so the paper reads as having thickness — an extruded
/// "side" peeking out along the bottom-right. Shares the tear path with the
/// clipper so the thickness follows the same teeth.
class _TornExtrudePainter extends CustomPainter {
  const _TornExtrudePainter({
    required this.color,
    required this.dx,
    required this.dy,
  });

  final Color color;
  final double dx;
  final double dy;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.drawPath(_TornReceiptClipper.buildPath(size), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TornExtrudePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dx != dx ||
      oldDelegate.dy != dy;
}
