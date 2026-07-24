import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_error_view.dart';
import '../models/measurement_template.dart';
import '../state/dictionary_admin_notifiers.dart';

/// Templates decide which measurements a given garment needs. "Agbada" pulls
/// chest, agbada length, sleeve; "Skirt" pulls waist, hip, skirt length. The
/// capture form lays out whichever template is picked, in order, with the
/// required fields marked.
class MeasurementTemplatesScreen extends ConsumerWidget {
  const MeasurementTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateAdminListProvider);
    final notifier = ref.read(templateAdminListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement templates'),
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
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(error: err, onRetry: notifier.refresh),
        data: (templates) {
          if (templates.isEmpty) {
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
              itemCount: templates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _TemplateTile(template: templates[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_measurement_templates',
        onPressed: () => context.push('/settings/measurements/templates/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});

  final MeasurementTemplate template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fields = template.fields;
    final requiredCount = fields.where((f) => f.isRequired).length;
    final staleCount = fields.where((f) => f.isArchived).length;

    final details = <String>[
      fields.length == 1 ? '1 field' : '${fields.length} fields',
      if (requiredCount > 0) '$requiredCount required',
      if (template.garmentType != null && template.garmentType!.isNotEmpty)
        template.garmentType!,
    ];

    return ListTile(
      title: Row(
        children: [
          Flexible(child: Text(template.name)),
          if (template.isArchived) ...[
            const SizedBox(width: 8),
            _Tag(label: 'Archived', color: scheme.outline),
          ],
          // A field in this template has since been archived. It no longer
          // renders on the capture form, so the template is quietly shorter
          // than it looks — worth flagging before someone wonders why.
          if (staleCount > 0) ...[
            const SizedBox(width: 8),
            _Tag(
              label:
                  '$staleCount archived field${staleCount == 1 ? '' : 's'}',
              color: scheme.error,
            ),
          ],
        ],
      ),
      subtitle: Text(details.join('  ·  ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          context.push('/settings/measurements/templates/${template.id}'),
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
            const Icon(Icons.checkroom_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'No templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Build a template per garment so the capture form asks for the '
              'right measurements every time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
