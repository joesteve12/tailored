import '../models/order.dart';

/// Hand-written (not freezed) for the same reason as ClientListState: this
/// never crosses a JSON boundary, so codegen buys nothing.
///
/// Filters mirror the orders endpoint's query params — there's no free-text
/// search, only orderStatus / paymentStatus / clientId / priority /
/// dueBefore / dueAfter, plus a `sortBy` (created_at | due_date | priority).
class OrderListState {
  const OrderListState({
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.orderStatus,
    this.paymentStatus,
    this.clientId,
    this.priority,
    this.dueBefore,
    this.dueAfter,
    this.sortBy,
    this.isLoadingMore = false,
  });

  final List<Order> items;
  final int page;
  final int total;
  final String? orderStatus;
  final String? paymentStatus;
  final String? clientId;
  final String? priority;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final String? sortBy;
  final bool isLoadingMore;

  bool get hasMore => items.length < total;
  bool get hasActiveFilters =>
      orderStatus != null ||
      paymentStatus != null ||
      clientId != null ||
      priority != null ||
      dueBefore != null ||
      dueAfter != null;

  OrderListState copyWith({
    List<Order>? items,
    int? page,
    int? total,
    String? orderStatus,
    String? paymentStatus,
    String? clientId,
    String? priority,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? sortBy,
    bool? isLoadingMore,
    bool clearOrderStatus = false,
    bool clearPaymentStatus = false,
    bool clearClientId = false,
    bool clearPriority = false,
    bool clearDueBefore = false,
    bool clearDueAfter = false,
    bool clearSortBy = false,
  }) {
    return OrderListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      orderStatus: clearOrderStatus ? null : (orderStatus ?? this.orderStatus),
      paymentStatus:
          clearPaymentStatus ? null : (paymentStatus ?? this.paymentStatus),
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      priority: clearPriority ? null : (priority ?? this.priority),
      dueBefore: clearDueBefore ? null : (dueBefore ?? this.dueBefore),
      dueAfter: clearDueAfter ? null : (dueAfter ?? this.dueAfter),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
