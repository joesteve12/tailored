import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/models/payment.dart';
import '../../payments/state/payment_providers.dart';
import '../models/order.dart';
import '../models/status_event.dart';
import '../state/order_detail_notifier.dart';
import '../state/order_list_notifier.dart';
import '../state/status_events_providers.dart';
import '../../tasks/models/task_event.dart';
import '../../tasks/state/tasks_providers.dart';
import '../../tasks/utils/task_labels.dart';

/// The Activity section on the order-detail screen — a Payments | Status
/// pill toggle over the audit log for this order. Modelled on the Darzee
/// reference screenshots the owner shared.
///
/// Two tabs:
///   • Payments — every payment recorded against this order, including
///     voided ones (rendered greyed / struck-through). Active rows have a
///     void action; voided rows do not. This is the *only* place payment
///     history is shown; the money-summary card above only owns the
///     record-payment action.
///   • Status — the append-only log of order- and item-status transitions,
///     backed by `GET /orders/{id}/status-events`. Written by the backend
///     on `PATCH /orders/{id}/status` and on item edits where `status`
///     moves. The order detail notifier invalidates `statusEventsProvider`
///     after those mutations so this tab refetches. The log starts empty
///     for orders that predate Phase 1 — nothing to backfill from.
///
/// Both tabs cap the visible area to roughly four rows and scroll beyond
/// that (see [_ScrollableEntries]), so a long history doesn't push the rest
/// of the screen away.
///
/// Deliberately no actor chip ("joe · owner · …"): the app is single-owner
/// and every entry has the same actor. Rendering it on every row would be
/// noise. If sub-users are ever added, this is where the chip would go.
class OrderActivitySection extends ConsumerStatefulWidget {
  const OrderActivitySection({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderActivitySection> createState() =>
      _OrderActivitySectionState();
}

enum _ActivityTab { payments, status }

class _OrderActivitySectionState extends ConsumerState<OrderActivitySection> {
  _ActivityTab _tab = _ActivityTab.payments;

  /// Id of the payment currently being voided — drives a per-row spinner
  /// while the DELETE (soft delete) is in flight.
  String? _voidingId;

  String get _orderId => widget.order.id;

  void _refreshAfterVoid() {
    // Same three surfaces as the record-payment path in PaymentSection:
    // log, order detail (paid/balance move), orders list (payment_status).
    ref.invalidate(paymentsProvider(_orderId));
    ref.read(orderDetailProvider(_orderId).notifier).refresh();
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  Future<void> _voidPayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void payment?'),
        content: Text(
          'Remove the ${payment.amount.toStringAsFixed(2)} '
          '${paymentMethodLabel(payment.method).toLowerCase()} payment? '
          'It stays in the log as voided, and the balance goes back up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _voidingId = payment.id);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .voidPayment(_orderId, payment.id);
      _refreshAfterVoid();
      if (mounted) showSuccessSnackbar(context, 'Payment voided');
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not void payment');
      }
    } finally {
      if (mounted) setState(() => _voidingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _TabPills(
          current: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: 12),
        switch (_tab) {
          _ActivityTab.payments => _PaymentsTab(
              orderId: _orderId,
              onVoid: _voidPayment,
              voidingId: _voidingId,
            ),
          _ActivityTab.status => _StatusTab(orderId: _orderId),
        },
      ],
    );
  }
}

// ── Pill tab picker ─────────────────────────────────────────────────────

class _TabPills extends StatelessWidget {
  const _TabPills({required this.current, required this.onChanged});

  final _ActivityTab current;
  final ValueChanged<_ActivityTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _Pill(
          label: 'Payments',
          selected: current == _ActivityTab.payments,
          onTap: () => onChanged(_ActivityTab.payments),
        ),
        _Pill(
          label: 'Status',
          selected: current == _ActivityTab.status,
          onTap: () => onChanged(_ActivityTab.status),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.onSurface : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.onSurface : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.surface : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scrollable, height-capped entry list ────────────────────────────────

/// Caps a list of activity rows to roughly four rows tall, then scrolls.
///
/// Row heights vary (a payment row with a note is taller than a bare status
/// row), so the cap is a pixel [maxHeight], not an exact count — "four rows"
/// is an approximation tuned per tab. Below the cap the region shrinks to
/// its content (nothing reserved); above it, an always-visible scrollbar
/// signals there's more.
///
/// Owns its own [ScrollController] (and disposes it) so the inner scroll
/// view never latches onto the order-detail screen's PrimaryScrollController
/// — the two vertical scrollables then coexist cleanly.
class _ScrollableEntries extends StatefulWidget {
  const _ScrollableEntries({
    required this.children,
    required this.maxHeight,
  });

  final List<Widget> children;
  final double maxHeight;

  @override
  State<_ScrollableEntries> createState() => _ScrollableEntriesState();
}

class _ScrollableEntriesState extends State<_ScrollableEntries> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          // Small right pad so rows don't sit under the scrollbar thumb.
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}

// ── Payments tab ────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({
    required this.orderId,
    required this.onVoid,
    required this.voidingId,
  });

  final String orderId;
  final ValueChanged<Payment> onVoid;
  final String? voidingId;

  /// ~4 payment rows. Payment rows run taller than status rows (amount +
  /// method line, sometimes a note), so this cap is a touch higher.
  static const double _maxHeight = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider(orderId));
    return paymentsAsync.when(
      loading: () => const _TabLoader(),
      error: (err, _) => AsyncErrorView(
        error: err,
        compact: true,
        onRetry: () async => ref.invalidate(paymentsProvider(orderId)),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return const _EmptyText(text: 'No payments yet.');
        }
        return _ScrollableEntries(
          maxHeight: _maxHeight,
          children: [
            for (final p in payments)
              _PaymentRow(
                payment: p,
                busy: voidingId == p.id,
                voidingLocked: voidingId != null,
                onVoid: () => onVoid(p),
              ),
          ],
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.busy,
    required this.voidingLocked,
    required this.onVoid,
  });

  final Payment payment;
  final bool busy;
  final bool voidingLocked;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = payment.isVoided;
    final amountStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: muted ? scheme.outline : Colors.green.shade700,
          decoration: muted ? TextDecoration.lineThrough : null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EntryDot(color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniChip(
                      label: 'Payment',
                      color: muted
                          ? scheme.surfaceContainerHighest
                          : Colors.green.shade50,
                      textColor: muted ? scheme.outline : Colors.green.shade800,
                    ),
                    if (muted) ...[
                      const SizedBox(width: 6),
                      _MiniChip(
                        label: 'Voided',
                        color: scheme.surfaceContainerHighest,
                        textColor: scheme.outline,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, payment.paidAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(payment.amount.toStringAsFixed(2), style: amountStyle),
                    const SizedBox(width: 8),
                    Text(
                      'via ${paymentMethodLabel(payment.method)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: muted ? scheme.outline : null,
                          ),
                    ),
                  ],
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      payment.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (!muted)
            (busy
                ? const Padding(
                    padding: EdgeInsets.only(right: 8, top: 4),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Void',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: voidingLocked ? null : onVoid,
                  )),
        ],
      ),
    );
  }
}

