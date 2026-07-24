# Phase 1 frontend — pre-patched, mirror-ready

Everything in this zip is already patched. There are **no manual diffs** to
apply. Unzip at the root of your Flutter project (the folder holding `lib/`
and `pubspec.yaml`), let it overwrite, then run one code-gen command.

## THE ONE THING YOU MUST STILL RUN

The Payment model gained a field and a private constructor, and
`OrderStatusEvent` is a brand-new freezed model. Their generated files
(`*.freezed.dart`, `*.g.dart`) can only be produced by build_runner on your
machine — I can't ship valid ones. **The app will not compile until you
run:**

    dart run build_runner build --delete-conflicting-outputs

If your editor shows errors in `payment.dart` / `status_event.dart` right
after unzipping, that's expected — they clear once code-gen finishes.

## What changed (7 files)

New:
- `lib/features/orders/models/status_event.dart`
- `lib/features/orders/state/status_events_providers.dart`
- `lib/features/orders/widgets/order_activity_section.dart`

Rewritten:
- `lib/features/payments/widgets/payment_section.dart` — now just the money
  summary + Record button. Payment history and the void action have moved
  into the new Activity → Payments tab.
- `lib/features/payments/models/payment.dart` — adds `voidedAt` +
  `isVoided`.

Patched in place:
- `lib/features/orders/data/order_repository.dart` — adds
  `listStatusEvents(orderId)`.
- `lib/features/orders/screens/order_detail_screen.dart` — imports and
  renders `OrderActivitySection` below `PaymentSection`.

Every other file under `lib/` is a byte-for-byte copy of what you uploaded,
included only so the tree mirrors cleanly.

## Deploy order

Backend first (this frontend calls `GET /orders/{id}/status-events`, which
old backends will 404). The Payments tab still works against an old backend
because `voided_at` is optional on the wire.

## IMPORTANT — if your frontend changed since you sent me the zip

This mirror was built from the `lib/` you uploaded. If you've edited any
Dart files since, overwriting the whole tree reverts those edits. In that
case copy only the 7 files above rather than bulk-overwriting.

## Verify (after build_runner)

1. Order detail: money card shows totals only — no history list under it.
2. Below it, an "Activity" heading with Payments | Status pills.
3. Payments tab lists past payments. Void one → it stays, struck-through,
   with a "Voided" chip; the money card's balance recovers.
4. Status tab: empty on pre-existing orders (expected). Change an order or
   item status → a new row appears (newest first).
