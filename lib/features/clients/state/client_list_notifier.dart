import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../data/client_repository.dart';
import 'client_list_state.dart';

class ClientListNotifier extends AsyncNotifier<ClientListState> {
  Timer? _debounce;

  @override
  Future<ClientListState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null) {
      return const ClientListState();
    }
    return _fetchPage(page: 1, search: '');
  }

  Future<ClientListState> _fetchPage({
    required int page,
    required String search,
  }) async {
    final response = await ref.read(clientRepositoryProvider).list(
          search: search,
          page: page,
        );
    return ClientListState(
      items: response.results,
      page: response.page,
      total: response.total,
      searchQuery: search,
    );
  }

  /// Re-runs page 1 with the current search query. Call this after a
  /// create, update, or delete so the list reflects the change — those
  /// operations happen on other screens and don't touch this notifier's
  /// state on their own.
  Future<void> refresh() async {
    final currentQuery = state.valueOrNull?.searchQuery ?? '';
    state = const AsyncLoading<ClientListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _fetchPage(page: 1, search: currentQuery),
    );
  }

  /// Fetches the next page and appends it. No-ops if already loading more
  /// or if the current page is already the last one — safe to call
  /// repeatedly from a scroll listener without extra guards on the
  /// caller's side.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final response = await ref.read(clientRepositoryProvider).list(
            search: current.searchQuery,
            page: current.page + 1,
          );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...response.results],
          page: response.page,
          total: response.total,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // The existing page of results is still good — only the "load more"
      // attempt failed, so drop back to not-loading rather than surfacing
      // a full-screen error and losing what's already on screen.
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Debounced (400ms) so typing a search term doesn't fire a request per
  /// keystroke. Cancels any pending search if called again before the
  /// delay elapses.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading<ClientListState>().copyWithPrevious(state);
      state = await AsyncValue.guard(() => _fetchPage(page: 1, search: query));
    });
  }
}

final clientListProvider =
    AsyncNotifierProvider<ClientListNotifier, ClientListState>(
  ClientListNotifier.new,
);
