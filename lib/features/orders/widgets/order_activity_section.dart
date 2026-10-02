import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/utils/share_document.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/models/document_issue.dart';
import '../../documents/state/document_providers.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/widgets/money_sheet_parts.dart';
import '../../payments/widgets/record_refund_sheet.dart';
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
///   • Payments — the order's money timeline: payments, refunds and tips,
///     newest first, each with its own receipt. This is the *only* place
///     history is shown; the money card above owns the actions that create
///     these rows.
///
///     **No voided rows.** Voiding was a server-side soft delete, and every
///     query touching payments had to remember to filter the flag — several
///     didn't. Rows are now either present or really gone, and the record of
///     what was printed survives in `document_issues` instead. Nothing here
///     renders greyed or struck through, and nothing should be added that
///     does.
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

  /// Id of the payment currently being deleted — drives a per-row spinner
  /// while the DELETE is in flight. Null while idle.
  String? _deletingId;

  /// Id of the payment whose receipt is being prepared. Separate from
  /// [_deletingId] so fetching a receipt doesn't grey out the delete actions
  /// on every other row.
  String? _receiptId;

  String get _orderId => widget.order.id;

  void _refreshAfterDelete() {
    // Same three surfaces the money card refreshes after recording. The
    // documents log is invalidated too: the deleted payment's audit row now
    // has a null paymentId, and a stale list would keep claiming a receipt
    // exists for a row that's gone.
    ref.invalidate(paymentsProvider(_orderId));
    ref.invalidate(orderDocumentsProvider(_orderId));
    ref.read(orderDetailProvider(_orderId).notifier).refresh();
    ref.read(orderListProvider.notifier).refresh().catchError((_) {});
  }

  /// Fetches and shares the receipt for one money row.
  ///
  /// Every row has one, including refunds and standalone tips — a client who
  /// was given money back has at least as much reason to want it in writing
  /// as one who handed it over.
  Future<void> _shareReceipt(Payment payment) async {
    final format = await pickDocumentFormat(context);
    if (format == null || !mounted) return;

    setState(() => _receiptId = payment.id);
    try {
      final bytes = await ref.read(documentRepositoryProvider).fetchPaymentReceipt(
            _orderId,
            payment.id,
            format: format.apiValue,
          );
      final label = payment.isRefund ? 'refund' : 'receipt';
      final stem = safeFileSegment(
          payment.receiptNumber ?? widget.order.orderNumber);
      await shareDocumentBytes(
        bytes,
        fileName: '${label}_$stem.${format.extension}',
        mimeType: format.mimeType,
        text: '${payment.isRefund ? 'Refund' : 'Receipt'} · '
            'order ${widget.order.orderNumber}',
      );
      // A receipt has now demonstrably gone out; the delete warning below
      // reads this list to decide how hard to push back.
      ref.invalidate(orderDocumentsProvider(_orderId));
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not prepare receipt');
      }
    } finally {
      if (mounted) setState(() => _receiptId = null);
    }
  }

  /// Looks up whether a receipt has already been generated for this row.
  ///
  /// Failure degrades to null, which makes the dialog show the *stronger*
  /// copy. Erring toward the harsher warning is the right way round for a
  /// destructive action: the cost of over-warning is a moment's reading, the
  /// cost of under-warning is a deleted record of real money.
  Future<DocumentIssue?> _existingReceipt(String paymentId) async {
    try {
      final documents =
          await ref.read(orderDocumentsProvider(_orderId).future);
      return receiptForPayment(documents, paymentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final receipt = await _existingReceipt(payment.id);
    if (!mounted) return;

    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (context) => _DeletePaymentDialog(
        payment: payment,
        receipt: receipt,
      ),
    );
    if (choice == null || !mounted) return;

    // "Log a refund instead" — the honest path when the client actually got
    // the money back. Deleting would make it look like the payment never
    // happened; a refund records both halves of what occurred.
    if (choice == _DeleteChoice.refund) {
      final payments = ref.read(paymentsProvider(_orderId)).valueOrNull ?? [];
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => RecordRefundSheet(
          orderId: _orderId,
          maxAmount: widget.order.amountPaid,
          dateFloor: paymentFloorFor(payments, widget.order),
          initialAmount: payment.amount,
        ),
      );
      if (ok == true) _refreshAfterDelete();
      return;
    }

    setState(() => _deletingId = payment.id);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .deletePayment(_orderId, payment.id);
      _refreshAfterDelete();
      if (mounted) {
        showSuccessSnackbar(
            context, payment.isRefund ? 'Refund deleted' : 'Payment deleted');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not delete');
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
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
              onReceipt: _shareReceipt,
              onDelete: _deletePayment,
              deletingId: _deletingId,
              receiptId: _receiptId,
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
    required this.onReceipt,
    required this.onDelete,
    required this.deletingId,
    required this.receiptId,
  });

  final String orderId;
  final ValueChanged<Payment> onReceipt;
  final ValueChanged<Payment> onDelete;
  final String? deletingId;
  final String? receiptId;

  /// ~4 rows. Money rows run taller than status rows (amount + method line,
  /// sometimes a note or a refund reason), so this cap is a touch higher.
  static const double _maxHeight = 380;

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
        // Only the most recently inserted entry can be deleted: every later
        // row's frozen "balance remaining" counts an earlier one in, so
        // removing one from underneath them would leave those receipts lying.
        // The tail is by insertion order (createdAt), which is not the same as
        // the paid_at-sorted display order once an entry has been back-dated —
        // so the delete action can land on a row that isn't the top one.
        final deletableId = payments
            .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
            .id;
        return _ScrollableEntries(
          maxHeight: _maxHeight,
          children: [
            for (final p in payments)
              _PaymentRow(
                payment: p,
                canDelete: p.id == deletableId,
                deleting: deletingId == p.id,
                preparingReceipt: receiptId == p.id,
                actionsLocked: deletingId != null,
                onReceipt: () => onReceipt(p),
                onDelete: () => onDelete(p),
              ),
          ],
        );
      },
    );
  }
}

