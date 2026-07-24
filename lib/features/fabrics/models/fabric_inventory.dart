import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'fabric_inventory.freezed.dart';
part 'fabric_inventory.g.dart';

/// One fabric in the shop inventory — mirrors the backend `FabricInventoryItem`
/// returned by `GET /fabrics`. This is a read-only projection that already
/// resolves the order the fabric belongs to (`orderNumber` / `orderId`) and the
/// client/guest it's for (`recipientName`), so the list needs no further
/// lookups.
///
/// `quantity` arrives as a JSON number (the backend encodes its Decimal → float
/// for this view) and may be null; [nullableDecimalToDouble] tolerates number,
/// Decimal-string, or null. `productionState` / `recipientType` are left plain
/// strings, matching the rest of the app's "don't hardcode the backend's
/// vocabulary into a Dart enum" stance — render them through the shared label
/// helpers.
@freezed
class FabricInventoryItem with _$FabricInventoryItem {
  const factory FabricInventoryItem({
    required String id,
    required String serial,
    String? details,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
    String? unit,
    @JsonKey(name: 'order_item_id') required String orderItemId,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'garment_type') required String garmentType,
    @JsonKey(name: 'production_state') required String productionState,
    @JsonKey(name: 'recipient_type') required String recipientType,
    @JsonKey(name: 'recipient_name') String? recipientName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _FabricInventoryItem;

  factory FabricInventoryItem.fromJson(Map<String, dynamic> json) =>
      _$FabricInventoryItemFromJson(json);
}

/// Single-fabric lookup — mirrors the backend `FabricInventoryDetail` returned
/// by `GET /fabrics/{serial}`. Everything in [FabricInventoryItem] plus the
/// order's status and due date and the recipient's phone, so a "scanned a tag"
/// screen can act on the fabric (call the client, open the order) without
/// another round-trip.
@freezed
class FabricInventoryDetail with _$FabricInventoryDetail {
  const factory FabricInventoryDetail({
    required String id,
    required String serial,
    String? details,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
    String? unit,
    @JsonKey(name: 'order_item_id') required String orderItemId,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'garment_type') required String garmentType,
    @JsonKey(name: 'production_state') required String productionState,
    @JsonKey(name: 'recipient_type') required String recipientType,
    @JsonKey(name: 'recipient_name') String? recipientName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'order_status') String? orderStatus,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'recipient_phone') String? recipientPhone,
  }) = _FabricInventoryDetail;

  factory FabricInventoryDetail.fromJson(Map<String, dynamic> json) =>
      _$FabricInventoryDetailFromJson(json);
}
