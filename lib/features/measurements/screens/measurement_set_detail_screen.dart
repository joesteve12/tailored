import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/widgets/async_error_view.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_set.dart';
import '../state/measurement_list_notifier.dart';
import '../state/measurement_set_providers.dart';

import '../../../core/widgets/feedback.dart';
/// Read-only view of one measurement set, with edit + delete. Addressed by id
/// (GET /measurements/sets/{id}), so it's deep-link safe.
class MeasurementSetDetailScreen extends ConsumerWidget {
  const MeasurementSetDetailScreen({super.key, required this.setId});

  final String setId;

  RecipientRef _recipientOf(MeasurementSet set) => set.clientId != null
      ? clientRecipient(set.clientId!)
      : guestRecipient(set.guestRecipientId!);

  Future<void> _delete(BuildContext context, WidgetRef ref, MeasurementSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this measurement set?'),
        content: const Text('This removes the recorded values. It can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(measurementRepositoryProvider).deleteSet(setId);
      await ref
          .read(measurementListProvider(_recipientOf(set)).notifier)
          .refresh();
      if (context.mounted) {
        showSuccessSnackbar(context, 'Measurements deleted');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, e, action: 'Could not delete');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setAsync = ref.watch(measurementSetByIdProvider(setId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurements'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/measurements/sets/$setId/edit'),
          ),
        ],
      ),
      body: setAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () async => ref.invalidate(measurementSetByIdProvider(setId)),
        ),
        data: (set) {
          final date = set.takenAt ?? set.createdAt;
          final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (set.label?.isNotEmpty == true)
                Text(set.label!, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Taken $dateLabel',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (set.values.isEmpty)
                const Text('No values recorded.')
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < set.values.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          dense: true,
                          title: Text(set.values[i].label),
                          trailing: Text(
                            set.values[i].display,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (set.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(set.notes!),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _delete(context, ref, set),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete set'),
              ),
            ],
          );
        },
      ),
    );
  }
}
