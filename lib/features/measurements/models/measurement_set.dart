import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/json_converters.dart';

part 'measurement_set.freezed.dart';
part 'measurement_set.g.dart';

/// One field's captured value within a set (MeasurementValueResponse). Either
/// `valueNumber` (number fields) or `valueText` (text fields) is set, never
/// both. `unit` is frozen at capture time. `key`/`label` are flattened from
/// the field so the value renders without a dictionary lookup.
@freezed
class MeasurementValue with _$MeasurementValue {
  const factory MeasurementValue({
    @JsonKey(name: 'field_id') required String fieldId,
    required String key,
    required String label,
    @JsonKey(name: 'value_number', fromJson: nullableDecimalToDouble)
    double? valueNumber,
    @JsonKey(name: 'value_text') String? valueText,
    String? unit,
  }) = _MeasurementValue;

  const MeasurementValue._();

  factory MeasurementValue.fromJson(Map<String, dynamic> json) =>
      _$MeasurementValueFromJson(json);

  /// Display string for this value, e.g. "102.5 cm" or "slim". Trims a
  /// trailing ".0" so whole numbers read cleanly.
  String get display {
    if (valueText != null && valueText!.isNotEmpty) return valueText!;
    final n = valueNumber;
    if (n == null) return '—';
    final num shown = n % 1 == 0 ? n.toInt() : n;
    final u = (unit != null && unit != 'none') ? ' $unit' : '';
    return '$shown$u';
  }
}

/// A captured measurement event for a client or guest (MeasurementSetResponse).
@freezed
class MeasurementSet with _$MeasurementSet {
  const factory MeasurementSet({
    required String id,
    @JsonKey(name: 'client_id') String? clientId,
    @JsonKey(name: 'guest_recipient_id') String? guestRecipientId,
    @JsonKey(name: 'template_id') String? templateId,
    String? label,
    String? notes,
    @JsonKey(name: 'taken_at') DateTime? takenAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(<MeasurementValue>[]) List<MeasurementValue> values,
  }) = _MeasurementSet;

  factory MeasurementSet.fromJson(Map<String, dynamic> json) =>
      _$MeasurementSetFromJson(json);
}
