import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_error_view.dart';
import '../state/employee_list_notifier.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final notifier = ref.read(employeeListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            initialValue: notifier.showInactive,
            onSelected: (showInactive) => notifier.setShowInactive(showInactive),
            itemBuilder: (context) => const [
              PopupMenuItem(value: false, child: Text('Active only')),
              PopupMenuItem(value: true, child: Text('Show all')),
            ],
          ),
        ],
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => notifier.refresh(),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            // Wrap in a RefreshIndicator over a scrollable ListView so pull-
            // to-refresh works in the empty state too. A bare Center wouldn't
            // over-scroll and would silently swallow the gesture.
            return RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child:
                        _EmptyState(showInactive: notifier.showInactive),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              // Force overscroll so pull-to-refresh works even when only a
              // couple of rows are visible and the list wouldn't otherwise
              // be scrollable.
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = employees[index];
                final initials =
                    e.name.isNotEmpty ? e.name[0].toUpperCase() : '?';
                return ListTile(
                  leading: CircleAvatar(child: Text(initials)),
                  title: Text(e.name),
                  subtitle: Text(
                    [e.phone, if (e.specialty != null) e.specialty!]
                        .join('  ·  '),
                  ),
                  trailing: e.isActive
                      ? const Icon(Icons.chevron_right)
                      : const Chip(
                          label: Text('Inactive'),
                          visualDensity: VisualDensity.compact,
                        ),
                  onTap: () => context.push('/settings/employees/${e.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_employees',
        onPressed: () => context.push('/settings/employees/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showInactive});

  final bool showInactive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              showInactive ? 'No employees yet' : 'No active employees',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Add the tailors you assign work to.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
