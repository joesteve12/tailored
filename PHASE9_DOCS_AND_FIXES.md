# Phase 9 — Documents (invoice/receipt) + two fixes

Extract over your project. Builds on Phases 5–8.

## Apply
Nothing to regenerate: no new freezed/json models (the one model change is a
plain getter) and no new packages — `share_plus`/`path_provider` came in
Phase 7. Just drop the files in.

For the staged-media cleanup to actually delete files, also apply the small
backend route in **BACKEND_PATCH_staging_delete.md** (one endpoint, reuses
existing helpers). Without it the frontend cleanup calls no-op safely.

## Fix 1 — item → order status automation
Moving an order item into production (cutting / sewing / finishing / done)
while the order is still **pending** now advances the order to **in_progress**
automatically. Centralised in OrderDetailNotifier.updateItem so it fires no
matter which screen drove the change. The backend doesn't do this itself; the
transition pending → in_progress is always valid, and the auto-advance is
best-effort (a failure never turns into an item-save error).
- lib/features/orders/state/order_detail_notifier.dart

## Fix 2 — orphaned staged uploads
Staged media/fabric/style images uploaded during order creation are now
deleted from ImageKit if they're removed before saving, or if the create flow
is abandoned. Cleanup fires on: removing a staged file in the item sheet,
removing an item or order-media tile in the create form, dismissing the item
sheet without adding, and disposing the create form without saving. A saved
order keeps its files (ownership transfers).
- lib/features/orders/data/order_repository.dart      (+ deleteStagedFile)
- lib/features/orders/models/order_item.dart          (+ stagedFileIds getter)
- lib/features/orders/widgets/order_item_form_sheet.dart
- lib/features/orders/screens/order_form_screen.dart
- BACKEND_PATCH_staging_delete.md                     (DELETE /uploads/staging/{file_id})

## Phase 9 — Documents (invoice / receipt share)
Order detail now has a Documents card: **Share invoice** (while a balance is
outstanding) and **Share receipt** (once anything is paid) — a partially-paid
order shows both. Fetches the server-generated PDF and opens the OS share
sheet, reusing share_document.dart from Phase 7.
- lib/features/documents/data/document_repository.dart      (new)
- lib/features/documents/widgets/order_document_actions.dart (new)
- lib/features/orders/screens/order_detail_screen.dart      (embeds the card)

## Not done: Fabrics
The Fabrics module can't be built yet — the backend has `services/fabric.py`
but **no router and it isn't mounted**, so there are no `/fabrics` endpoints
to target. Once the backend exposes them, the frontend module can follow.

## Remaining
- Phase 10: Dashboard.
