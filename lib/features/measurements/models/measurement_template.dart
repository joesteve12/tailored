import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_template.freezed.dart';
part 'measurement_template.g.dart';

/// A field within a template (TemplateFieldResponse). The backend flattens the
/// field's key/label/unit/value_type onto this row so the capture form can
/// render the input without a second lookup. `sortOrder` is the display order;
/// `isRequired` marks fields the backend enforces on set creation.
///
/// `isArchived` mirrors the underlying dictionary field. Archiving used to be
/// invisible here — the template kept returning the field, the capture form
/// kept rendering it, and a required-but-archived field made the set
/// impossible to save. The capture form now skips archived rows and the
/// template editor shows them with a warning so they're removed on purpose,
/// not silently.
@freezed
class TemplateField with _$TemplateField {
  const factory TemplateField({
    @JsonKey(name: 'field_id') required String fieldId,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'is_required') required bool isRequired,
    required String key,
    required String label,
    required String unit,
    @JsonKey(name: 'value_type') required String valueType,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
  }) = _TemplateField;

  factory TemplateField.fromJson(Map<String, dynamic> json) =>
      _$TemplateFieldFromJson(json);
}

/// A named set of fields for a garment type (MeasurementTemplateResponse).
@freezed
class MeasurementTemplate with _$MeasurementTemplate {
  const factory MeasurementTemplate({
    required String id,
    required String name,
    @JsonKey(name: 'garment_type') String? garmentType,
    String? description,
    @JsonKey(name: 'is_archived') required bool isArchived,
    @Default(<TemplateField>[]) List<TemplateField> fields,
  }) = _MeasurementTemplate;

  factory MeasurementTemplate.fromJson(Map<String, dynamic> json) =>
      _$MeasurementTemplateFromJson(json);
}
