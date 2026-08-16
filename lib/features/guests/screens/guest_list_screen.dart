import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../clients/state/client_detail_notifier.dart';
import '../models/guest_profile.dart';
import '../state/guest_list_notifier.dart';

/// Full-screen guest list for one client — reached from the "Guests" figure on
/// the client detail header. Replaces the old embedded `GuestListSection`: the
/// detail screen just shows the count now, and the roster lives here with room
/// to breathe (avatar cards, a proper empty state, pull-to-refresh).
class GuestListScreen extends ConsumerWidget {
  const GuestListScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestsAsync = ref.watch(guestListProvider(clientId));
    final scheme = Theme.of(context).colorScheme;

    // Title carries the client's name when it's already cached (opening this
    // screen from the detail page means it is); falls back to a plain title on
    // a cold deep-link before the client loads.
    final clientName =
        ref.watch(clientDetailProvider(clientId)).valueOrNull?.name.trim();
    final title = (clientName != null && clientName.isNotEmpty)
        ? "$clientName's guests"
        : 'Guests';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_client_guests',
        onPressed: () => context.push('/clients/$clientId/guests/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add guest'),
      ),
      body: guestsAsync.when(
        loading: () => const SkeletonList(
          scrollable: true,
          itemCount: 6,
          separatorHeight: 10,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemBuilder: _guestSkeletonRow,
        ),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.read(guestListProvider(clientId).notifier).refresh(),
        ),
        data: (guests) {
          if (guests.isEmpty) {
            return _EmptyState(
              onRefresh: () =>
                  ref.read(guestListProvider(clientId).notifier).refresh(),
              onAdd: () => context.push('/clients/$clientId/guests/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(guestListProvider(clientId).notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: guests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _GuestCard(
                clientId: clientId,
                guest: guests[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loading placeholder for one guest row — avatar + name/relation, matching
/// [_GuestCard]'s shape.
Widget _guestSkeletonRow(BuildContext context, int index) => const SkeletonTile(
      leadingDiameter: 48,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

/// One guest as a tappable card — a step up from the old borderless ListTile:
/// a rounded surface with a larger avatar, the name in title weight, the
/// relation beneath, and a chevron into the guest detail.
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.clientId, required this.guest});

  final String clientId;
  final GuestProfile guest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final relation = guest.relation?.trim() ?? '';
    final initial = guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?';

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/clients/$clientId/guests/${guest.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                foregroundColor: scheme.primary,
                backgroundImage: guest.photoUrl != null
                    ? NetworkImage(guest.photoUrl!)
                    : null,
                child: guest.photoUrl == null
                    ? Text(initial,
                        style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      guest.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (relation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          relation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: scheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the client has no guests — an icon, a line of copy, and a
/// primary "Add guest" action, all reachable inside a pull-to-refresh.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh, required this.onAdd});

  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined,
                      size: 48, color: scheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No guests yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Add the people this client orders for.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add guest'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
