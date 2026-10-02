import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/client.dart';
import '../state/client_list_notifier.dart';
import '../../billing/models/entitlements.dart';
import '../../billing/state/entitlements_notifier.dart';
import '../../billing/widgets/upgrade_prompt.dart';
import '../../promotions/state/promotion_providers.dart';
import '../../promotions/util/in_list_promo.dart';
import '../../promotions/widgets/promo_slot.dart';
import '../../../core/ads/native_ad_card.dart';
import '../../../core/ads/native_ad_in_list.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/auth/models/user.dart';
import '../../../core/utils/hero_tags.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/theme/app_tokens.dart';

import '../../../core/widgets/feedback.dart';
class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger the next page a bit before hitting the literal bottom so
    // the next batch is loading by the time the user gets there.
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      ref.read(clientListProvider.notifier).loadMore().catchError((_) {
        if (!mounted) return;
        showErrorMessage(context, 'Could not load more clients');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(
      authStateProvider.select((state) => state.valueOrNull),
      (previous, next) {
        final prevId = previous?.id;
        final nextId = next?.id;
        if (prevId != nextId) {
          ref.read(clientListProvider.notifier).refresh().catchError((_) {});
        }
      },
    );

    final listState = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(clientListProvider.notifier).search(value),
            ),
          ),
          Expanded(
            child: listState.when(
              loading: () => const SkeletonList(
                scrollable: true,
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                separatorHeight: 10,
                itemBuilder: _clientSkeletonRow,
              ),
              error: (err, _) => AsyncErrorView(
                error: err,
                onRetry: () => ref.read(clientListProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  // See employee_list_screen for why the empty state needs a
                  // scrollable wrapper to enable pull-to-refresh here.
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(clientListProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child:
                              const Center(child: Text('No clients yet')),
                        ),
                      ],
                    ),
                  );
                }
                // One in-list house promo injected into a long-enough list
                // (proposal §5/§7 `in_list_card`) — never on a short list, and
                // at most one per screen. Driven by the resolved campaign: it
                // injects only when a campaign targets THIS list ('clients'),
                // at the campaign's configured interval, and adds no phantom row
                // otherwise (H5).
                final inListPromo =
                    ref.watch(promotionProvider(kInListPlacement)).valueOrNull;
                final promoPlan = resolveInListPlan(
                  promo: inListPromo,
                  dismissed: ref.watch(dismissedPromotionsProvider),
                  thisList: 'clients',
                  contentCount: state.items.length,
                );
                // One AdMob native card injected into a long-enough Customers
                // list (A4) — but only when NO house promo already owns this
                // screen (house > AdMob, LOCKED decision 9): disabled whenever
                // the house in-list card injects here. It also fails closed on
                // web / ineligible shops, so no phantom row is added there.
                final nativePlan = NativeAdInListPlan(
                  contentCount: state.items.length,
                  enabled: ref.watch(adsEnabledProvider) &&
                      !kIsWeb &&
                      !promoPlan.injected,
                );
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(clientListProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: state.items.length +
                        (state.hasMore ? 1 : 0) +
                        promoPlan.extraCount +
                        nativePlan.extraCount,
                    itemBuilder: (context, index) {
                      if (promoPlan.isPromoAt(index)) {
                        return const PromoSlot(
                          placement: kInListPlacement,
                          padding: EdgeInsets.symmetric(vertical: 4),
                        );
                      }
                      if (nativePlan.isPromoAt(index)) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: NativeAdCard(),
                        );
                      }
                      // Exactly one of the two plans injects (native is off when
                      // the house card is on), so a single contentIndex applies.
                      final itemIndex = promoPlan.injected
                          ? promoPlan.contentIndex(index)
                          : nativePlan.contentIndex(index);

                      if (itemIndex >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final client = state.items[itemIndex];
                      return _ClientListRow(
                        client: client,
                        // `extra: client` is load-bearing, not a shortcut.
                        // The detail screen needs a Client on its FIRST frame
                        // or its Hero isn't in the tree when the
                        // HeroController looks for a match — and it only looks
                        // once. Handing over the row we're already rendering
                        // is what makes the flight happen at all.
                        onTap: () => context.push(
                          '/clients/${client.id}',
                          extra: client,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clients',
        // Plan gate (UX only — the backend 402 is the real limit): if the shop
        // is at its client cap, prompt to upgrade instead of opening the form.
        onPressed: () async {
          if (!await guardCreate(context, ref, QuotaDimension.clients)) return;
          if (context.mounted) context.push('/clients/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Loading placeholder for one client row — mirrors the avatar + two text
/// lines + trailing order-count block of a real [_ClientListRow].
Widget _clientSkeletonRow(BuildContext context, int index) => const SkeletonTile(
      leadingDiameter: 48,
      hasTrailing: true,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

/// A client card: avatar + name/phone on the left, an order-count/
/// active-order stack on the right, matching the card layout design shared
/// for this screen.
///
/// The order count and active-order flag are placeholders — there is no
/// per-client order-stats endpoint yet (computing them for real would mean
/// firing a per-row orders request for every client in the list, an N+1 the
/// backend doesn't support today). Wire these up to real data once that
/// endpoint exists; until then they render a static zero/none state rather
/// than fabricated numbers.
class _ClientListRow extends StatelessWidget {
  const _ClientListRow({required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  static const _placeholderOrderCount = 0;
  static const _placeholderActiveOrders = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mutedForeground = context.appTokens.mutedForeground;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: clientPhotoHeroTag(client.id),
                // See client_detail_screen for why this is the centre-arc
                // variant and not the MaterialApp default. This Hero is the
                // *destination* when popping back from the detail screen, so
                // its tween governs the return flight.
                createRectTween: (begin, end) =>
                    MaterialRectCenterArcTween(begin: begin, end: end),
                transitionOnUserGestures: true,
                child: CircleAvatar(
                  radius: 24,
                  // Neutral warm placeholder, matching the app's other avatars
                  // (order_client_tile) and thumbnails rather than a brand tint.
                  backgroundColor: scheme.surfaceContainerHighest,
                  backgroundImage: client.photoUrl != null
                      ? NetworkImage(client.photoUrl!)
                      : null,
                  child: client.photoUrl == null
                      ? Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.appTokens.mutedForeground,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          client.phone,
                          style: textTheme.bodySmall
                              ?.copyWith(color: mutedForeground),
                        ),
                      ],
                    ),
                    if (_placeholderActiveOrders > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_placeholderActiveOrders active order'
                            '${_placeholderActiveOrders > 1 ? 's' : ''}',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_placeholderOrderCount',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ORDERS',
                    style: textTheme.labelSmall?.copyWith(
                      color: mutedForeground,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
