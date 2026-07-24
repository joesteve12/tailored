// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClientListResponseImpl _$$ClientListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$ClientListResponseImpl(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ClientListResponseImplToJson(
        _$ClientListResponseImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
      'results': instance.results,
    };
