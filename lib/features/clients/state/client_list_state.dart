import '../models/client.dart';

/// Deliberately a plain class with a hand-written copyWith, not freezed —
/// this state never crosses a JSON boundary, so paying for codegen here
/// would just be one more generated file to regenerate on every field
/// tweak with no real benefit.
class ClientListState {
  const ClientListState({
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.searchQuery = '',
    this.isLoadingMore = false,
  });

  final List<Client> items;
  final int page;
  final int total;
  final String searchQuery;
  final bool isLoadingMore;

  bool get hasMore => items.length < total;

  ClientListState copyWith({
    List<Client>? items,
    int? page,
    int? total,
    String? searchQuery,
    bool? isLoadingMore,
  }) {
    return ClientListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
