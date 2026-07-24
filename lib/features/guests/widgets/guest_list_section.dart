import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/guest_profile.dart';
import '../state/guest_list_notifier.dart';
import '../../../core/widgets/async_error_view.dart';

/// Embeddable "Guests" block dropped into ClientDetailScreen. Pulled out
/// as its own widget — rather than inlined directly — purely so the
/// list/add-button UI lives in one place. Only one screen uses this
/// today, but writing it standalone costs nothing and avoids a
/// copy-paste if a second use case shows up later.
class GuestListSection extends ConsumerWidget {
  const GuestListSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(guestListProvider(clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Guests', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: 'Add guest',
              onPressed: () => context.push('/clients/$clientId/guests/new'),
            ),
          ],
        ),
        guestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => AsyncErrorView(
            error: err,
            compact: true,
            onRetry: () => ref.read(guestListProvider(clientId).notifier).refresh(),
          ),
          data: (guests) {
            if (guests.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No guests yet'),
              );
            }
            return Column(
              children: guests
                  .map((guest) => _GuestTile(clientId: clientId, guest: guest))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({required this.clientId, required this.guest});

  final String clientId;
  final GuestProfile guest;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage:
            guest.photoUrl != null ? NetworkImage(guest.photoUrl!) : null,
        child: guest.photoUrl == null
            ? Text(guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(guest.name),
      subtitle: guest.relation != null && guest.relation!.isNotEmpty
          ? Text(guest.relation!)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/clients/$clientId/guests/${guest.id}'),
    );
  }
}
