# Patch: `lib/features/orders/data/order_repository.dart`

Two edits — one import, one method.

---

## 1. Extend the imports (top of the file)

```diff
 import '../models/order.dart';
 import '../models/order_item.dart';
 import '../models/order_media.dart';
+import '../models/status_event.dart';
```

---

## 2. New method on `OrderRepository`

Add anywhere in the class — a natural spot is right after `getById`, so all
the read methods live together.

```dart
  /// GET /orders/{id}/status-events → the append-only log of order- and
  /// item-status transitions. Newest first. Backs the Activity → Status
  /// tab. Returns just the rows (the `total` in the envelope is currently
  /// unused on the client).
  Future<List<OrderStatusEvent>> listStatusEvents(String orderId) async {
    final response = await _dio.get('/orders/$orderId/status-events');
    final data = response.data as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
```
