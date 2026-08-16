import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fabric_repository.dart';
import '../models/fabric_inventory.dart';
import 'fabric_list_state.dart';

/// The fabric inventory list, paged. Fetches a page at a time (see
/// [FabricRepository.list]) and appends as the user scrolls, so opening the
/// screen no longer pulls the shop's entire fabric table in one request.
///
/// `autoDispose` so the cache clears when the inventory screen closes — the
/// same lifetime the old family provider had. Search lives inside the notifier
/// (debounced) rather than in a separate provider, mirroring the clients list.
class FabricListNotifier extends AutoDisposeAsyncNotifier<FabricListState> {
  Timer? _debounce;

  @override
  Future<FabricListState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    return _fetchPage(page: 1, search: '');
  }

  Future<FabricListState> _fetchPage({
    required int page,
    required String search,
  }) async {
    final result =
        await ref.read(fabricRepositoryProvider).list(search: search, page: page);
    return FabricListState(
      items: result.items,
      page: page,
      total: result.total,
      searchQuery: search,
    );
  }

  /// Re-runs page 1 with the current query — the pull-to-refresh / retry path.
  Future<void> refresh() async {
    final query = state.valueOrNull?.searchQuery ?? '';
    state = const AsyncLoading<FabricListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(page: 1, search: query));
  }

  /// Fetches the next page and appends it. No-ops if a page is already in
  /// flight or we're already at the end, so it's safe to call repeatedly from a
  /// scroll listener. On failure the existing rows stay put — only the spinner
  /// clears — and the error rethrows so the caller can surface a toast.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(fabricRepositoryProvider).list(
            search: current.searchQuery,
            page: current.page + 1,
          );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          page: current.page + 1,
          total: result.total,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Debounced (300ms) search so typing doesn't fire a request per keystroke;
  /// the latest query wins. Resets back to page 1.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      state = const AsyncLoading<FabricListState>().copyWithPrevious(state);
      state = await AsyncValue.guard(() => _fetchPage(page: 1, search: query));
    });
  }
}

final fabricListProvider =
    AsyncNotifierProvider.autoDispose<FabricListNotifier, FabricListState>(
  FabricListNotifier.new,
);

/// One fabric by serial — backs the detail screen. `autoDispose` family keyed
/// by serial.
final fabricDetailProvider = FutureProvider.autoDispose
    .family<FabricInventoryDetail, String>((ref, serial) async {
  return ref.read(fabricRepositoryProvider).getBySerial(serial);
});
