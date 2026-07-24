import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_field.freezed.dart';
part 'measurement_field.g.dart';

/// One entry in a shop's measurement dictionary (MeasurementFieldResponse).
/// `unit` is cm / inch / none; `valueType` is number / text. Archived fields
/// are hidden from new templates/capture but kept so old records stay valid.
@freezed
class MeasurementField with _$MeasurementField {
  const factory MeasurementField({
    required String id,
    required String key,
    required String label,
    required String unit,
    @JsonKey(name: 'value_type') required String valueType,
    String? description,
    @JsonKey(name: 'is_archived') required bool isArchived,
  }) = _MeasurementField;

  factory MeasurementField.fromJson(Map<String, dynamic> json) =>
      _$MeasurementFieldFromJson(json);
}
