// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeasurementFieldImpl _$$MeasurementFieldImplFromJson(
        Map<String, dynamic> json) =>
    _$MeasurementFieldImpl(
      id: json['id'] as String,
      key: json['key'] as String,
      label: json['label'] as String,
      unit: json['unit'] as String,
      valueType: json['value_type'] as String,
      description: json['description'] as String?,
      isArchived: json['is_archived'] as bool,
    );

Map<String, dynamic> _$$MeasurementFieldImplToJson(
        _$MeasurementFieldImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'label': instance.label,
      'unit': instance.unit,
      'value_type': instance.valueType,
      'description': instance.description,
      'is_archived': instance.isArchived,
    };
