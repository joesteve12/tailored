/// Placement thresholds for the AdMob **native advanced** card injected into a
/// long feed (AD_SYSTEM Phase A4 — see `ADMOB_INTEGRATION.md` §3, §4).
library;

/// Don't inject a native card into a list shorter than this (§3): a shop with a
/// handful of orders should never see an ad wedged into a near-empty list.
const int kNativeAdMinItems = 12;

/// The content row after which the single native card sits (§3/§4): a fixed
/// position, so at most one native card is ever on screen at a time. Kept below
/// [kNativeAdMinItems] so the card lands mid-feed, not at the very top or the
/// tail.
const int kNativeAdInjectAt = 8;

/// Plan for injecting **exactly one** AdMob native card into a builder-driven
/// list (A4). It injects a single card after [kNativeAdInjectAt] content rows,
/// and only when the list has at least [kNativeAdMinItems] items — so a short
/// list is never interrupted and only one card is ever in view (§3/§4).
///
/// Deliberately mirrors the house engine's `PromoInListPlan` shape (same
/// `injected` / `injectAt` / `extraCount` / `isPromoAt` / `contentIndex` API) so
/// a list screen composes it the same way — but it is a separate, AdMob-owned
/// type (no dependency on the promotions module). Pure index arithmetic, no
/// widgets, so it stays trivially testable.
///
/// **The AdMob native card yields to any house promo on the same screen**
/// (LOCKED decision 9 — house > AdMob): the caller passes `enabled: false`
/// whenever a house in-list / footer card will render, so the two never coexist.
/// The full cross-surface arbitration (banner suppression, interstitial
/// coordination) remains U1's job; this is only the minimal local yield that
/// keeps the "one ad per screen" guardrail intact before U1 exists.
class NativeAdInListPlan {
  const NativeAdInListPlan._(this.injected, this.injectAt);

  /// Build a plan for a list of [contentCount] real items. Set [enabled] false
  /// (ineligible shop, web, or a house promo already on this screen) to never
  /// inject.
  factory NativeAdInListPlan({
    required int contentCount,
    bool enabled = true,
    int minItems = kNativeAdMinItems,
    int injectAt = kNativeAdInjectAt,
  }) {
    final inject = enabled && contentCount >= minItems;
    return NativeAdInListPlan._(inject, injectAt);
  }

  /// Whether a native card row is injected at all.
  final bool injected;

  /// The display index the card occupies (only meaningful when [injected]).
  final int injectAt;

  /// Extra rows this plan adds to the list's item count (0 or 1).
  int get extraCount => injected ? 1 : 0;

  /// Whether [displayIndex] is the injected native-card row.
  bool isPromoAt(int displayIndex) => injected && displayIndex == injectAt;

  /// Map a display index back to the underlying content/trailing index (undo the
  /// shift the injected row introduces for everything after it).
  int contentIndex(int displayIndex) =>
      injected && displayIndex > injectAt ? displayIndex - 1 : displayIndex;
}
