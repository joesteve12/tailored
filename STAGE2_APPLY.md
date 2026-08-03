# Frontend money rebuild — stage 2 of 2 (UI, sheets, tests)

Unzip at the repo root over your stage-1 tree, then regenerate (the stage-1
models are unchanged here, but re-running is harmless and safe):

    dart run build_runner build --delete-conflicting-outputs
    flutter analyze
    flutter test test/money_model_test.dart

After this stage the app compiles again — the five stage-1 breakages
(`voidPayment`, `isVoided`, `fetchReceipt`) are all resolved by the rewrites
below.

## The hard limit on what I can promise

There is no Dart toolchain in the environment I built this in, and I could not
install one — the Dart SDK and Flutter both bootstrap from a host that wasn't
reachable. So **nothing here has been compiled or run.** On the backend I ran
74 tests and both migrations; here I ran a battery of static checks and ported
the one piece of pure logic (the naira formatter) to Python to test its
algorithm, but that is not a compiler.

What I checked, mechanically, across every file I touched:

- brace/paren/bracket balance
- every relative and `package:` import resolves to a real file
- no undefined private identifiers (this is the check that would have caught
  the `_groupThousands` bug from stage 1 — it now runs over everything)
- every `order.` / `payment.` / `addon.` field access resolves to a real
  model member or getter
- no surviving references to the removed API (`isVoided`, `voidPayment`,
  `fetchReceipt`) anywhere but doc comments
- the naira formatter, 23 cases, via a faithful Python port — 0 failures

Treat `flutter analyze` as the real gate. If it reports anything, send it —
type inference and null-safety flow are exactly what my static passes can't
see.

## New files

    lib/features/payments/widgets/money_sheet_parts.dart   shared: date floor, midday rule, error mapping, date field
    lib/features/payments/widgets/record_refund_sheet.dart
    lib/features/payments/widgets/log_tip_sheet.dart
    lib/features/orders/widgets/addon_form_sheet.dart
    lib/features/orders/widgets/order_addons_section.dart
    lib/features/documents/state/document_providers.dart   receipt-exists lookup for the delete warning
    test/money_model_test.dart

## Changed files

    lib/features/payments/widgets/payment_section.dart      money card: garments/extras split, refund-due row, 3 actions
    lib/features/payments/widgets/record_payment_sheet.dart tip prompt on over-balance, date field, no hard block
    lib/features/orders/widgets/order_activity_section.dart timeline: payments+refunds+tips, per-row receipt, delete dialog
    lib/features/documents/widgets/order_document_actions.dart invoice only; receipt button removed
    lib/features/orders/screens/order_detail_screen.dart    addons section wired in; discount-includes-addons prompt
    lib/features/orders/widgets/order_item_edit_sheet.dart  item-removal credit warning
    lib/features/orders/state/order_detail_notifier.dart    addon mutations, discount flag
    lib/features/payments/state/payment_providers.dart      doc only (no void)
    lib/features/orders/models/order_item.dart              money formatting on subtitle
    lib/features/orders/widgets/client_orders_section.dart  money formatting
    lib/features/tasks/screens/task_detail_screen.dart      money formatting

## Deviations from FRONTEND_MONEY_REBUILD.md, as agreed

**Discount prompt lives in the edit-details dialog, not the create form.** §7
lists `order_form_screen.dart`, but an order has no addons at create time, so
the prompt (shown only when `order.hasAddons`) could never fire there. It's in
`_EditDetailsDialog` inside `order_detail_screen.dart`, which is where the
discount is actually edited, and `order_detail_notifier` + `order_repository`
carry the new flag. `order_form_screen.dart` is untouched — the backend
defaults `discountIncludesAddons` to true.

**Picked dates are sent at noon local.** A date picker returns local midnight;
in WAT (UTC+1) that's 23:00 the previous day in UTC, and the backend's date
floor compares at UTC-date granularity, so "today" would be rejected as
yesterday. `middayOn()` in `money_sheet_parts.dart` normalises to 12:00 local,
which is the same calendar day in UTC for any offset within ±12h. An untouched
field sends no `paid_at` at all and lets the server stamp now.

**Four money-formatting sites beyond §7's list.** The spec's copy is in
`₦95,000` throughout but the codebase rendered `95000.00`. Besides the money
card I converted the order-detail item line, the order_item subtitle, the task
detail unit price, and the client-orders row, so the app doesn't show two money
formats on one screen. All one-line changes via the new `formatNaira`.

**Item-removal warning added.** §6 covers the addon-removal credit warning;
removing an *item* creates the same credit and had no warning. The item edit
sheet now shows the projected total and refund-owed figure before removing —
computed for the copy only; the backend returns the settled numbers.

## Two things worth watching in review

**`payment_labels.dart` gained a `flutter/material` import** for the new
`paymentStatusColor(ColorScheme, String)`. If your lints forbid a
material-framework dependency in a `utils/` file, move that one function to a
widget file — the label functions don't need it.

**The delete-payment dialog degrades to the harsher warning on lookup
failure.** If `/documents` can't be reached, `_existingReceipt` returns null,
which shows the *stronger* "delete anyway" copy. That's deliberate — over-
warning on a destructive money action is the safe direction — but it means a
flaky network reads as "a receipt may exist" rather than a hard error.

## Tests

`test/money_model_test.dart` is pure Dart — no widget pumping, no HTTP. It pins
the getters the whole card is built on: `balanceDue`/`refundDue` mutual
exclusivity, the negative-`amountPaid` case, `isOverpaid` reading server state,
`balanceAfter` returning null on legacy rows, tip/refund detection, and the
formatter. Runs under `flutter test`.
