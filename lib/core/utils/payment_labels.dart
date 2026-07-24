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
/// paid.
String paymentStatusLabel(String status) {
  switch (status) {
    case 'unpaid':
      return 'Unpaid';
    case 'partial':
      return 'Partially paid';
    case 'paid':
      return 'Paid';
    default:
      return status;
  }
}
