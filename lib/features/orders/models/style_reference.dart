import 'package:freezed_annotation/freezed_annotation.dart';

part 'style_reference.freezed.dart';
part 'style_reference.g.dart';

/// Mirrors the backend StyleReferenceResponse — one inspiration/reference
/// image or video attached to an order item (separate from the item's
/// single fabric image and from order-level media). Read-only here; the
/// `file_id` ImageKit handle the backend keeps for deletion isn't surfaced
/// to the client (deletion goes by the reference's own `id`, see
/// OrderRepository.deleteStyleReference), so it's deliberately not modeled.
///
/// `fileType` is 'image' or 'video' — left a plain string for the same
/// reason `status`/`recipientType` are: model what the wire confirms, and
/// the UI only needs to branch image-vs-video for how it renders a
/// thumbnail, which a string handles fine.
@freezed
class StyleReference with _$StyleReference {
  const factory StyleReference({
    required String id,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_type') @Default('image') String fileType,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _StyleReference;

  factory StyleReference.fromJson(Map<String, dynamic> json) =>
      _$StyleReferenceFromJson(json);
}

/// NOT a response model — request-building helper for OrderItemCreate's
/// `style_references` array (StyleReferenceCreate shape). Used by the
/// create flow, where each reference is uploaded to ImageKit via the
/// staging endpoint first (yielding `fileUrl` + `fileId`), then attached
/// as part of the item-create payload. `fileId` is required on the wire
/// here precisely so the backend can delete the ImageKit file later;
/// staging uploads always return one, so it's non-nullable.
///
/// On an *existing* item, style references are added through the dedicated
/// `/uploads/order-items/{id}/style-reference` endpoint instead, which
/// uploads and attaches in one call — this input type is only for the
/// not-yet-created case.
class StyleReferenceInput {
  const StyleReferenceInput({
    required this.fileUrl,
    required this.fileId,
    this.fileType = 'image',
    this.notes,
  });

  final String fileUrl;
  final String fileId;
  final String fileType;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'file_url': fileUrl,
        'file_id': fileId,
        'file_type': fileType,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
