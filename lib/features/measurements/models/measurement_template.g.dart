// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TemplateFieldImpl _$$TemplateFieldImplFromJson(Map<String, dynamic> json) =>
    _$TemplateFieldImpl(
      fieldId: json['field_id'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      isRequired: json['is_required'] as bool,
      key: json['key'] as String,
      label: json['label'] as String,
      unit: json['unit'] as String,
      valueType: json['value_type'] as String,
      isArchived: json['is_archived'] as bool? ?? false,
    );

Map<String, dynamic> _$$TemplateFieldImplToJson(_$TemplateFieldImpl instance) =>
    <String, dynamic>{
      'field_id': instance.fieldId,
      'sort_order': instance.sortOrder,
      'is_required': instance.isRequired,
      'key': instance.key,
      'label': instance.label,
      'unit': instance.unit,
      'value_type': instance.valueType,
      'is_archived': instance.isArchived,
    };

_$MeasurementTemplateImpl _$$MeasurementTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$MeasurementTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      garmentType: json['garment_type'] as String?,
      description: json['description'] as String?,
      isArchived: json['is_archived'] as bool,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => TemplateField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TemplateField>[],
    );

Map<String, dynamic> _$$MeasurementTemplateImplToJson(
        _$MeasurementTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'garment_type': instance.garmentType,
      'description': instance.description,
      'is_archived': instance.isArchived,
      'fields': instance.fields,
    };
