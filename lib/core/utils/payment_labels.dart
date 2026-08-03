import 'package:flutter/material.dart';

/// View-layer labels for payment methods and the order's payment status.
/// The wire values (the keys) are what the backend accepts/returns; these
/// maps only affect display, mirroring how order/item statuses are handled.

/// The payment methods the backend's PaymentCreate validator accepts, in the
/// order shown in the method dropdown. 'cash' is the backend default.
const List<String> kPaymentMethods = [
  'cash',
  'bank_transfer',
  'card',
  'mobile_money',
  'other',
];

String paymentMethodLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Cash';
    case 'bank_transfer':
      return 'Bank transfer';
    case 'card':
      return 'Card';
    case 'mobile_money':
      return 'Mobile money';
    case 'other':
      return 'Other';
    default:
      return method;
  }
}

/// Order payment_status as set by the payments service: unpaid | partial |
/// paid | overpaid.
///
/// `overpaid` renders as **"Refund due"**, not "Overpaid". The two describe
/// the same row, but one names an anomaly and the other names the action the
/// shop now owes. An owner scanning the orders list wants a worklist, not a
/// diagnosis.
///
/// The state is reachable by removing a garment from, or deepening a discount
/// on, an order that was already paid — it is *not* reachable by taking an
/// overlarge payment, which the backend rejects outright.
String paymentStatusLabel(String status) {
  switch (status) {
    case 'unpaid':
      return 'Unpaid';
    case 'partial':
      return 'Partially paid';
    case 'paid':
      return 'Paid';
    case 'overpaid':
      return 'Refund due';
    default:
      return status;
  }
}

/// The colour a payment status should render in.
///
/// Takes a [ColorScheme] rather than a `BuildContext` so it stays callable
/// from anywhere that already has the theme resolved, and so it can be unit
/// tested without pumping a widget.
///
/// `overpaid` gets the error colour: money owed back to a client is a
/// liability, and rendering it in the same primary colour as "Paid" is how it
/// gets overlooked until the client asks for it.
Color paymentStatusColor(ColorScheme scheme, String status) {
  switch (status) {
    case 'overpaid':
      return scheme.error;
    default:
      return scheme.primary;
  }
}
