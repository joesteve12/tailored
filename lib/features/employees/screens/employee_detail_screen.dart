import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tasks/utils/task_labels.dart';
import '../../../core/widgets/async_error_view.dart';
import '../data/employee_repository.dart';
import '../models/employee_workload_item.dart';
import '../state/employee_list_notifier.dart';
import '../state/employee_providers.dart';

import '../../../core/widgets/feedback.dart';
class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate employee?'),
        content: const Text(
          'They\'ll stop appearing in worker pickers, but stages already '
          'assigned to them stay on record. You can reactivate them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(employeeRepositoryProvider).deactivate(employeeId);
      ref.invalidate(employeeByIdProvider(employeeId));
      await ref.read(employeeListProvider.notifier).refresh();
      if (context.mounted) {
        showSuccessSnackbar(context, 'Employee deactivated');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, e, action: 'Could not deactivate');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/settings/employees/$employeeId/edit'),
          ),
        ],
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => ref.invalidate(employeeByIdProvider(employeeId)),
        ),
        data: (employee) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(employeeByIdProvider(employeeId));
              ref.invalidate(employeeWorkloadProvider(employeeId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(employee.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(employee.phone,
                              style: Theme.of(context).textTheme.bodyMedium),
                          if (employee.specialty != null) ...[
                            const SizedBox(height: 2),
                            Text(employee.specialty!,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    if (!employee.isActive)
                      Chip(
                        label: const Text('Inactive'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                if (employee.notes != null && employee.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(employee.notes!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                Text('Current workload',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _WorkloadSection(employeeId: employeeId),
                const SizedBox(height: 24),
                if (employee.isActive)
                  OutlinedButton.icon(
                    onPressed: () => _deactivate(context, ref),
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Deactivate employee'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkloadSection extends ConsumerWidget {
  const _WorkloadSection({required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workloadAsync = ref.watch(employeeWorkloadProvider(employeeId));
    return workloadAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => AsyncErrorView(
        error: err,
        compact: true,
        onRetry: () async => ref.invalidate(employeeWorkloadProvider(employeeId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'Nothing assigned yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          children: items.map((w) => _WorkloadTile(item: w)).toList(),
        );
      },
    );
  }
}

class _WorkloadTile extends StatelessWidget {
  const _WorkloadTile({required this.item});

  final EmployeeWorkloadItem item;

  @override
  Widget build(BuildContext context) {
    final due = item.dueDate;
    final dueText = due == null
        ? null
        : 'Due ${due.day}/${due.month}/${due.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.garmentType),
        subtitle: Text(
          [
            item.processName,
            'Order ${item.orderNumber}',
            if (dueText != null) dueText,
          ].join('  ·  '),
        ),
        trailing: Chip(
          label: Text(stageStateLabel(item.stageState)),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => context.push('/orders/${item.orderId}'),
      ),
    );
  }
}
