// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StyleReferenceImpl _$$StyleReferenceImplFromJson(Map<String, dynamic> json) =>
    _$StyleReferenceImpl(
      id: json['id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? 'image',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$StyleReferenceImplToJson(
        _$StyleReferenceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_url': instance.fileUrl,
      'file_type': instance.fileType,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
