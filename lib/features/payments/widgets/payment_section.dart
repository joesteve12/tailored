import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/payment_labels.dart';
import '../../orders/models/order.dart';
import '../../orders/state/order_detail_notifier.dart';
import '../../orders/state/order_list_notifier.dart';
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
      if (isPercentage) buffer.write('${trimTrailingZeros(order.discountValue)}%');
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

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: -6,
            child: _Eyelet(
              cardColor: scheme.surfaceContainerHigh,
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
                            fontFamily: 'JetBrainsMono',
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
                            formatNaira(
                                showRefundDue ? order.refundDue : order.balanceDue),
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
                if (order.hasAddons) ...[
                  _leaderRow(scheme, 'Garments', formatNaira(order.itemsSubtotal)),
                  _leaderRow(scheme, 'Extras', formatNaira(order.addonsTotal)),
                ],
                _leaderRow(scheme, 'Subtotal', formatNaira(order.subtotal)),
                if (order.hasDiscount)
                  _leaderRow(
                      scheme, _discountLabel, '-${formatNaira(order.discountAmount)}'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _Perforation(color: scheme.outlineVariant),
                ),
                _totalsRow(scheme, 'Total', formatNaira(order.totalAmount),
                    emphasize: true),
                _totalsRow(scheme, 'Paid', formatNaira(order.amountPaid)),
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
                          borderColor: scheme.outlineVariant,
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
                          borderColor: scheme.outlineVariant,
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
                          borderColor: scheme.outlineVariant,
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
    );
  }

  /// A breakdown line set as a printed ticket item: label, dotted leader,
  /// tabular-figure value. Quieter than the totals block below it — this is
  /// the arithmetic you'd audit, not the number you'd act on.
  Widget _leaderRow(ColorScheme scheme, String label, String value) {
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
              child: _DottedLine(color: scheme.outlineVariant),
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
        ],
      ),
    );
  }

  Widget _totalsRow(ColorScheme scheme, String label, String value,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: emphasize ? 15 : 13.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: emphasize ? 15 : 13.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
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
            fontFamily: 'JetBrainsMono',
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
