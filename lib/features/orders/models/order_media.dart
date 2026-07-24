import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_media.freezed.dart';
part 'order_media.g.dart';

/// Mirrors the backend OrderMediaResponse — one order-level media file
/// (max 3 per order, enforced server-side). This is distinct from an
/// item's fabric image and from per-item style references: order media is
/// "photos/clips of the whole job" rather than tied to a single garment.
///
/// `fileType` ('image' | 'video') stays a plain string — the UI only needs
/// it to decide image-thumbnail vs video-placeholder. The ImageKit
/// `file_id` the backend keeps for deletion isn't surfaced; deletes go by
/// this row's own `id` (see OrderRepository.deleteMedia).
@freezed
class OrderMedia with _$OrderMedia {
  const factory OrderMedia({
    required String id,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_type') @Default('image') String fileType,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _OrderMedia;

  factory OrderMedia.fromJson(Map<String, dynamic> json) =>
      _$OrderMediaFromJson(json);
}
