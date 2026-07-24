import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/recipient_ref.dart';
import '../../../core/widgets/async_error_view.dart';
import '../models/measurement_set.dart';
import '../state/measurement_dictionary_providers.dart';
import '../state/measurement_list_notifier.dart';
import '../widgets/measurement_list_section.dart' show kCustomTemplateFilter;

/// Measurement-set history for a client or guest, newest first. If
/// [templateFilter] is provided, the list is restricted to sets under that
/// template — a template id, or the [kCustomTemplateFilter] sentinel to show
/// only sets captured without any template. The FAB starts a new capture for
/// the same recipient (unfiltered — a new capture picks its own template).
class MeasurementHistoryScreen extends ConsumerWidget {
  const MeasurementHistoryScreen({
    super.key,
    required this.recipient,
    this.templateFilter,
  });

  final RecipientRef recipient;
  final String? templateFilter;

  bool _matchesFilter(MeasurementSet s) {
    if (templateFilter == null) return true;
    if (templateFilter == kCustomTemplateFilter) return s.templateId == null;
    return s.templateId == templateFilter;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(measurementListProvider(recipient));
    // Templates only fetched when we actually need a name for the title —
    // when a filter is set. On the unfiltered view the provider still watches
    // if it's already cached, but no extra fetch is triggered.
    final templatesAsync = templateFilter == null
        ? null
        : ref.watch(measurementTemplatesProvider);

    // Title resolves the template name if we can; falls back cleanly when we
    // can't (unknown/archived template, or "Custom" sentinel).
    String title = 'Measurement history';
    if (templateFilter == kCustomTemplateFilter) {
      title = 'Custom measurements';
    } else if (templateFilter != null && templatesAsync != null) {
      final name = templatesAsync.whenOrNull(
        data: (templates) {
          for (final t in templates) {
            if (t.id == templateFilter) return t.name;
          }
          return null;
        },
      );
      if (name != null) title = '$name measurements';
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () =>
              ref.read(measurementListProvider(recipient).notifier).refresh(),
        ),
        data: (allSets) {
          final sets = allSets.where(_matchesFilter).toList();
          if (sets.isEmpty) {
            // Scroll-wrap the empty state so pull-to-refresh still fires.
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(measurementListProvider(recipient).notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        templateFilter == null
                            ? 'No measurements recorded yet'
                            : 'No records under this template yet',
                      ),
                    ),
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
              itemCount: sets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _SetTile(set: sets[index]),
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

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set});

  final MeasurementSet set;

  @override
  Widget build(BuildContext context) {
    final date = set.takenAt ?? set.createdAt;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final preview = set.values.take(3).map((v) => v.label).join(', ');
    final notes = set.notes?.trim() ?? '';

    return ListTile(
      isThreeLine: notes.isNotEmpty,
      title: Text(set.label?.isNotEmpty == true ? set.label! : dateLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (set.label?.isNotEmpty == true) dateLabel,
              if (preview.isNotEmpty) preview,
              '${set.values.length} value${set.values.length == 1 ? '' : 's'}',
            ].join('  ·  '),
          ),
          // Notes carry the fit preference and anything else that isn't a
          // number, and they print on the work order — so they belong on the
          // row, not two taps away.
          if (notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/measurements/sets/${set.id}'),
    );
  }
}
