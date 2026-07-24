import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recipient_ref.dart';
import '../../guests/state/guest_list_notifier.dart';

/// "Who is this garment for?" — the client themselves, or one of their
/// guests. Extracted from the original add-item sheet so both the create
/// and edit item sheets share one implementation.
///
/// If the guest list fails to load, this still offers the client as a
/// recipient (an item for the client themselves shouldn't be blocked by a
/// guests fetch failing) — the same graceful-degradation choice the
/// original sheet made.
class RecipientPicker extends ConsumerWidget {
  const RecipientPicker({
    super.key,
    required this.clientId,
    required this.selected,
    required this.onChanged,
  });

  final String clientId;
  final RecipientRef? selected;
  final ValueChanged<RecipientRef> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(guestListProvider(clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is this for?',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        guestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => RadioListTile<RecipientRef>(
            contentPadding: EdgeInsets.zero,
            value: clientRecipient(clientId),
            groupValue: selected,
            title: const Text('The client'),
            subtitle: const Text("Couldn't load guests — try again later"),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
          data: (guests) => Column(
            children: [
              RadioListTile<RecipientRef>(
                contentPadding: EdgeInsets.zero,
                value: clientRecipient(clientId),
                groupValue: selected,
                title: const Text('The client'),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
              for (final guest in guests)
                RadioListTile<RecipientRef>(
                  contentPadding: EdgeInsets.zero,
                  value: guestRecipient(guest.id),
                  groupValue: selected,
                  title: Text(guest.name),
                  subtitle:
                      guest.relation != null ? Text(guest.relation!) : null,
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
