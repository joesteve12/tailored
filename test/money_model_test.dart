import 'package:flutter_test/flutter_test.dart';
import 'package:tailored_business_app/core/utils/money.dart';
import 'package:tailored_business_app/features/orders/models/order.dart';
import 'package:tailored_business_app/features/orders/models/order_addon.dart';
import 'package:tailored_business_app/features/payments/models/payment.dart';

/// Unit tests over the money getters and the naira formatter.
///
/// Deliberately pure Dart — no `pumpWidget`, no mock HTTP. These pin the
/// arithmetic the whole money card is built on, which is where a silent wrong
/// answer does real damage: a card that renders beautifully and reports the
/// wrong balance is worse than one that fails to build.
///
/// Every case here corresponds to something that was either wrong or
/// unrepresentable before the money rebuild — most of all the old
/// `balanceDue` clamp, which reported "nothing owed" on an order where the
/// shop owed the client money back.

Order _order({
  double itemsSubtotal = 95000,
  double addonsTotal = 0,
  double? subtotal,
  double totalAmount = 95000,
  double amountPaid = 0,
  String paymentStatus = 'unpaid',
  String discountType = 'none',
  double discountValue = 0,
  double discountAmount = 0,
  bool discountIncludesAddons = true,
  List<OrderAddon> addons = const [],
  String status = 'pending',
}) {
  return Order(
    id: 'o1',
    clientId: 'c1',
    orderNumber: 'ORD-0001',
    status: status,
    dueDate: DateTime(2026, 8, 1),
    itemsSubtotal: itemsSubtotal,
    addonsTotal: addonsTotal,
    subtotal: subtotal ?? (itemsSubtotal + addonsTotal),
    discountType: discountType,
    discountValue: discountValue,
    discountAmount: discountAmount,
    discountIncludesAddons: discountIncludesAddons,
    totalAmount: totalAmount,
    amountPaid: amountPaid,
    paymentStatus: paymentStatus,
    addons: addons,
    createdAt: DateTime(2026, 7, 1),
  );
}

Payment _payment({
  String kind = 'payment',
  double amount = 50000,
  double tipAmount = 0,
  String? reason,
  String? receiptNumber = 'RCP-0001',
  double? orderTotalAtPayment = 95000,
  double? amountPaidAfter = 50000,
}) {
  return Payment(
    id: 'p1',
    orderId: 'o1',
    kind: kind,
    amount: amount,
    tipAmount: tipAmount,
    method: 'cash',
    reason: reason,
    paidAt: DateTime(2026, 7, 10),
    receiptNumber: receiptNumber,
    orderTotalAtPayment: orderTotalAtPayment,
    amountPaidAfter: amountPaidAfter,
  );
}

