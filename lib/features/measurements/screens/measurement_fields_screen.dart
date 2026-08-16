import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/measurement_field.dart';
import '../state/dictionary_admin_notifiers.dart';

/// The shop's measurement dictionary — every thing it can measure, e.g. "Chest",
/// "Agbada length". Templates draw from this list; the capture form renders it.
///
/// Archived fields are hidden by default. They're never removed from history, so
/// archiving is the normal way to retire a measurement you've stopped taking.
class MeasurementFieldsScreen extends ConsumerWidget {
  const MeasurementFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldAdminListProvider);
    final notifier = ref.read(fieldAdminListProvider.notifier);
    final usage = ref.watch(fieldTemplateUsageProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement fields'),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            initialValue: notifier.showArchived,
            onSelected: notifier.setShowArchived,
            itemBuilder: (context) => const [
              PopupMenuItem(value: false, child: Text('Active only')),
              PopupMenuItem(value: true, child: Text('Show archived')),
            ],
          ),
        ],
      ),
      body: fieldsAsync.when(
        loading: () => SkeletonList(
          scrollable: true,
          itemBuilder: (_, __) => const SkeletonTile(hasLeading: false),
        ),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: notifier.refresh,
        ),
        data: (fields) {
          if (fields.isEmpty) {
            return RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const _EmptyState(),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: fields.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _FieldTile(
                field: fields[index],
                templateNames: usage?[fields[index].id] ?? const [],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_measurement_fields',
        onPressed: () => context.push('/settings/measurements/fields/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field, required this.templateNames});

  final MeasurementField field;
  final List<String> templateNames;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // The subtitle is for the owner, so it never shows the machine key —
    // the description ("shoulder seam to hem") is what actually helps tell
    // "Shoulder to bust" from "Bust point" at a glance.
    final description = field.description?.trim() ?? '';
    final details = <String>[
      if (description.isNotEmpty) description,
      if (field.unit != 'none') field.unit,
      if (templateNames.isNotEmpty)
        templateNames.length == 1
            ? 'in 1 template'
            : 'in ${templateNames.length} templates',
    ];

    return ListTile(
      title: Row(
        children: [
          Flexible(child: Text(field.label)),
          // Legacy text fields (shops seeded before notes replaced them) still
          // exist and still work. Flag them so they're recognisable, since
          // nothing creates new ones.
          if (field.valueType == 'text') ...[
            const SizedBox(width: 8),
            _Tag(label: 'Text', color: scheme.tertiary),
          ],
          if (field.isArchived) ...[
            const SizedBox(width: 8),
            _Tag(label: 'Archived', color: context.appTokens.mutedForeground),
          ],
        ],
      ),
      subtitle: details.isEmpty ? null : Text(details.join('  ·  ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/settings/measurements/fields/${field.id}'),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, height: 1.1),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.straighten, size: 40),
            const SizedBox(height: 12),
            Text(
              'No measurement fields',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Add the measurements your shop takes — chest, waist, '
              'agbada length. Templates are built from these.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