// ── Status tab ──────────────────────────────────────────────────────────

class _StatusTab extends ConsumerWidget {
  const _StatusTab({required this.orderId});

  final String orderId;

  /// ~4 status rows. These are shorter than payment rows (no amount/method
  /// line), so the cap is a little lower.
  static const double _maxHeight = 320;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Two feeds, one tab: order-level status transitions
    // (status_events — 'item' rows are no longer produced) and the
    // item-level task history (task_events — created / started / finished
    // / sent back / …, which SURVIVES task deletion by design). Merged
    // here by timestamp rather than server-side so each feed keeps its
    // own shape and invalidation.
    final statusAsync = ref.watch(statusEventsProvider(orderId));
    final taskAsync = ref.watch(orderTaskEventsProvider(orderId));

    if (statusAsync.isLoading || taskAsync.isLoading) {
      return const _TabLoader();
    }
    final err = statusAsync.hasError
        ? statusAsync.error
        : (taskAsync.hasError ? taskAsync.error : null);
    if (err != null) {
      return AsyncErrorView(
        error: err,
        compact: true,
        onRetry: () async {
          ref.invalidate(statusEventsProvider(orderId));
          ref.invalidate(orderTaskEventsProvider(orderId));
        },
      );
    }

    final statusEvents = statusAsync.value ?? const [];
    final taskEvents = taskAsync.value ?? const [];
    if (statusEvents.isEmpty && taskEvents.isEmpty) {
      return const _EmptyText(text: 'No activity yet.');
    }

    // Newest first across both sources.
    final merged = <({DateTime at, Widget row})>[
      for (final e in statusEvents)
        (at: e.createdAt, row: _StatusEventRow(event: e)),
      for (final e in taskEvents)
        (at: e.createdAt, row: _TaskEventRow(event: e)),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return _ScrollableEntries(
      maxHeight: _maxHeight,
      children: [for (final m in merged) m.row],
    );
  }
}

/// One task_events row: "Agbada — Stage finished · Stitching — Musa". The
/// snapshots (`itemLabel`, `detail`) carry the specifics, so this renders
/// correctly even for tasks that have since been deleted.
class _TaskEventRow extends StatelessWidget {
  const _TaskEventRow({required this.event});

  final TaskEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = event.itemLabel;
    final detail = event.detail;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EntryDot(color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniChip(
                  label: 'Task',
                  color: Colors.indigo.shade50,
                  textColor: Colors.indigo.shade800,
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, event.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (label != null && label.isNotEmpty) label,
                    taskEventActionLabel(event.action),
                    if (detail != null && detail.isNotEmpty) detail,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusEventRow extends StatelessWidget {
  const _StatusEventRow({required this.event});

  final OrderStatusEvent event;

  /// Order-status labels. 'item' rows are no longer produced (that flow
  /// moved to task_events) and dev data predating the change was wiped —
  /// but a stray legacy row still renders as its raw wire value rather
  /// than crashing on a deleted helper.
  String _renderStatus(String wire) {
    return event.entityType == 'item' ? wire : orderStatusLabel(wire);
  }

  String _lineText() {
    final from = _renderStatus(event.fromStatus);
    final to = _renderStatus(event.toStatus);
    if (event.entityType == 'item') {
      final label = event.itemLabel ?? 'Outfit';
      return '#$label: $from → $to';
    }
    return 'Order: $from → $to';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EntryDot(color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniChip(
                  label: 'Status',
                  color: Colors.blue.shade50,
                  textColor: Colors.blue.shade800,
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, event.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lineText(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small shared bits ───────────────────────────────────────────────────

class _EntryDot extends StatelessWidget {
  const _EntryDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.circle, size: 10, color: color),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _TabLoader extends StatelessWidget {
  const _TabLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

/// "today at 11:24 AM" / "Jun 16 at 5:55 PM" / "Jun 16, 2025 at …" —
/// matches the reference screenshots' tone.
String _fmtTimestamp(BuildContext context, DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;

  final localizedTime = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );

  if (isToday) return 'today at $localizedTime';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final monthName = months[local.month - 1];
  final sameYear = local.year == now.year;
  final head = sameYear
      ? '$monthName ${local.day}'
      : '$monthName ${local.day}, ${local.year}';
  return '$head at $localizedTime';
}