void main() {
  group('Order.balanceDue / refundDue', () {
    test('unpaid order owes the full total', () {
      final order = _order(totalAmount: 95000, amountPaid: 0);
      expect(order.balanceDue, 95000);
      expect(order.refundDue, 0);
    });

    test('part-paid order owes the remainder', () {
      final order = _order(totalAmount: 95000, amountPaid: 50000);
      expect(order.balanceDue, 45000);
      expect(order.refundDue, 0);
    });

    test('settled order owes nothing either way', () {
      final order = _order(totalAmount: 95000, amountPaid: 95000);
      expect(order.balanceDue, 0);
      expect(order.refundDue, 0);
    });

    test('overpaid order reports credit, not a zero balance', () {
      // The headline regression. The old getter was
      // `(totalAmount - amountPaid).clamp(0, totalAmount)`, which returned 0
      // here and left the card silent about ₦9,500 owed back to the client.
      final order = _order(
        totalAmount: 85500,
        amountPaid: 95000,
        paymentStatus: 'overpaid',
      );
      expect(order.balanceDue, 0);
      expect(order.refundDue, 9500);
      expect(order.isOverpaid, isTrue);
    });

    test('the two are never both non-zero', () {
      for (final (total, paid) in [
        (95000.0, 0.0),
        (95000.0, 50000.0),
        (95000.0, 95000.0),
        (85500.0, 95000.0),
        (0.0, 5000.0),
      ]) {
        final order = _order(totalAmount: total, amountPaid: paid);
        expect(order.balanceDue == 0 || order.refundDue == 0, isTrue,
            reason: 'total=$total paid=$paid');
      }
    });

    test('negative amountPaid does not become a phantom balance', () {
      // Reachable by deleting a payment after a refund was taken against it.
      // The backend records the shortfall honestly rather than clamping, so
      // the client must not turn −₦50,000 paid into extra money owed.
      final order = _order(totalAmount: 0, amountPaid: -50000);
      expect(order.balanceDue, 50000);
      expect(order.refundDue, 0);
    });

    test('isOverpaid reads the server status, not the arithmetic', () {
      // The backend is authoritative. An order whose figures look settled but
      // which the server marked overpaid must render as overpaid.
      final order = _order(
        totalAmount: 95000,
        amountPaid: 95000,
        paymentStatus: 'overpaid',
      );
      expect(order.isOverpaid, isTrue);
      expect(_order(paymentStatus: 'paid').isOverpaid, isFalse);
    });
  });

  group('Order.hasAddons', () {
    test('false with no addons, true with one', () {
      expect(_order().hasAddons, isFalse);
      expect(
        _order(addons: [
          OrderAddon(
            id: 'a1',
            orderId: 'o1',
            label: 'Delivery',
            amount: 5000,
            createdAt: DateTime(2026, 7, 2),
          )
        ]).hasAddons,
        isTrue,
      );
    });
  });

  group('OrderAddon.lineTotal', () {
    test('multiplies by quantity', () {
      final addon = OrderAddon(
        id: 'a1',
        orderId: 'o1',
        label: 'Extra buttons',
        amount: 1500,
        quantity: 3,
        createdAt: DateTime(2026, 7, 2),
      );
      expect(addon.lineTotal, 4500);
    });

    test('defaults to quantity 1', () {
      final addon = OrderAddon(
        id: 'a1',
        orderId: 'o1',
        label: 'Delivery',
        amount: 5000,
        createdAt: DateTime(2026, 7, 2),
      );
      expect(addon.quantity, 1);
      expect(addon.lineTotal, 5000);
    });
  });

  group('Payment kind and tips', () {
    test('a plain payment is not a refund or a tip', () {
      final payment = _payment();
      expect(payment.isRefund, isFalse);
      expect(payment.hasTip, isFalse);
      expect(payment.isStandaloneTip, isFalse);
      expect(payment.signedAmount, 50000);
    });

    test('a refund reports a negative signed amount but stores positive', () {
      final refund = _payment(kind: 'refund', amount: 9500, reason: 'Returned');
      expect(refund.amount, 9500, reason: 'stored positive on the wire');
      expect(refund.signedAmount, -9500);
      expect(refund.isRefund, isTrue);
    });

    test('a payment with a tip carries both, and they stay separate', () {
      final payment = _payment(amount: 95000, tipAmount: 5000);
      expect(payment.hasTip, isTrue);
      expect(payment.isStandaloneTip, isFalse);
      expect(payment.totalReceived, 100000);
      // The tip is not part of what settles the order.
      expect(payment.amount, 95000);
    });

    test('a standalone tip has no payment portion', () {
      final tip = _payment(amount: 0, tipAmount: 5000);
      expect(tip.isStandaloneTip, isTrue);
      expect(tip.hasTip, isTrue);
      expect(tip.signedAmount, 0);
    });

    test('a zero-tip payment is not a standalone tip', () {
      expect(_payment(amount: 0, tipAmount: 0).isStandaloneTip, isFalse);
    });
  });

  group('Payment.balanceAfter (frozen snapshot)', () {
    test('is the difference between the two snapshot figures', () {
      final payment = _payment(
        orderTotalAtPayment: 95000,
        amountPaidAfter: 50000,
      );
      expect(payment.balanceAfter, 45000);
    });

    test('is null when the snapshot is missing, not a computed guess', () {
      // Legacy rows recorded before snapshots existed. The UI renders an em
      // dash; deriving a figure from today's total would put a confident lie
      // on a document the client may hold a printed copy of.
      expect(_payment(orderTotalAtPayment: null).balanceAfter, isNull);
      expect(_payment(amountPaidAfter: null).balanceAfter, isNull);
      expect(
        _payment(orderTotalAtPayment: null, amountPaidAfter: null)
            .balanceAfter,
        isNull,
      );
    });

    test('does not move when the order total later changes', () {
      // The snapshot is the whole point: an item removed next month must not
      // rewrite a receipt already in a client's hands.
      final payment = _payment(
        orderTotalAtPayment: 95000,
        amountPaidAfter: 50000,
      );
      final _ = _order(totalAmount: 50000); // order shrank afterwards
      expect(payment.balanceAfter, 45000);
    });
  });

  group('formatNaira', () {
    test('groups thousands', () {
      expect(formatNaira(0), '\u20A60');
      expect(formatNaira(999), '\u20A6999');
      expect(formatNaira(1000), '\u20A61,000');
      expect(formatNaira(95000), '\u20A695,000');
      expect(formatNaira(1234567), '\u20A61,234,567');
    });

    test('shows kobo only when there are any', () {
      expect(formatNaira(9500), '\u20A69,500');
      expect(formatNaira(9500.5), '\u20A69,500.50');
      expect(formatNaira(95000, alwaysShowKobo: true), '\u20A695,000.00');
    });

    test('renders a negative with a true minus sign', () {
      expect(formatNaira(-9500), '\u2212\u20A69,500');
    });

    test('signed form marks direction explicitly', () {
      expect(formatSignedNaira(50000), '+\u20A650,000');
      expect(formatSignedNaira(-9500), '\u2212\u20A69,500');
    });

    test('dash for an unknown figure', () {
      expect(formatNairaOrDash(null), '\u2014');
      expect(formatNairaOrDash(45000), '\u20A645,000');
    });
  });

  group('trimTrailingZeros', () {
    test('drops .0 but keeps real fractions', () {
      expect(trimTrailingZeros(10), '10');
      expect(trimTrailingZeros(12.5), '12.5');
    });
  });
}
