// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_process.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductionProcessImpl _$$ProductionProcessImplFromJson(
        Map<String, dynamic> json) =>
    _$ProductionProcessImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ProductionProcessImplToJson(
        _$ProductionProcessImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
