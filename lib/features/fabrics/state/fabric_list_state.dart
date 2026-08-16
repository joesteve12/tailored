import '../models/fabric_inventory.dart';

/// Paged state for the fabric inventory list. A plain class with a hand-written
/// copyWith (not freezed) — it never crosses a JSON boundary, so codegen would
/// just be one more file to regenerate for no benefit. Mirrors the clients
/// list's `ClientListState`.
class FabricListState {
  const FabricListState({
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.searchQuery = '',
    this.isLoadingMore = false,
  });

  final List<FabricInventoryItem> items;
  final int page;
  final int total;
  final String searchQuery;

  /// True while a `loadMore` fetch is in flight — drives the trailing spinner
  /// and guards against firing overlapping page requests from the scroll
  /// listener.
  final bool isLoadingMore;

  /// More rows exist on the server than we've loaded so far.
  bool get hasMore => items.length < total;

  FabricListState copyWith({
    List<FabricInventoryItem>? items,
    int? page,
    int? total,
    String? searchQuery,
    bool? isLoadingMore,
  }) {
    return FabricListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
