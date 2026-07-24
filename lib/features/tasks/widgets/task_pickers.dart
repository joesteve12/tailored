import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clients/data/client_repository.dart';
import '../../clients/models/client.dart';
import '../../employees/data/employee_repository.dart';
import '../../employees/models/employee.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/models/order.dart';

/// Bottom-sheet pickers shared by the task screens (Assign on the detail
/// timeline, the per-stage pickers on the Create Task screen, and the
/// to-do sheet's link fields). All fetch on open rather than watching a
/// list provider: a picker is a momentary surface and shouldn't pin a
/// whole list's cache alive, and ACTIVE-only filtering (employees) is a
/// query concern, not something to re-filter client-side off the settings
/// screen's list.

Future<Employee?> pickEmployee(BuildContext context, WidgetRef ref) {
  final future = ref.read(employeeRepositoryProvider).list(active: true);
  return showModalBottomSheet<Employee>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: FutureBuilder<List<Employee>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return _sheetError('Could not load employees.\n${snap.error}');
          }
          if (!snap.hasData) return _sheetLoading();
          final employees = snap.data!;
          if (employees.isEmpty) {
            return _sheetError(
                'No active employees yet.\nAdd one under Settings → Employees.');
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final e in employees)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(e.name),
                  subtitle: (e.specialty ?? '').isNotEmpty
                      ? Text(e.specialty!)
                      : null,
                  onTap: () => Navigator.pop(ctx, e),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// Search-as-you-type client picker for a to-do's client link.
Future<Client?> pickClient(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Client>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _ClientPickerSheet(ref: ref),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _search = '';
  late Future<List<Client>> _future = _fetch();

  Future<List<Client>> _fetch() async {
    final response = await widget.ref
        .read(clientRepositoryProvider)
        .list(search: _search, page: 1);
    return response.results;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the field above the keyboard.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search clients…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() {
                  _search = v.trim();
                  _future = _fetch();
                }),
              ),
            ),
            Flexible(
              child: FutureBuilder<List<Client>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    return _sheetError('Could not load clients.');
                  }
                  if (!snap.hasData) return _sheetLoading();
                  final clients = snap.data!;
                  if (clients.isEmpty) {
                    return _sheetError('No clients match.');
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in clients)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(c.name),
                          onTap: () => Navigator.pop(ctx, c),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent-orders picker for a to-do's order link. First page of the
/// default order list (newest first, 20 rows) — a to-do about an order is
/// almost always about a recent one; anything older can be linked later
/// from richer surfaces if that need ever materializes.
Future<Order?> pickOrder(BuildContext context, WidgetRef ref) {
  final future =
      ref.read(orderRepositoryProvider).list(page: 1, pageSize: 20);
  return showModalBottomSheet<Order>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: FutureBuilder<OrderListResponse>(
        future: future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return _sheetError('Could not load orders.');
          }
          if (!snap.hasData) return _sheetLoading();
          final orders = snap.data!.results;
          if (orders.isEmpty) return _sheetError('No orders yet.');
          return ListView(
            shrinkWrap: true,
            children: [
              for (final o in orders)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(o.orderNumber),
                  onTap: () => Navigator.pop(ctx, o),
                ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _sheetLoading() => const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );

Widget _sheetError(String message) => SizedBox(
      height: 160,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