/// One row of the money timeline. Three shapes, keyed off the row's kind:
///
///   payment         teal dot,  `+₦50,000`, method · date · RCP-0007
///   payment + tip   as above, with a `Tip ₦5,000` chip
///   standalone tip  amber dot, `Tip ₦5,000`
///   refund          error dot, `−₦9,500`, method · date · reason
///
/// The sign is carried in the text, not only in the colour. Colour alone
/// fails for the substantial minority of men who can't distinguish these
/// hues, and telling a payment from a refund is not an optional detail.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.canDelete,
    required this.deleting,
    required this.preparingReceipt,
    required this.actionsLocked,
    required this.onReceipt,
    required this.onDelete,
  });

  final Payment payment;

  /// Whether this is the deletable tail entry. Only the most recently inserted
  /// payment or refund shows a delete action; older ones are unwound by
  /// deleting the newer ones first, or reversed with a refund.
  final bool canDelete;
  final bool deleting;
  final bool preparingReceipt;
  final bool actionsLocked;
  final VoidCallback onReceipt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRefund = payment.isRefund;
    final isTipOnly = payment.isStandaloneTip;

    final Color accent = isRefund
        ? StatusColors.refund(scheme)
        : isTipOnly
            ? StatusColors.tipAccent
            : StatusColors.paymentAccent;

    final String chipLabel =
        isRefund ? 'Refund' : (isTipOnly ? 'Tip' : 'Payment');

    final String amountText = isTipOnly
        ? 'Tip ${formatNaira(payment.tipAmount)}'
        : formatSignedNaira(payment.signedAmount);

    final amountStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: accent,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EntryDot(
              color: isRefund ? StatusColors.refund(scheme) : StatusColors.paymentDot),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniChip(
                      label: chipLabel,
                      color: isRefund
                          ? scheme.errorContainer
                          : (isTipOnly
                              ? StatusColors.tipChipBg
                              : StatusColors.paymentChipBg),
                      textColor: isRefund ? scheme.onErrorContainer : accent,
                    ),
                    // A tip riding along with a payment gets its own chip so
                    // the amount beside it stays readable as the payment
                    // alone — which is what it is, since tips never count
                    // toward the balance.
                    if (!isTipOnly && payment.hasTip) ...[
                      const SizedBox(width: 6),
                      _MiniChip(
                        label: 'Tip ${formatNaira(payment.tipAmount)}',
                        color: StatusColors.tipChipBg,
                        textColor: StatusColors.tipChipText,
                      ),
                    ],
                    if (payment.receiptNumber != null) ...[
                      const SizedBox(width: 6),
                      _MiniChip(
                        label: payment.receiptNumber!,
                        color: scheme.surfaceContainerHighest,
                        textColor: context.appTokens.mutedForeground,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, payment.paidAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTokens.mutedForeground,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(amountText, style: amountStyle),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'via ${paymentMethodLabel(payment.method)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                // A refund without a reason is worse than no record at all
                // when someone queries the figure a year later, so it always
                // shows.
                if (isRefund && payment.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      payment.reason!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                    ),
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
          if (preparingReceipt)
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 4),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Share receipt',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              onPressed: actionsLocked ? null : onReceipt,
            ),
          // Delete is offered only on the tail entry; the backend refuses any
          // other, since removing it would strand a later receipt's frozen
          // balance. Older entries are unwound newest-first or reversed with a
          // refund.
          if (deleting)
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 4),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (canDelete)
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: actionsLocked ? null : onDelete,
            ),
        ],
      ),
    );
  }
}

