import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'order_addon.freezed.dart';
part 'order_addon.g.dart';

/// Mirrors the backend's `OrderAddonResponse` — a chargeable extra on an
/// order that isn't a garment: delivery, a rush fee, embroidery, fabric
/// sourced on the client's behalf.
///
/// **Order-level only.** There is deliberately no `orderItemId`: an addon is
/// money, not production work, so adding one must never move the order's
/// status or spawn a task. If per-item addons are ever wanted the field is
/// additive server-side with no data rewrite.
///
/// `amount` is always positive — the backend refuses zero and negatives with
/// both a validator and a check constraint. A negative addon would be a
/// second discount mechanism sitting beside `discountType`/`discountValue`
/// with none of the same caps, and the two would disagree within a week.
/// Discounts go through the discount fields.
@freezed
class OrderAddon with _$OrderAddon {
  // Required by freezed before custom getters can be declared on the class.
  const OrderAddon._();

  const factory OrderAddon({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    required String label,
    @JsonKey(fromJson: decimalStringToDouble) required double amount,
    @Default(1) int quantity,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _OrderAddon;

  /// Display only. The backend computes `addons_total` authoritatively; this
  /// exists so a row can show `2 × ₦1,500  ₦3,000` without the widget doing
  /// the multiplication inline.
  double get lineTotal => amount * quantity;

  factory OrderAddon.fromJson(Map<String, dynamic> json) =>
      _$OrderAddonFromJson(json);
}
