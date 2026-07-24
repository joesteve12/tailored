import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../measurements/models/measurement_set.dart';
import '../../measurements/models/measurement_template.dart';
import '../../measurements/state/measurement_dictionary_providers.dart';
import '../../measurements/state/measurement_list_notifier.dart';

/// Lets an order item record which of the recipient's measurement sets it
/// was "cut from" (the snapshot link the backend stores as
/// `measurement_set_id`). Shows the recipient's sets newest-first and a
/// "None" option; reports the chosen set id (or null to clear) via
/// [onChanged].
///
/// The recipient drives which sets are offered — measurement sets belong to
/// a client or a guest, so changing the item's recipient changes this list.
/// Pass the *current* recipient; the picker re-reads sets for whatever
/// recipient it's given via the shared `measurementListProvider` (the same
/// provider the client/guest measurement sections use, so it's usually
/// already warm).
class MeasurementSnapshotField extends ConsumerWidget {
  const MeasurementSnapshotField({
    super.key,
    required this.recipient,
    required this.selectedSetId,
    required this.onChanged,
  });

  final RecipientRef recipient;
  final String? selectedSetId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // An empty recipient id (malformed item fallback) has no sets to show.
    if (recipient.id.isEmpty) return const SizedBox.shrink();

    final setsAsync = ref.watch(measurementListProvider(recipient));
    // Templates load in parallel. If the fetch is still pending we render
    // the row anyway (nameById is just empty), and if it fails we simply
    // degrade to date-only labels instead of blocking snapshot picking on
    // a totally-unrelated network dependency.
    final templatesAsync = ref.watch(measurementTemplatesProvider);
    final nameById = <String, String>{
      for (final t in (templatesAsync.valueOrNull ?? const <MeasurementTemplate>[]))
        t.id: t.name,
    };

    return setsAsync.when(
      loading: () => const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.straighten_outlined),
        title: Text('Measurement snapshot'),
        subtitle: Text('Loading measurement sets…'),
      ),
      error: (_, __) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.straighten_outlined),
        title: const Text('Measurement snapshot'),
        subtitle: const Text("Couldn't load measurement sets"),
        trailing: TextButton(
          onPressed: () =>
              ref.read(measurementListProvider(recipient).notifier).refresh(),
          child: const Text('Retry'),
        ),
      ),
      data: (sets) {
        final selected = _findSelected(sets);
        final notes = selected?.notes?.trim() ?? '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          isThreeLine: notes.isNotEmpty,
          leading: const Icon(Icons.straighten_outlined),
          title: const Text('Measurement snapshot'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected != null
                    ? 'Cut from: ${_primaryLabel(selected, nameById)}'
                    : sets.isEmpty
                        ? 'No measurement sets for this recipient yet'
                        : 'None selected',
              ),
              // The chosen set's notes — fit preference and anything else the
              // tailor has to know that isn't a number. These print on the work
              // order, so seeing them while picking the snapshot is the check
              // that the right one was picked.
              if (notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
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
          trailing: const Icon(Icons.chevron_right),
          onTap: sets.isEmpty ? null : () => _pick(context, sets, nameById),
        );
      },
    );
  }

  MeasurementSet? _findSelected(List<MeasurementSet> sets) {
    if (selectedSetId == null) return null;
    for (final s in sets) {
      if (s.id == selectedSetId) return s;
    }
    return null;
  }

  Future<void> _pick(
    BuildContext context,
    List<MeasurementSet> sets,
    Map<String, String> nameById,
  ) async {
    final result = await showModalBottomSheet<_SnapshotChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Cut from which measurements?',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioListTile<String?>(
              value: null,
              groupValue: selectedSetId,
              title: const Text('None'),
              onChanged: (_) =>
                  Navigator.pop(context, const _SnapshotChoice(null)),
            ),
            for (final s in sets)
              RadioListTile<String?>(
                value: s.id,
                groupValue: selectedSetId,
                isThreeLine: (s.notes?.trim().isNotEmpty ?? false),
                title: Text(_primaryLabel(s, nameById)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_subtitle(s, nameById)),
                    if (s.notes?.trim().isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          s.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
                onChanged: (_) =>
                    Navigator.pop(context, _SnapshotChoice(s.id)),
              ),
          ],
        ),
      ),
    );
    if (result != null) onChanged(result.setId);
  }

  /// What goes on the top line of a picker row (and in the trailing "Cut from"
  /// subtitle on the collapsed field). Order of preference: the user's own
  /// label if they wrote one > the template name > a date fallback. The idea
  /// is that "Shirt" or "Wedding agbada" identifies a set immediately, where
  /// "Set from 2026-06-10" doesn't when several sets share a date.
  String _primaryLabel(MeasurementSet set, Map<String, String> nameById) {
    final userLabel = set.label;
    if (userLabel != null && userLabel.isNotEmpty) return userLabel;
    final tplId = set.templateId;
    if (tplId != null) {
      final name = nameById[tplId];
      if (name != null) return name;
    }
    return _dateLabel(set);
  }

  /// Disambiguating detail for the picker's subtitle. Always ends with the
  /// value count; prepends the date, and — if the set has a real capture
  /// time (not just midnight from a date-only ``taken_at``) — the hh:mm so
  /// two same-day sets under the same template can still be told apart.
  String _subtitle(MeasurementSet set, Map<String, String> nameById) {
    final parts = <String>[_dateLabel(set)];
    final t = set.takenAt;
    if (t != null && (t.hour != 0 || t.minute != 0)) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      parts.add('$hh:$mm');
    }
    parts.add('${set.values.length} measurements');
    return parts.join(' · ');
  }

  String _dateLabel(MeasurementSet set) {
    final when = set.takenAt ?? set.createdAt;
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return 'Set from $y-$m-$d';
  }
}

/// Wraps the picked id so "picked None" (null) is distinguishable from
/// "dismissed the sheet" (the showModalBottomSheet future resolving null).
class _SnapshotChoice {
  const _SnapshotChoice(this.setId);
  final String? setId;
}
