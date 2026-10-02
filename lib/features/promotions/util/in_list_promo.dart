import '../models/promotion.dart';
import '../state/promotion_providers.dart';

/// Decide the in-list plan for one specific list feed (H5), from the resolved
/// `in_list_card` promotion. Injects only when a renderable, non-dismissed
/// campaign targets THIS list — its [Promotion.inListListKey], defaulting to
/// `clients` for campaigns authored before the list became configurable — and
/// uses the campaign's configured [Promotion.inListInterval] (falling back to
/// [kInListInterval]). Returns a non-injecting plan otherwise, so a screen with
/// no matching campaign adds no phantom row.
PromoInListPlan resolveInListPlan({
  required Promotion? promo,
  required Set<String> dismissed,
  required String thisList, // 'orders' | 'clients'
  required int contentCount,
}) {
  PromoInListPlan off() =>
      PromoInListPlan(contentCount: contentCount, enabled: false);

  if (promo == null || !promo.isRenderable) return off();
  if (dismissed.contains(promo.campaignId)) return off();
  final targetList = promo.inListListKey ?? 'clients'; // back-compat default
  if (targetList != thisList) return off();
  return PromoInListPlan(
    contentCount: contentCount,
    enabled: true,
    interval: promo.inListInterval ?? kInListInterval,
  );
}

/// Plan for injecting a single in-list house promo into a builder-driven list
/// (AD_SYSTEM Phase H4). It injects **exactly one** card, after [injectAt]
/// content rows, and only when the list is longer than that — so a short list is
/// never interrupted and a screen never carries more than one house promo (the
/// §7 density rule). This is the "configured interval" made concrete: the card
/// sits at a fixed position within the feed, not as a repeating cadence.
///
/// Pure index arithmetic (no widgets), so a screen keeps full control of its own
/// row/trailing (load-more) widgets and this stays trivially testable.
class PromoInListPlan {
  const PromoInListPlan._(this.injected, this.injectAt);

  /// Build a plan for a list of [contentCount] real items. Set [enabled] false
  /// (e.g. house promos globally off) to never inject. [interval] defaults to
  /// [kInListInterval].
  factory PromoInListPlan({
    required int contentCount,
    bool enabled = true,
    int interval = kInListInterval,
  }) {
    final inject = enabled && contentCount > interval;
    return PromoInListPlan._(inject, interval);
  }

  /// Whether a promo row is injected at all.
  final bool injected;

  /// The display index the promo row occupies (only meaningful when [injected]).
  final int injectAt;

  /// Extra rows this plan adds to the list's item count (0 or 1).
  int get extraCount => injected ? 1 : 0;

  /// Whether [displayIndex] is the injected promo row.
  bool isPromoAt(int displayIndex) => injected && displayIndex == injectAt;

  /// Map a display index back to the underlying content/trailing index (i.e.
  /// undo the shift the injected row introduces for everything after it).
  int contentIndex(int displayIndex) =>
      injected && displayIndex > injectAt ? displayIndex - 1 : displayIndex;
}
