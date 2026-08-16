// TEMPORARY dev-only harness to visually verify the payment ticket's dotted
// leader rows without a live backend. Not part of the app — delete before
// committing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/orders/models/order.dart';
import 'features/orders/models/order_addon.dart';
import 'features/payments/widgets/payment_section.dart';

void main() {
  final now = DateTime.now();
  final order = Order(
    id: 'preview-order-1',
    clientId: 'preview-client-1',
    clientName: 'Emeka Johnson',
    orderNumber: 'ORD-2026-0042',
    status: 'in_progress',
    priority: 'high',
    dueDate: now.add(const Duration(days: 5)),
    itemsSubtotal: 69,
    addonsTotal: 369,
    subtotal: 438,
    discountType: 'percentage',
    discountValue: 9,
    discountAmount: 6.21,
    discountIncludesAddons: false,
    totalAmount: 431.79,
    amountPaid: 131.79,
    paymentStatus: 'partial',
    addons: [
      OrderAddon(
        id: 'addon-1',
        orderId: 'preview-order-1',
        label: 'Delivery',
        amount: 66,
        quantity: 1,
        createdAt: now,
      ),
      OrderAddon(
        id: 'addon-2',
        orderId: 'preview-order-1',
        label: 'Home visit',
        amount: 3,
        quantity: 1,
        createdAt: now,
      ),
      OrderAddon(
        id: 'addon-3',
        orderId: 'preview-order-1',
        label: 'Extra lining and hand-finished hem work',
        amount: 300,
        quantity: 1,
        createdAt: now,
      ),
    ],
    createdAt: now,
  );

  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PaymentSection(order: order),
            ),
          ),
        ),
      ),
    ),
  );
}
