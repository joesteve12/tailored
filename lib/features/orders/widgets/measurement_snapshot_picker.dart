import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../measurements/models/measurement_set.dart';
import '../../measurements/models/measurement_template.dart';
import '../../measurements/state/measurement_dictionary_providers.dart';
import '../../measurements/state/measurement_list_notifier.dart';

/// Lets an order item record which of the recipient's measurement sets it
/// was "cut from" (the snapshot link the backend stores in
/// `measurement_set_ids`). A garment can be several pieces — a top and a
/// skirt, say — each cut from its own set, so this picks *any number* of
/// sets. Shows the recipient's sets newest-first with a checkbox each;
/// reports the chosen ids via [onChanged].
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
    required this.selectedSetIds,
    required this.onChanged,
  });

  final RecipientRef recipient;
  final List<String> selectedSetIds;
  final ValueChanged<List<String>> onChanged;

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
        title: Text('Measurement snapshots'),
        subtitle: Text('Loading measurement sets…'),
      ),
      error: (_, __) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.straighten_outlined),
        title: const Text('Measurement snapshots'),
        subtitle: const Text("Couldn't load measurement sets"),
        trailing: TextButton(
          onPressed: () =>
              ref.read(measurementListProvider(recipient).notifier).refresh(),
          child: const Text('Retry'),
        ),
      ),
      data: (sets) {
        final chosen = _chosenSets(sets);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.straighten_outlined),
          title: const Text('Measurement snapshots'),
          subtitle: Text(
            chosen.isNotEmpty
                ? 'Cut from: '
                    '${chosen.map((s) => _primaryLabel(s, nameById)).join(', ')}'
                : sets.isEmpty
                    ? 'No measurement sets for this recipient yet'
                    : 'None selected',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: sets.isEmpty ? null : () => _pick(context, sets, nameById),
        );
      },
    );
  }

  /// The selected sets, in the list's newest-first order (so the field's
  /// summary reads the same way the picker does), filtered to ids that still
  /// exist for this recipient.
  List<MeasurementSet> _chosenSets(List<MeasurementSet> sets) {
    final wanted = selectedSetIds.toSet();
    return [for (final s in sets) if (wanted.contains(s.id)) s];
  }

  Future<void> _pick(
    BuildContext context,
    List<MeasurementSet> sets,
    Map<String, String> nameById,
  ) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Local, mutable selection committed only on "Done" — so dismissing
        // the sheet (swipe / tap-out) leaves the item's snapshots unchanged.
        final working = selectedSetIds.toSet();
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Cut from which measurements?',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, working.toList()),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in sets)
                        CheckboxListTile(
                          value: working.contains(s.id),
                          controlAffinity: ListTileControlAffinity.leading,
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
                          onChanged: (checked) => setSheetState(() {
                            if (checked ?? false) {
                              working.add(s.id);
                            } else {
                              working.remove(s.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) onChanged(result);
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
