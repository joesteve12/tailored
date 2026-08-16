import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/order_labels.dart';

/// Shared field widgets for the order forms — the create screen, the
/// edit-details sheet, and the discount sheet all dress the same controls the
/// same way, so they live here once rather than being re-derived per surface
/// (which is how the create form and the edit dialog drifted apart before).

/// The four order priorities as a row of selectable pills, each dotted with the
/// colour the rest of the app already uses for that priority so the selection
/// reads at a glance. Wraps on narrow widths.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in kPriorities)
          () {
            final selected = p == value;
            final dot = priorityDotColor(context, p);
            return InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.12)
                      : tokens.inputBackground,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      priorityLabel(p),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selected
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// Priority dot colour, matching the semantics used elsewhere in the app:
/// high rides the error role, urgent the orange attention colour; low/normal
/// stay quiet.
Color priorityDotColor(BuildContext context, String priority) {
  final scheme = Theme.of(context).colorScheme;
  switch (priority) {
    case 'urgent':
      return StatusColors.urgent;
    case 'high':
      return StatusColors.priorityHigh(scheme);
    case 'normal':
      return context.appTokens.chart3;
    case 'low':
    default:
      return scheme.onSurfaceVariant;
  }
}

/// A tappable, input-styled tile showing a chosen date and how far out it is.
/// Presentational only — the owner supplies [onTap] and runs its own
/// `showDatePicker` (the create form floors on tomorrow, the edit sheet allows
/// past dates), so the picking policy stays with the caller.
class DueDateTile extends StatelessWidget {
  const DueDateTile({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final days = date.difference(_todayAtMidnight()).inDays;
    final relative = days < 0
        ? '${-days} day${days == -1 ? '' : 's'} ago'
        : days == 0
            ? 'today'
            : days == 1
                ? 'tomorrow'
                : 'in $days days';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.inputBackground,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              _fmtLongDate(date),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              relative,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_outlined, size: 18, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// The discount control on a single row: a compact ₦ / % mode toggle on the
/// left and the value field beside it. Leaving the value **empty means "no
/// discount"** — there is deliberately no separate "None" option; the empty
/// field is the off state. The mode only decides how a *present* value is read
/// (a flat naira amount vs a percentage of the subtotal).
///
/// The caller derives the wire discount type from the value: empty or
/// non-positive → 'none', otherwise the selected [mode]. The backend still
/// recomputes the authoritative `discount_amount`.
class DiscountField extends StatelessWidget {
  const DiscountField({
    super.key,
    required this.mode,
    required this.valueController,
    required this.onModeChanged,
  });

  /// 'fixed' or 'percentage' — never 'none' (an empty value carries that).
  final String mode;
  final TextEditingController valueController;
  final ValueChanged<String> onModeChanged;

  /// Shared height so the toggle and the field line up exactly.
  static const double _height = 52;

  static const _modes = <(String, String)>[
    ('fixed', kNairaSign),
    ('percentage', '%'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Row(
      children: [
        Container(
          height: _height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tokens.inputBackground,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (wire, label) in _modes)
                GestureDetector(
                  onTap: () => onModeChanged(wire),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mode == wire ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(tokens.radiusSm),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: mode == wire
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: _height,
            child: TextField(
              controller: valueController,
              textAlignVertical: TextAlignVertical.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                prefixText: mode == 'fixed' ? '$kNairaSign ' : null,
                suffixText: mode == 'percentage' ? '%' : null,
                hintText: 'No discount',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

DateTime _todayAtMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtLongDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';
