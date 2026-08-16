import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/utils/json_converters.dart';
import '../../../core/utils/money.dart';
import '../../tasks/models/item_production.dart';
import 'fabric.dart';
import 'style_reference.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// Mirrors OrderItemResponse on the restructured backend. Fabric is no longer a
/// few flat columns on the item — a garment can be cut from several fabrics, so
/// the item now embeds a `fabrics` list (each a [Fabric] with its own
/// server-generated serial). The old `fabricSerial` / `fabricDetails` /
/// `fabricImageUrl` fields are gone; read `fabrics` instead.
///
/// Production status is no longer a stored field — the old `status` column
/// is gone. The server derives a read-only `production` block from the
/// item's Task (stage timestamps) on every read; see [ItemProduction].
/// All production changes go through the task endpoints, never through an
/// item edit. `recipientType` stays a plain string per house convention.
@freezed
class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String id,
    @JsonKey(name: 'garment_type') required String garmentType,
    String? description,
    required int quantity,
    @JsonKey(name: 'unit_price', fromJson: decimalStringToDouble)
    required double unitPrice,
    @JsonKey(name: 'fabrics') @Default(<Fabric>[]) List<Fabric> fabrics,
    String? notes,
    @JsonKey(name: 'recipient_type') required String recipientType,
    @JsonKey(name: 'recipient_client_id') String? recipientClientId,
    @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
    // The measurement snapshots this garment is cut from. A multi-piece outfit
    // (top + skirt) links one set per piece; each set names itself, so the ids
    // are enough here. Newest-first, matching the backend's ordering.
    @JsonKey(name: 'measurement_set_ids')
    @Default(<String>[])
    List<String> measurementSetIds,
    required ItemProduction production,
    @JsonKey(name: 'style_references')
    @Default(<StyleReference>[])
    List<StyleReference> styleReferences,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  /// The first fabric image, if any — used for the item's thumbnail in lists.
  String? get primaryFabricImageUrl {
    for (final f in fabrics) {
      if (f.imageUrl != null && f.imageUrl!.isNotEmpty) return f.imageUrl;
    }
    return null;
  }

  /// Reconstructs the RecipientRef shape (shared with Measurements) from the
  /// three raw wire fields. Falls back to a client-recipient with an empty id
  /// if neither id is set (shouldn't happen given the backend check
  /// constraint) — better than throwing and taking the whole order detail
  /// screen down over one malformed item.
  RecipientRef get recipient {
    if (recipientType == 'guest' && guestRecipientId != null) {
      return guestRecipient(guestRecipientId!);
    }
    return clientRecipient(recipientClientId ?? '');
  }

  /// Line total for this item, for display only — the authoritative
  /// subtotal/total are computed server-side and read off the Order.
  double get lineTotal => unitPrice * quantity;
}

/// NOT a response model — request-building helper matching OrderItemCreate.
/// Used for both "items on a brand-new order" and "add an item to an existing
/// order" (both hit endpoints that take OrderItemCreate).
///
/// Takes a [RecipientRef] rather than separate type/id fields so it's
/// impossible to build an item with, say, type 'guest' but no guest id.
///
/// Each fabric's image (when present) and each style reference are expected to
/// have already been uploaded via the staging endpoints — the item doesn't
/// exist yet at create time, so the per-fabric / per-item upload endpoints
/// can't be used. Staging-then-attach is the only path that works here.
class OrderItemInput {
  const OrderItemInput({
    required this.garmentType,
    this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.fabrics = const [],
    required this.recipient,
    this.notes,
    this.measurementSetIds = const [],
    this.styleReferences = const [],
  });

  final String garmentType;
  final String? description;
  final int quantity;
  final double unitPrice;
  final List<FabricInput> fabrics;
  final RecipientRef recipient;
  final String? notes;
  final List<String> measurementSetIds;
  final List<StyleReferenceInput> styleReferences;

  /// A short summary line for the in-form item list, before the order is
  /// submitted (the create form accumulates these locally).
  String get summaryLine =>
      'Qty $quantity · ${formatNaira(unitPrice)} each'
      '${fabrics.isNotEmpty ? ' · ${fabrics.length} fabric${fabrics.length == 1 ? '' : 's'}' : ''}'
      '${recipient.isGuest ? ' · for guest' : ''}';

  /// Every ImageKit file_id this not-yet-saved item staged (each fabric's image
  /// and any style references). If the item is removed from the create form, or
  /// the whole form is abandoned before saving, these are deleted so they don't
  /// orphan on ImageKit.
  List<String> get stagedFileIds => [
        for (final f in fabrics) ...f.stagedFileIds,
        for (final r in styleReferences) r.fileId,
      ];

  Map<String, dynamic> toJson() => {
        'garment_type': garmentType,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'quantity': quantity,
        // Plain JSON number on create — OrderItemCreate types unit_price as
        // `number`, unlike the Decimal-as-string in OrderItemResponse.
        'unit_price': unitPrice,
        if (fabrics.isNotEmpty)
          'fabrics': fabrics.map((f) => f.toJson()).toList(),
        'recipient_type': recipient.isClient ? 'client' : 'guest',
        if (recipient.isClient) 'recipient_client_id': recipient.id,
        if (recipient.isGuest) 'guest_recipient_id': recipient.id,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (measurementSetIds.isNotEmpty)
          'measurement_set_ids': measurementSetIds,
        if (styleReferences.isNotEmpty)
          'style_references':
              styleReferences.map((r) => r.toJson()).toList(),
      };
}
