import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../models/order.dart';
import 'order_list_state.dart';

/// Orders for a single client, newest first — backs the Orders section on the
/// client detail screen. A ``family`` keyed by client id so distinct clients
/// cache independently, and ``autoDispose`` so the cache clears when the
/// screen closes.
///
/// Returns the whole [OrderListResponse] (not just `results`) so the section
/// can compare `results.length` against `total` and offer a "View all" link
/// into the fully-paginated [clientOrdersPagedProvider] when a client has more
/// orders than this first page shows.
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
    .family<OrderListResponse, String>((ref, clientId) async {
  return ref.read(orderRepositoryProvider).list(
        clientId: clientId,
        pageSize: 20,
      );
});

/// The full, scroll-to-load-more order history for one client — backs the
/// dedicated "all orders" screen reached from the detail section's "View all"
/// link. Scoped per client via a ``family`` and ``autoDispose`` so it doesn't
/// outlive the pushed screen.
///
/// Deliberately separate from the global [orderListProvider] for the same
/// reason [clientOrdersProvider] is (see above): the bottom-nav Orders tab
/// must never inherit a client filter. Reuses [OrderListState] purely as a
/// paging container — only `items` / `page` / `total` / `isLoadingMore` are
/// meaningful here; the filter fields stay unset.
class ClientOrdersPagedNotifier
    extends AutoDisposeFamilyAsyncNotifier<OrderListState, String> {
  @override
  Future<OrderListState> build(String clientId) =>
      _fetchPage(clientId, page: 1);

  Future<OrderListState> _fetchPage(
    String clientId, {
    required int page,
  }) async {
    final response = await ref
        .read(orderRepositoryProvider)
        .list(clientId: clientId, page: page);
    return OrderListState(
      items: response.results,
      page: response.page,
      total: response.total,
      clientId: clientId,
    );
  }

  /// Re-runs page 1. Backs the screen's pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading<OrderListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(arg, page: 1));
  }

  /// Appends the next page. No-op while a page is already in flight or once
  /// everything's loaded (`hasMore` is false).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await ref
          .read(orderRepositoryProvider)
          .list(clientId: arg, page: current.page + 1);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...response.results],
          page: response.page,
          total: response.total,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }
}

final clientOrdersPagedProvider = AsyncNotifierProvider.autoDispose
    .family<ClientOrdersPagedNotifier, OrderListState, String>(
  ClientOrdersPagedNotifier.new,
);
