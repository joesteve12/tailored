import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/order.dart';

/// Orders for a single client, newest first — backs the Orders section on the
/// client detail screen. A ``family`` keyed by client id so distinct clients
/// cache independently, and ``autoDispose`` so the cache clears when the
/// screen closes.
///
/// Kept separate from the global [orderListProvider] on purpose: that provider
/// owns the main Orders screen's filter/pagination state, and having the
/// client detail piggyback on it would either (a) fight over shared filter
/// state or (b) reset the user's filters every time they open a client. The
/// backend endpoint already accepts ``client_id`` as a filter, so an
/// independent read here is a one-shot ``list(clientId: …)`` call with no
/// downside.
///
/// Refresh model: the client detail's pull-to-refresh invalidates this
/// provider. Creating an order from the section's "New order" button opens
/// the order form; on return, the section will still show the pre-creation
/// list until the next pull-to-refresh (or reopening the client). If that
/// staleness becomes annoying, invalidate this family from the order-form
/// success path.
final clientOrdersProvider = FutureProvider.autoDispose
    .family<List<Order>, String>((ref, clientId) async {
  final response = await ref.read(orderRepositoryProvider).list(
        clientId: clientId,
        pageSize: 20,
      );
  return response.results;
});
