import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/measurement_set.dart';
import '../state/measurement_list_notifier.dart';

/// The full measurement list for a client or guest, newest first.
///
/// This is the single list surface for a recipient's measurements. It used to
/// support a `templateFilter` so the (now removed) grouped preview could drill
/// into one template's records — measurements are no longer grouped by
/// template, so the list is simply every set the recipient has, each identified
/// by its label (which defaults to the template name at capture time). The FAB
/// starts a new capture for the same recipient.
class MeasurementHistoryScreen extends ConsumerWidget {
  const MeasurementHistoryScreen({super.key, required this.recipient});

  final RecipientRef recipient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(measurementListProvider(recipient));

    return Scaffold(
      appBar: AppBar(title: const Text('Measurements')),
      body: setsAsync.when(
        loading: () => SkeletonList(
          scrollable: true,
          itemBuilder: (_, __) => const SkeletonTile(hasLeading: false),
        ),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () =>
              ref.read(measurementListProvider(recipient).notifier).refresh(),
        ),
        data: (sets) {
          if (sets.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref
                  .read(measurementListProvider(recipient).notifier)
                  .refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _EmptyState(recipient: recipient),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(measurementListProvider(recipient).notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: sets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SetCard(set: sets[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_measurements_new',
        onPressed: () => context.push('/measurements/new', extra: recipient),
        icon: const Icon(Icons.straighten),
        label: const Text('New'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.recipient});

  final RecipientRef recipient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.straighten,
                size: 34,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No measurements yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Record a set to start building this history. '
              'Pick a template to prefill the fields, or add your own.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.mutedForeground,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One measurement set as a tappable card: label + date, a preview of the
/// captured values as chips, and the notes line (which carries fit preferences
/// and prints on the work order, so it earns a place on the card).
class _SetCard extends StatelessWidget {
  const _SetCard({required this.set});

  final MeasurementSet set;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    final date = set.takenAt ?? set.createdAt;
    final dateLabel = _formatDate(date);
    final title = set.label?.isNotEmpty == true ? set.label! : dateLabel;
    final count = set.values.length;
    final countLabel =
        count == 0 ? 'No measurements' : '$count measurement${count == 1 ? '' : 's'}';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/measurements/sets/${set.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row one: the set's name (label, or the date as a fallback).
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: tokens.fontWeightMedium,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Row two: when it was taken and how many values it holds.
                    Text(
                      '$dateLabel  ·  $countLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: tokens.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
