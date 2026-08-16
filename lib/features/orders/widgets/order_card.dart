import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// One order row — the shop's order-list card. Extracted from the Orders tab
/// so the Calendar screen renders deadlines with the identical card (same
/// priority rail, status pill, due line, and payment meta) rather than a
/// look-alike. Fed by scalar fields, not a model, so both an [Order] (list)
/// and a lean calendar order can drive it.
///
/// The secondary row under the order number is variable via [subtitle]: the
/// Orders tab and Calendar pass the client name, while a client's own order
/// list — where the client is already the context — passes the order total
/// instead. A null/blank subtitle just hides that line.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.orderNumber,
    required this.subtitle,
    required this.dueDate,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.onTap,
  });

  final String orderNumber;

  /// The secondary line under the order number (client name, order total, …).
  /// Null or blank hides the line entirely.
  final String? subtitle;
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
    // Whatever the caller wants on the secondary line — a client name in the
    // Orders tab, the order total in a client's own list. A null/blank value
    // (e.g. an older row missing a denormalised client name) hides the line.
    final subtitleText = subtitle?.trim() ?? '';

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
                        if (subtitleText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitleText,
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
                                fontWeight: overdue
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
        color: meta.color.withValues(alpha: 0.14),
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

/// Maps the payment status to a color + icon, same normalization approach
/// as [_statusMeta] (lowercased, separators stripped) so "Paid", "PAID",
/// etc. all match the backend's paid/partial/unpaid enum. Unpaid is left
/// at the neutral color — it's the default/expected state, not a problem
/// state. Unrecognized values fall back to the same neutral icon.
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
