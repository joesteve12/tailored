# Phase 8 — Payments (changed files)

Extract over your project (paths mirror the tree). Builds on Phases 5–7.

## Apply
    dart run build_runner build --delete-conflicting-outputs

Required because there's a new freezed/json model (Payment). No new packages,
so `pub get` isn't needed.

## New files
- lib/features/payments/models/payment.dart        Payment model (amount comes
    back as a JSON number here — the shared decimalStringToDouble handles it).
- lib/core/utils/payment_labels.dart               method + payment-status labels.
- lib/features/payments/data/payment_repository.dart   list / record / void.
- lib/features/payments/state/payment_providers.dart   paymentsProvider(orderId).
- lib/features/payments/widgets/record_payment_sheet.dart  amount + method +
    notes; caps amount at the balance and surfaces the backend's overpayment
    400 message.
- lib/features/payments/widgets/payment_section.dart   the money breakdown +
    "Record payment" + payment history with void. Replaces the old display-only
    card on the order detail screen.

## Modified files
- lib/features/orders/screens/order_detail_screen.dart   swaps the Phase-5
    display-only _PaymentCard for the live PaymentSection.
- lib/features/orders/screens/order_list_screen.dart     tiles now show the
    payment status via paymentStatusLabel (e.g. "Partially paid").

## Behaviour notes
- Record is offered whenever there's an outstanding balance and the order
  isn't cancelled (so a delivered-but-unpaid order can still take a final
  payment). The amount defaults to the full balance.
- The backend recomputes amount_paid / payment_status on every record and
  void; each mutation therefore refreshes the payment history, the order
  detail (breakdown + balance), and the orders list (tile status).
- Methods: Cash, Bank transfer, Card, Mobile money, Other. Voiding a payment
  pushes the balance back up and may flip the status back to partial/unpaid.

## Deferred
- Fabrics + invoice/receipt share (Phase 9 — will reuse share_document.dart
  from Phase 7); Dashboard (Phase 10).
