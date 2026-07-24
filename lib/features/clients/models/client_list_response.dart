import 'package:freezed_annotation/freezed_annotation.dart';

import 'client.dart';

part 'client_list_response.freezed.dart';
part 'client_list_response.g.dart';

/// Mirrors the confirmed ClientListResponse schema exactly:
/// {total, page, page_size, results: [ClientResponse]}.
@freezed
class ClientListResponse with _$ClientListResponse {
  const factory ClientListResponse({
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    required List<Client> results,
  }) = _ClientListResponse;

  factory ClientListResponse.fromJson(Map<String, dynamic> json) =>
      _$ClientListResponseFromJson(json);
}
