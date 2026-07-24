import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'fabric.freezed.dart';
part 'fabric.g.dart';

/// Mirrors the backend `FabricResponse` — one physical fabric on a garment.
/// A garment (order item) can be cut from several, so an item embeds a list of
/// these. `serial` is the tag written on the cloth; it's generated server-side
/// and is therefore read-only here (never sent on create). `quantity` arrives
/// as a JSON number (the backend encodes its Decimal → float) and may be null;
/// [nullableDecimalToDouble] tolerates number / Decimal-string / null.
@freezed
class Fabric with _$Fabric {
  const factory Fabric({
    required String id,
    @JsonKey(name: 'order_item_id') required String orderItemId,
    required String serial,
    String? details,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(fromJson: nullableDecimalToDouble) double? quantity,
    String? unit,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Fabric;

  factory Fabric.fromJson(Map<String, dynamic> json) => _$FabricFromJson(json);
}

/// NOT a response model — request-building helper for `OrderItemCreate.fabrics`
/// (on a brand-new item) and for `POST .../items/{id}/fabrics` (on an existing
/// item). The serial is generated server-side, so it's absent here.
///
/// On a not-yet-created item the image must be staged first (its `imageUrl` +
/// `imageFileId` come from `/uploads/staging/image`) and rides along in the
/// create payload. On an existing item, add the fabric first, then upload its
/// image by the returned fabric id (`/uploads/fabrics/{id}/image`) — there's no
/// id to attach to until it exists.
class FabricInput {
  const FabricInput({
    this.details,
    this.imageUrl,
    this.imageFileId,
    this.quantity,
    this.unit = 'yards',
  });

  final String? details;
  final String? imageUrl;
  final String? imageFileId;
  final double? quantity;
  final String? unit;

  /// Any ImageKit file_id this input staged (its fabric image), so an
  /// abandoned create flow can clean it up.
  List<String> get stagedFileIds =>
      [if (imageFileId != null && imageFileId!.isNotEmpty) imageFileId!];

  Map<String, dynamic> toJson() => {
        if (details != null && details!.isNotEmpty) 'details': details,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
        if (imageFileId != null && imageFileId!.isNotEmpty)
          'image_file_id': imageFileId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
      };
}
