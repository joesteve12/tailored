import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_event.freezed.dart';
part 'status_event.g.dart';

/// One entry in an order's status-change log, as returned by
/// `GET /orders/{id}/status-events`. Newest-first from the server.
///
/// `entityType` is `'order'` (an order-level status transition) or `'item'`
/// (a per-item transition — `itemId` and `itemLabel` are populated).
/// `itemLabel` is a snapshot of the item's garment name at the time the
/// event was written, so the Activity feed still reads sensibly if the
/// item is later renamed or deleted.
///
/// Status values (`fromStatus`, `toStatus`) are the raw wire strings —
/// `'in_progress'`, `'ready'`, etc. — mapped to human labels at render
/// time (`orderStatusLabel`). Rows with `entityType == 'item'` are legacy:
/// the Task system stopped producing them (item-level history now lives in
/// `task_events`), and pre-existing rows were wiped with the dev data.
@freezed
class OrderStatusEvent with _$OrderStatusEvent {
  const factory OrderStatusEvent({
    required String id,
    @JsonKey(name: 'entity_type') required String entityType,
    @JsonKey(name: 'item_id') String? itemId,
    @JsonKey(name: 'item_label') String? itemLabel,
    @JsonKey(name: 'from_status') required String fromStatus,
    @JsonKey(name: 'to_status') required String toStatus,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _OrderStatusEvent;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusEventFromJson(json);
}
