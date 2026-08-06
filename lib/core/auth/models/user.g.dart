// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String?,
      businessAddress: json['business_address'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      authProvider: json['auth_provider'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'business_name': instance.businessName,
      'owner_name': instance.ownerName,
      'business_address': instance.businessAddress,
      'specializations': instance.specializations,
      'phone': instance.phone,
      'logo_url': instance.logoUrl,
      'auth_provider': instance.authProvider,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
