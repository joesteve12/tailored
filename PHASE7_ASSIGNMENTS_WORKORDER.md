# Phase 7 — Assignments + work order (changed files)

Extract over your existing project (paths mirror the tree). This builds on
Phase 5 (Orders parity). Phase 6 (Employees) was already present in the tree.

## Apply
    flutter pub get      # pulls share_plus + path_provider

No `build_runner` run is needed this phase — the only model change is a plain
request class (`AssignmentInput`); no freezed/json_serializable code changed.

## New files
- lib/features/orders/widgets/order_item_assignments_section.dart
    The assignment editor embedded in the item edit sheet: a "Whole item"
    dropdown plus Cutting / Stitching / Finishing overrides (each shows
    "From whole item: <name>" when left on default), a "Save assignments"
    action (PUT replaces the whole set), and "Send work order".
- lib/core/utils/share_document.dart
    Writes document bytes to a temp file and opens the OS share sheet
    (reused later for invoice/receipt in Phase 9).

## Modified files
- pubspec.yaml                          (+ share_plus ^9.0.0, path_provider ^2.1.4)
- lib/features/orders/models/assignment.dart        (+ AssignmentInput)
- lib/features/orders/data/order_repository.dart     (+ getAssignments,
    replaceAssignments, fetchWorkOrder[bytes])
- lib/features/orders/state/order_detail_notifier.dart  (+ replaceAssignments,
    refetches the order so the read-only summary updates)
- lib/features/orders/widgets/order_item_edit_sheet.dart (embeds the section)
- lib/features/employees/state/employee_providers.dart   (+ activeEmployeesProvider
    for the dropdowns — independent of the Employees list filter)

## Behaviour notes
- Assignment dropdowns list active employees. Someone assigned and then
  deactivated still appears (labelled "(inactive)") so their row doesn't
  break — but only active staff are offered for new picks.
- "Send work order" fetches the server-generated PDF (which reflects the last
  *saved* assignments) and shares it; if there are unsaved changes it offers
  to save first. The OS share sheet can't pre-target a WhatsApp chat — the
  owner picks the chat (plan §7).
- The assignment editor saves through its own button (PUT …/assignments),
  separate from the item-field "Save" above it, since they hit different
  endpoints; failures are isolated and surfaced inline.

## Deferred
- Payments (Phase 8); Fabrics + invoice/receipt share (Phase 9, will reuse
  share_document.dart); Dashboard (Phase 10).
