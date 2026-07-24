// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeasurementValueImpl _$$MeasurementValueImplFromJson(
        Map<String, dynamic> json) =>
    _$MeasurementValueImpl(
      fieldId: json['field_id'] as String,
      key: json['key'] as String,
      label: json['label'] as String,
      valueNumber: nullableDecimalToDouble(json['value_number']),
      valueText: json['value_text'] as String?,
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$$MeasurementValueImplToJson(
        _$MeasurementValueImpl instance) =>
    <String, dynamic>{
      'field_id': instance.fieldId,
      'key': instance.key,
      'label': instance.label,
      'value_number': instance.valueNumber,
      'value_text': instance.valueText,
      'unit': instance.unit,
    };

_$MeasurementSetImpl _$$MeasurementSetImplFromJson(Map<String, dynamic> json) =>
    _$MeasurementSetImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String?,
      guestRecipientId: json['guest_recipient_id'] as String?,
      templateId: json['template_id'] as String?,
      label: json['label'] as String?,
      notes: json['notes'] as String?,
      takenAt: json['taken_at'] == null
          ? null
          : DateTime.parse(json['taken_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => MeasurementValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MeasurementValue>[],
    );

Map<String, dynamic> _$$MeasurementSetImplToJson(
        _$MeasurementSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'guest_recipient_id': instance.guestRecipientId,
      'template_id': instance.templateId,
      'label': instance.label,
      'notes': instance.notes,
      'taken_at': instance.takenAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'values': instance.values,
    };
