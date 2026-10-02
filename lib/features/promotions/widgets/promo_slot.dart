import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/promotion_providers.dart';
import 'promo_card.dart';

/// A self-contained inline house-promotion slot for a placement (AD_SYSTEM Phase
/// H4). Drop it wherever a placement is allowed; it renders the resolved card or
/// nothing at all — fail-silent, exactly like [HomeBannerSlot]'s promo branch
/// (which now delegates here).
///
/// It handles the full quiet-path itself: asks [promotionProvider] only when
/// house promos are globally on (the provider fails closed otherwise), renders
/// nothing while loading/on error/on no-match, drops a card that isn't
/// renderable (empty or a too-new `schema_version`), and hides a card dismissed
/// this session. So a caller just places `PromoSlot(placement: …)` and never has
/// to reason about eligibility.
///
/// **Never mount this on a forbidden surface** (documents/checkout/create/auth):
/// the guardrail is structural — the widget simply isn't placed there (§7).
class PromoSlot extends ConsumerWidget {
  const PromoSlot({
    super.key,
    required this.placement,
    this.padding = EdgeInsets.zero,
  });

  final String placement;

  /// Spacing applied only when a card actually renders, so an empty slot takes
  /// zero space (no stray gap on a screen with no promo).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(promotionProvider(placement)).valueOrNull;
    if (promo == null || !promo.isRenderable) return const SizedBox.shrink();

    final dismissed = ref.watch(dismissedPromotionsProvider);
    if (dismissed.contains(promo.campaignId)) return const SizedBox.shrink();

    return Padding(padding: padding, child: PromoCard(promo: promo));
  }
}
