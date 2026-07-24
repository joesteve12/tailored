// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GuestProfileImpl _$$GuestProfileImplFromJson(Map<String, dynamic> json) =>
    _$GuestProfileImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      name: json['name'] as String,
      relation: json['relation'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$GuestProfileImplToJson(_$GuestProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'name': instance.name,
      'relation': instance.relation,
      'photo_url': instance.photoUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
