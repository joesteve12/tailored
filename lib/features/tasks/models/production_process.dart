import 'package:freezed_annotation/freezed_annotation.dart';

part 'production_process.freezed.dart';
part 'production_process.g.dart';

/// Mirrors ProductionProcessResponse — one row of the shop's process
/// dictionary (Cutting, Stitching, …). Stage rows snapshot the name at
/// creation, so renaming or deactivating a process here never rewrites any
/// task's history. There is no hard delete — deactivate instead.
@freezed
class ProductionProcess with _$ProductionProcess {
  const factory ProductionProcess({
    required String id,
    required String name,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ProductionProcess;

  factory ProductionProcess.fromJson(Map<String, dynamic> json) =>
      _$ProductionProcessFromJson(json);
}
