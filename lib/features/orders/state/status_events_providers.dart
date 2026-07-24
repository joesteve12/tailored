import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/status_event.dart';

/// The status-event log for one order — backs the Activity → Status tab.
///
/// Shape mirrors `paymentsProvider`: a `FutureProvider.family` keyed by
/// order id, auto-disposed when the detail screen goes away. It's read by
/// the activity section and invalidated by:
///   - order-status changes (which write an 'order' event)
///   - item-status changes on edit (which write an 'item' event)
///
/// The invalidation is fired from the order detail notifier so the section
/// doesn't need to know which mutations feed the log.
final statusEventsProvider =
    FutureProvider.family<List<OrderStatusEvent>, String>(
  (ref, orderId) async {
    return ref.read(orderRepositoryProvider).listStatusEvents(orderId);
  },
);
