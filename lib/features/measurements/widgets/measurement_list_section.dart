import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/measurement_set.dart';
import '../models/measurement_template.dart';
import '../state/measurement_dictionary_providers.dart';
import '../state/measurement_list_notifier.dart';

/// Sentinel query-param value used on the history route for sets that were
/// captured without a template. Matches [_customGroupKey] below.
const String kCustomTemplateFilter = 'custom';
const String _customGroupKey = 'custom';

/// Embeddable "Measurements" block for ClientDetailScreen and
/// GuestDetailScreen, keyed by [recipient]. Instead of a single-latest-set
/// preview, this now lists the *templates* the client has recordings under —
/// one row per template, with a count and the most-recent recording date.
/// Tapping a row opens the full history filtered to that template. Sets that
/// were captured without a template are grouped under "Custom".
class MeasurementListSection extends ConsumerWidget {
  const MeasurementListSection({super.key, required this.recipient});

  final RecipientRef recipient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(measurementListProvider(recipient));
    final templatesAsync = ref.watch(measurementTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Measurements',
                style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.straighten),
              tooltip: 'Add measurements',
              onPressed: () =>
                  context.push('/measurements/new', extra: recipient),
            ),
          ],
        ),
        // Combine sets + templates. Sets carry only ``templateId``, so we need
        // the templates list to render friendly names; templates alone give
        // us the whole catalog even when a client has no records against them
        // (though we only show templates that actually have records).
        setsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => AsyncErrorView(
            error: err,
            compact: true,
            onRetry: () =>
                ref.read(measurementListProvider(recipient).notifier).refresh(),
          ),
          data: (sets) => templatesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AsyncErrorView(
              error: err,
              compact: true,
              onRetry: () async => ref.invalidate(measurementTemplatesProvider),
            ),
            data: (templates) => _buildGroups(context, sets, templates),
          ),
        ),
      ],
    );
  }

  Widget _buildGroups(
    BuildContext context,
    List<MeasurementSet> sets,
    List<MeasurementTemplate> templates,
  ) {
    if (sets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No measurements recorded yet'),
      );
    }

    // Resolve template names once. Sets whose template was archived/deleted
    // after capture still show up here — under a friendly fallback name —
    // rather than disappearing on the user.
    final nameById = <String, String>{
      for (final t in templates) t.id: t.name,
    };

    // Group sets by templateId (nulls collapse into [_customGroupKey]).
    final grouped = <String, List<MeasurementSet>>{};
    for (final s in sets) {
      final key = s.templateId ?? _customGroupKey;
      grouped.putIfAbsent(key, () => []).add(s);
    }

    // Newest set in each group is what we sort on: a client's active template
    // (they've been measured with it recently) belongs at the top.
    DateTime latestAt(MeasurementSet s) => s.takenAt ?? s.createdAt;
    final groups = grouped.entries.map((e) {
      final most =
          e.value.reduce((a, b) => latestAt(a).isAfter(latestAt(b)) ? a : b);
      final name = e.key == _customGroupKey
          ? 'Custom'
          : (nameById[e.key] ?? 'Unknown template');
      return _TemplateGroup(
        key: e.key,
        name: name,
        count: e.value.length,
        lastRecordedAt: latestAt(most),
      );
    }).toList()
      ..sort((a, b) => b.lastRecordedAt.compareTo(a.lastRecordedAt));

    return Column(
      children: [
        for (final g in groups)
          _TemplateGroupRow(recipient: recipient, group: g),
      ],
    );
  }
}

class _TemplateGroup {
  _TemplateGroup({
    required this.key,
    required this.name,
    required this.count,
    required this.lastRecordedAt,
  });

  final String key; // template id or _customGroupKey
  final String name;
  final int count;
  final DateTime lastRecordedAt;
}

class _TemplateGroupRow extends StatelessWidget {
  const _TemplateGroupRow({required this.recipient, required this.group});

  final RecipientRef recipient;
  final _TemplateGroup group;

  @override
  Widget build(BuildContext context) {
    final d = group.lastRecordedAt;
    final dateLabel = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    final countLabel = group.count == 1 ? '1 record' : '${group.count} records';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(
        '/measurements/history?template=${Uri.encodeComponent(group.key)}',
        extra: recipient,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    '$countLabel  ·  last $dateLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
