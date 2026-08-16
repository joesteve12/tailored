import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/errors.dart';
import '../../measurements/models/measurement_set.dart';
import '../../measurements/state/measurement_set_providers.dart';

/// The measurement snapshot an order item is cut from, expandable in place.
///
/// An item only carries `measurementSetIds`; before this widget, the order
/// screen showed a dead "Cut from saved measurements" chip and the actual
/// numbers — and the notes, which hold the fit preference the tailor works
/// from — lived two navigations away. Now the card answers "cut from what?"
/// where the question is asked.
///
/// The set is fetched **on first expand**, not on render: an order can hold
/// several items, and eagerly loading every snapshot would fire a request per
/// item the moment the screen opens, for data nobody may look at. The fetch
/// goes through [measurementSetByIdProvider], so a set already loaded by the
/// detail or capture screens renders instantly, and edits invalidate here too.
class MeasurementSnapshotSection extends ConsumerStatefulWidget {
  const MeasurementSnapshotSection({super.key, required this.setId});

  final String setId;

  @override
  ConsumerState<MeasurementSnapshotSection> createState() =>
      _MeasurementSnapshotSectionState();
}

class _MeasurementSnapshotSectionState
    extends ConsumerState<MeasurementSnapshotSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Only subscribe once opened — this is what defers the network call.
    final setAsync =
        _expanded ? ref.watch(measurementSetByIdProvider(widget.setId)) : null;
    final set = setAsync?.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.straighten_outlined, size: 15, color: context.appTokens.mutedForeground),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    // Before the fetch we can't know the set's name — the item
                    // only holds the id. Once loaded, the header names it.
                    set == null
                        ? 'Cut from saved measurements'
                        : 'Cut from: ${_setTitle(set)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.appTokens.mutedForeground),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: context.appTokens.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (_expanded && setAsync != null)
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 2),
            child: setAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        describeError(err),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          measurementSetByIdProvider(widget.setId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (set) => _SnapshotBody(set: set),
            ),
          ),
      ],
    );
  }

  static String _setTitle(MeasurementSet set) {
    if (set.label != null && set.label!.trim().isNotEmpty) {
      return set.label!.trim();
    }
    final d = set.takenAt ?? set.createdAt;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _SnapshotBody extends StatelessWidget {
  const _SnapshotBody({required this.set});

  final MeasurementSet set;

  @override
  Widget build(BuildContext context) {
    final notes = set.notes?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (set.values.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No values recorded in this set.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.appTokens.mutedForeground),
            ),
          )
        else
          // Same shape as the printed work order: label–value pairs flowing
          // two-ish to a row, so what's on screen is what lands on the card
          // the tailor holds.
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final v in set.values)
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${v.label}  ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.appTokens.mutedForeground),
                    ),
                    TextSpan(
                      text: v.display,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
            ],
          ),
        if (notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sticky_note_2_outlined,
                    size: 14, color: context.appTokens.mutedForeground),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appTokens.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push('/measurements/sets/${set.id}'),
            child: const Text('Open full set'),
          ),
        ),
      ],
    );
  }
}
