// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderMediaImpl _$$OrderMediaImplFromJson(Map<String, dynamic> json) =>
    _$OrderMediaImpl(
      id: json['id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? 'image',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$OrderMediaImplToJson(_$OrderMediaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_url': instance.fileUrl,
      'file_type': instance.fileType,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
