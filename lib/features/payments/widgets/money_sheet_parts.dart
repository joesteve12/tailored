import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/errors.dart';
import '../../orders/models/order.dart';
import '../models/payment.dart';

/// Pieces shared by the three money sheets — record payment, record refund,
/// log a tip. Extracted rather than copied because all three have to agree
/// with the *same* backend rule; three copies of a date floor is three
/// chances to drift out of step with the server and start producing 400s
/// that look like bugs in the wrong place.

/// The earliest date a new money row on this order may carry.
///
/// Mirrors the backend exactly: the latest `paidAt` already on this order,
/// or the order's `createdAt` when there are none. The server enforces it
/// regardless; computing it here just means the user gets a constrained
/// picker instead of a rejection after the fact.
///
/// The floor exists because receipts freeze a running balance. A payment
/// slipped in before an existing one would produce a receipt whose "balance
/// remaining" contradicts the one the client is already holding, and neither
/// would be wrong on its own terms.
///
/// Note the consequence on a fresh order: the first payment can't be dated
/// before the order was entered. A shop that took a deposit on Monday and
/// entered the order on Wednesday has to date that deposit Wednesday.
DateTime paymentFloorFor(List<Payment> payments, Order order) {
  var floor = order.createdAt;
  for (final payment in payments) {
    if (payment.paidAt.isAfter(floor)) floor = payment.paidAt;
  }
  return floor;
}

/// Normalises a date chosen in a picker into the timestamp to send.
///
/// **Midday local, deliberately.** A picker hands back local midnight, and
/// the repository converts to UTC before sending. In WAT (UTC+1) local
/// midnight is 23:00 the *previous* day in UTC — and the backend compares
/// `paid_at` against its floor at UTC date granularity, so an ordinary
/// "I took this today" would be filed as yesterday and rejected. Noon is the
/// same calendar day in UTC for any offset within ±12h, which makes the
/// user's idea of the date and the server's agree.
DateTime middayOn(DateTime date) =>
    DateTime(date.year, date.month, date.day, 12);

/// Prefers the backend's 400 `detail` over a generic description.
///
/// Those messages name the actual figure — the outstanding balance, the
/// refundable amount, the date floor — which is far more use than
/// "Something went wrong" when a client-side guard is raced or a rule
/// differs by a rounding step.
String messageForMoneyError(Object error) {
  if (error is DioException &&
      error.response?.statusCode == 400 &&
      error.response?.data is Map &&
      (error.response!.data as Map)['detail'] is String) {
    return (error.response!.data as Map)['detail'] as String;
  }
  return describeError(error);
}

/// The date row used by all three money sheets. Tapping opens a picker
/// bounded by [floor] and today; the trailing "Today" hint makes it obvious
/// the field is optional and already sensible.
class MoneyDateField extends StatelessWidget {
  const MoneyDateField({
    super.key,
    required this.value,
    required this.floor,
    required this.onChanged,
    this.enabled = true,
  });

  /// Null means "now" — the field hasn't been touched, and the caller should
  /// send no `paid_at` at all rather than stamping a client clock.
  final DateTime? value;
  final DateTime floor;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Guard against a floor in the future (a backdated-then-corrected row, or
    // clock skew): showDatePicker asserts if firstDate is after lastDate.
    final first = floor.isAfter(now) ? now : floor;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Date received'),
      subtitle: Text(
        value == null ? 'Today' : _fmtDate(value!),
        style: TextStyle(color: scheme.outline),
      ),
      trailing: const Icon(Icons.calendar_today, size: 18),
      onTap: !enabled
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(first.year, first.month, first.day),
                lastDate: now,
              );
              if (picked != null) onChanged(middayOn(picked));
            },
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
