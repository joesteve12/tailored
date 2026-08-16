import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_repository.dart';

/// Revenue and order/guest counts for the stats strip on the client detail
/// screen.
///
/// Backed by `GET /clients/{id}/stats`. Mirrors the backend's
/// ClientStatsResponse: `revenue` is cash collected net of refunds (not
/// invoiced), `outstanding` is what's still owed across non-cancelled orders,
/// and both money figures are in naira. See services/client.get_client_stats
/// for the exact definitions.
class ClientStats {
  const ClientStats({
    required this.revenue,
    required this.outstanding,
    required this.refundDue,
    required this.activeOrders,
    required this.guests,
  });

  factory ClientStats.fromJson(Map<String, dynamic> json) {
    return ClientStats(
      revenue: (json['revenue'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
      refundDue: (json['refund_due'] as num).toDouble(),
      activeOrders: (json['active_orders'] as num).toInt(),
      guests: (json['guests'] as num).toInt(),
    );
  }

  /// Cash collected from this client, in naira, net of refunds.
  final double revenue;

  /// Amount still owed by the client across their orders, in naira. Zero
  /// means the client owes nothing.
  final double outstanding;

  /// The mirror of [outstanding]: money the shop owes back on overpaid
  /// orders, in naira. Zero unless a refund is due. Can be positive at the
  /// same time as [outstanding] — one order underpaid, another overpaid.
  final double refundDue;

  /// True only when neither side owes the other — nothing outstanding from
  /// the client and no refund due back to them.
  bool get fullySettled => outstanding <= 0 && refundDue <= 0;

  /// Orders not yet delivered or cancelled.
  final int activeOrders;

  final int guests;
}

/// A ``family`` keyed by client id so distinct clients cache independently,
/// and ``autoDispose`` so the cache clears when the detail screen closes —
/// the same shape as [clientOrdersProvider]. Readers get an
/// `AsyncValue<ClientStats>` and handle its loading/error states (the stats
/// strip on the client detail screen does).
final clientStatsProvider = FutureProvider.autoDispose
    .family<ClientStats, String>((ref, clientId) async {
  return ref.read(clientRepositoryProvider).stats(clientId);
});
