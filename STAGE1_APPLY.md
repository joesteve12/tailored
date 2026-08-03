# Frontend money rebuild — stage 1 of 2 (models, converters, repositories)

Unzip at the repo root (the folder holding `lib/` and `pubspec.yaml`), let it
overwrite, then run codegen:

    dart run build_runner build --delete-conflicting-outputs

No new dependencies. `pubspec.yaml` is untouched.

## Read these first

`lib/features/orders/models/order.dart` and
`lib/features/payments/models/payment.dart` — the split of `balanceDue` into
`balanceDue` / `refundDue`, and the removal of `voidedAt`. Everything in stage
2 is built on those two.

## The app will not compile after this stage. That's expected.

Stage 1 removes members that stage-2 files still reference. **Exactly five
call sites, in two files:**

    lib/features/orders/widgets/order_activity_section.dart
      :73   _voidPayment(Payment payment)          → renamed flow, gone in stage 2
      :101  .voidPayment(_orderId, payment.id)     → now deletePayment()
      :128  onVoid: _voidPayment
      :325  payment.isVoided                       → no such getter any more

    lib/features/documents/widgets/order_document_actions.dart
      :51   repo.fetchReceipt(order.id, ...)       → now fetchPaymentReceipt(orderId, paymentId)

Both files are rewritten in stage 2. If `flutter analyze` reports anything
**outside** that list, that's a real problem — send it to me.

`build_runner` should still succeed: those two widget files aren't in the
dependency graph of any annotated model, so the builders don't need to resolve
them. If codegen does fail, paste the output rather than working around it.

## Files

**New**

    lib/core/utils/money.dart                          naira formatter
    lib/features/orders/models/order_addon.dart
    lib/features/documents/models/document_issue.dart

**Changed**

    lib/core/utils/payment_labels.dart                 'overpaid' → "Refund due", + status colour
    lib/features/orders/models/order.dart              +4 fields, balanceDue/refundDue split
    lib/features/payments/models/payment.dart          −voidedAt, +kind/tip/reason/snapshots
    lib/features/orders/data/order_repository.dart     3 addon methods, discount flag
    lib/features/payments/data/payment_repository.dart refund, tips, paidAt, void→delete
    lib/features/documents/data/document_repository.dart per-payment receipt, documents list

## Deviations from FRONTEND_MONEY_REBUILD.md

**No `decimalStringToDoubleOrNull` was added.** §4.3 asks for one, but
`nullableDecimalToDouble` already exists in `json_converters.dart` and already
handles exactly `null | num | String`. A second function doing the same job
under a different name is how the two drift. The new nullable fields use the
existing one.

**§2's wire-format claim is wrong, harmlessly.** It says money arrives as
Decimal-strings. Checked against the running backend: every money field on
both `OrderResponse` and `PaymentResponse` serialises as a JSON *number*
(`"amount": 30000.0`). Both converters accept `num` defensively, so nothing
changes — but don't write new code on the string assumption.

**`money.dart` isn't in §7's file list.** The spec's UI copy is written in
`₦95,000` throughout and the codebase had no currency formatter at all — it
rendered `toStringAsFixed(2)`, so `95000.00`. The copy isn't implementable
without this. Dependency-free; `intl` was not added.

**`trimTrailingZeros` moved out of `payment_section.dart`.** It was a private
`_trimZeros` there; the discount label is now built in two places (money card
and the discount-includes-addons prompt), and two copies of a formatter drift.
The stage-2 rewrite of `payment_section.dart` drops the private copy.

## Stage 2 will cover

The nine UI files, the tip and refund sheets, the addons section, the
discount-includes-addons prompt, the item-deletion warning, and
`test/money_model_test.dart` over the getters added here.

Two things I'll implement that the spec doesn't specify, flagged when we
agreed the plan: picked dates get sent at **noon local** (converted to UTC by
the repository) so a WAT date picker can't be read as the previous UTC day and
rejected by the backend's floor; and the discount prompt goes in the
`_EditDetailsSheet` inside `order_detail_screen.dart`, not
`order_form_screen.dart`, because an order has no addons at create time and
the prompt could never fire there.
