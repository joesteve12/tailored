import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';
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

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

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
          final scheme = Theme.of(context).colorScheme;
          final tokens = context.appTokens;
          final date = set.takenAt ?? set.createdAt;
          final dateLabel = _formatDate(date);
          final title =
              set.label?.isNotEmpty == true ? set.label! : dateLabel;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event, size: 15, color: tokens.mutedForeground),
                  const SizedBox(width: 6),
                  Text(
                    'Taken $dateLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.mutedForeground,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (set.values.isEmpty)
                Text(
                  'No values recorded.',
                  style: TextStyle(color: tokens.mutedForeground),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                    border: Border.all(
                      color: scheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Striped rows: alternating rows get a faint tint over
                      // the container's base color so a long list of numbers
                      // stays readable across the width without divider lines
                      // or a header eating space above them.
                      for (var i = 0; i < set.values.length; i++)
                        Container(
                          color: i.isOdd
                              ? scheme.surfaceContainerHighest
                                  .withOpacity(0.5)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(set.values[i].label)),
                              const SizedBox(width: 12),
                              Text(
                                set.values[i].display,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: tokens.fontWeightMedium,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              if (set.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(set.notes!),
              ],
              const SizedBox(height: 28),
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