/// What the delete dialog came back with.
enum _DeleteChoice { refund, delete }

/// Escalating warning for removing a money row.
///
/// The strength of the copy tracks whether a receipt has already gone out. A
/// client holding a printed receipt for a payment the shop has since deleted
/// is a much worse position than a mistyped figure nobody saw, so that case
/// says so explicitly and names the document.
///
/// Both variants offer **"Log a refund instead"**, because that is the right
/// action in the case operators will most often be in: the client got the
/// money back. Deleting would erase the fact that they ever paid.
class _DeletePaymentDialog extends StatelessWidget {
  const _DeletePaymentDialog({
    required this.payment,
    required this.receipt,
  });

  final Payment payment;
  final DocumentIssue? receipt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRefund = payment.isRefund;
    final amount = payment.isStandaloneTip ? payment.tipAmount : payment.amount;
    final noun = isRefund
        ? 'refund'
        : (payment.isStandaloneTip ? 'tip' : 'payment');

    return AlertDialog(
      title: Text('Delete this ${formatNaira(amount)} $noun?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt != null) ...[
            Text(
              'A receipt (${receipt!.documentNumber ?? 'issued'}) was '
              'generated for this on ${_fmtShortDate(receipt!.generatedAt)}.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            isRefund
                ? 'This removes the record entirely, and the client will look '
                    'as though they were never refunded.'
                : 'This removes the record entirely. Only do this if it was '
                    'entered by mistake.',
          ),
          if (!isRefund) ...[
            const SizedBox(height: 8),
            Text(
              'If the client actually received this money back, log a refund '
              'instead — deleting will make it look like the payment never '
              'happened.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!isRefund)
          TextButton(
            onPressed: () => Navigator.pop(context, _DeleteChoice.refund),
            child: const Text('Log a refund'),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(context, _DeleteChoice.delete),
          child: Text(receipt != null ? 'Delete anyway' : 'Delete'),
        ),
      ],
    );
  }
}

String _fmtShortDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = dt.toLocal();
  return '${local.day} ${months[local.month - 1]}';
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
          const _EntryDot(color: StatusColors.taskDot),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MiniChip(
                  label: 'Task',
                  color: StatusColors.taskChipBg,
                  textColor: StatusColors.taskChipText,
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, event.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTokens.mutedForeground,
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
          const _EntryDot(color: StatusColors.statusDot),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MiniChip(
                  label: 'Status',
                  color: StatusColors.statusChipBg,
                  textColor: StatusColors.statusChipText,
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTimestamp(context, event.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTokens.mutedForeground,
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
              color: context.appTokens.mutedForeground,
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
