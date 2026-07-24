# Phase 5 — Orders parity pass (changed files)

Extract this archive over your existing `lib/` (paths mirror the project),
then regenerate freezed/json code:

    flutter pub get
    dart run build_runner build --delete-conflicting-outputs

No `pubspec.yaml` changes are required — `image_picker` is already a
dependency, and `share_plus`/`path_provider` belong to later phases.

## New files
- core/utils/order_labels.dart — status/priority/discount label maps +
  client-side mirror of the backend's order-status transition rules.
- core/utils/pick_image.dart — camera/gallery image picker → File.
- features/orders/models/order_media.dart
- features/orders/models/assignment.dart   (read-only this phase)
- features/orders/models/style_reference.dart
- features/orders/widgets/order_media_section.dart
- features/orders/widgets/recipient_picker.dart
- features/orders/widgets/measurement_snapshot_picker.dart
- features/orders/widgets/order_item_form_sheet.dart   (create-mode item)
- features/orders/widgets/order_item_edit_sheet.dart    (edit-mode item)

## Modified files (regenerate codegen for the models)
- features/orders/models/order.dart        (+priority, money breakdown, media)
- features/orders/models/order_item.dart   (+notes, snapshot, assignments, refs)
- features/orders/data/order_repository.dart
- features/orders/state/order_list_state.dart
- features/orders/state/order_list_notifier.dart
- features/orders/state/order_detail_notifier.dart
- features/orders/screens/order_form_screen.dart
- features/orders/screens/order_detail_screen.dart
- features/orders/screens/order_list_screen.dart

## Deferred (by design, per plan §6–7, §11)
- Assignment *editing* UI + per-item work-order PDF → Phase 7
  (assignments are displayed read-only here).
- Recording payments → Phase 8 (payment card is display-only).
- Style references / order media accept images only in this pass; the
  video branch renders a placeholder thumbnail where the backend returns
  file_type == 'video'.
