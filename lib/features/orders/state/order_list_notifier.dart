import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../../core/utils/fake_latency.dart';
import '../data/order_repository.dart';
import '../models/order.dart';
import 'order_list_state.dart';

class OrderListNotifier extends AsyncNotifier<OrderListState> {
  @override
  Future<OrderListState> build() async {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null) {
      return const OrderListState();
    }
    return _fetchPage(page: 1, filters: const OrderListState());
  }

  /// Routes a page request to `/orders/search` when a query is active, or
  /// `/orders` otherwise — the active filters ride along either way (search
  /// takes the subset it supports). Keeps list and search paginating through
  /// the exact same call sites.
  Future<OrderListResponse> _requestPage(OrderListState filters, int page) {
    final repo = ref.read(orderRepositoryProvider);
    final query = filters.query?.trim() ?? '';
    if (query.isEmpty) {
      return repo.list(
        orderStatus: filters.orderStatus,
        paymentStatus: filters.paymentStatus,
        clientId: filters.clientId,
        priority: filters.priority,
        dueBefore: filters.dueBefore,
        dueAfter: filters.dueAfter,
        sortBy: filters.sortBy,
        page: page,
      );
    }
    return repo.search(
      query: query,
      orderStatus: filters.orderStatus,
      paymentStatus: filters.paymentStatus,
      priority: filters.priority,
      sortBy: filters.sortBy,
      page: page,
    );
  }

  Future<OrderListState> _fetchPage({
    required int page,
    required OrderListState filters,
  }) async {
    await fakeLatency(); // no-op unless kFakeLatency is on in a debug build
    final response = await _requestPage(filters, page);
    return filters.copyWith(
      items: response.results,
      page: response.page,
      total: response.total,
    );
  }

  /// Re-runs page 1 with whatever filters are currently set. Call after
  /// create/update/delete/status-change so the list reflects it.
  Future<void> refresh() async {
    final current = state.valueOrNull ?? const OrderListState();
    state = const AsyncLoading<OrderListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(page: 1, filters: current));
  }

  /// Replaces filters and refetches from page 1. `clear*` flags explicitly
  /// remove a filter rather than leaving it untouched — a filter that's
  /// merely "not passed this call" must stay distinguishable from one the
  /// user deliberately cleared.
  Future<void> setFilters({
    String? orderStatus,
    String? paymentStatus,
    String? clientId,
    String? priority,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? sortBy,
    bool clearOrderStatus = false,
    bool clearPaymentStatus = false,
    bool clearClientId = false,
    bool clearPriority = false,
    bool clearDueBefore = false,
    bool clearDueAfter = false,
    bool clearSortBy = false,
  }) async {
    final current = state.valueOrNull ?? const OrderListState();
    final updated = current.copyWith(
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      clientId: clientId,
      priority: priority,
      dueBefore: dueBefore,
      dueAfter: dueAfter,
      sortBy: sortBy,
      clearOrderStatus: clearOrderStatus,
      clearPaymentStatus: clearPaymentStatus,
      clearClientId: clearClientId,
      clearPriority: clearPriority,
      clearDueBefore: clearDueBefore,
      clearDueAfter: clearDueAfter,
      clearSortBy: clearSortBy,
    );
    state = const AsyncLoading<OrderListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(page: 1, filters: updated));
  }

  /// Sets (or clears, when blank) the free-text search term and refetches
  /// from page 1. Debouncing lives in the UI; this fires the request.
  Future<void> setQuery(String query) async {
    final current = state.valueOrNull ?? const OrderListState();
    final trimmed = query.trim();
    // No-op if the term hasn't actually changed — avoids a redundant refetch
    // on every keystroke the debounce lets through unchanged.
    if ((current.query ?? '') == trimmed) return;
    final updated = current.copyWith(
      query: trimmed.isEmpty ? null : trimmed,
      clearQuery: trimmed.isEmpty,
    );
    state = const AsyncLoading<OrderListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(page: 1, filters: updated));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final response = await _requestPage(current, current.page + 1);
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

final orderListProvider =
    AsyncNotifierProvider<OrderListNotifier, OrderListState>(
  OrderListNotifier.new,
);
