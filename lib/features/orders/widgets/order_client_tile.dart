import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/hero_tags.dart';
import '../../clients/state/client_detail_notifier.dart';

/// The "Belongs to" tile on the order detail screen — a tappable row showing
/// the client's avatar, name and phone, routing to `/clients/{id}`.
///
/// The order payload carries only `client_id` (OrderResponse has no client
/// name), so the name and phone are pulled from `clientDetailProvider`. That
/// costs one extra GET when the order screen opens — worth it, since a bare
/// "View client" row with no name is close to useless when you're looking at
/// an order and trying to remember whose it is. The provider is a family keyed
/// by client id and is shared with the client detail screen, so tapping
/// through is served from cache.
///
/// Every state stays tappable. If the fetch is still in flight, or fails
/// outright (offline, deleted client), the row degrades to a plain "View
/// client" and still routes — navigation never depends on the lookup
/// succeeding, because the id is right there in the order.
///
/// Deliberately styled as a Card + ListTile to match the client list screen's
/// row (same avatar-initial fallback, same chevron), so tapping it feels like
/// tapping the same client anywhere else in the app.
class OrderClientTile extends ConsumerWidget {
  const OrderClientTile({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: clientAsync.maybeWhen(
          // The Hero is attached only once the client has actually loaded.
          // Flying the grey placeholder and having it pop into a photo on
          // arrival looks broken; a tap during the (brief) load window simply
          // navigates with no animation instead. See hero_tags.dart for the
          // uniqueness rule this tag has to satisfy.
          data: (client) => Hero(
            tag: clientPhotoHeroTag(clientId),
            // Centre-arc rather than the MaterialApp default corner-arc: the
            // avatar grows 20px → 48px radius on the way to the detail screen,
            // and the default tween visibly squashes it mid-flight. See
            // client_detail_screen.dart for the full note.
            createRectTween: (begin, end) =>
                MaterialRectCenterArcTween(begin: begin, end: end),
            transitionOnUserGestures: true,
            child: CircleAvatar(
              backgroundImage: client.photoUrl != null
                  ? NetworkImage(client.photoUrl!)
                  : null,
              child: client.photoUrl == null
                  ? Text(client.name.isNotEmpty
                      ? client.name[0].toUpperCase()
                      : '?')
                  : null,
            ),
          ),
          orElse: () => CircleAvatar(
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person_outline, color: context.appTokens.mutedForeground),
          ),
        ),
        title: clientAsync.when(
          data: (client) => Text(client.name),
          loading: () => Text(
            'Loading…',
            style: TextStyle(color: context.appTokens.mutedForeground),
          ),
          // The client's details didn't load, but the order still belongs to
          // them and the route still works — so offer the trip rather than an
          // error the owner can do nothing about.
          error: (_, __) => const Text('View client'),
        ),
        subtitle: clientAsync.maybeWhen(
          data: (client) => Text(client.phone),
          orElse: () => null,
        ),
        trailing: const Icon(Icons.chevron_right),
        // Hand the loaded Client over so the detail screen can render its
        // avatar on frame 1 and the Hero has something to fly to. Null while
        // the lookup is still in flight — which is the same window in which
        // this tile has no Hero either, so there's nothing to fly and nothing
        // is lost. Navigation never depends on the lookup succeeding.
        onTap: () => context.push(
          '/clients/$clientId',
          extra: clientAsync.valueOrNull,
        ),
      ),
    );
  }
}
