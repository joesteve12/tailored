import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/state/entitlements_notifier.dart';
import '../data/promotions_repository.dart';
import '../models/promotion.dart';

/// Placement keys the client asks for (proposal §5 + H4). The server targets
/// campaigns at these exact strings; a new key is a code change on both sides
/// (LOCKED decision 14), never a migration. A placement is only ever mounted on
/// a **non-forbidden** surface — never on document/checkout/create/auth screens.
const String kHomeBannerPlacement = 'home_banner';

/// Bottom of the Orders list, after content — a contextual, never-interrupting
/// upgrade slot (proposal §5).
const String kOrdersFooterPlacement = 'orders_list_footer';

/// Inline card in the calm "More"/Settings hub (proposal §5).
const String kMoreTabPlacement = 'more_tab_card';

/// Hint card shown on an empty list (Orders/Customers/Fabric) — onboarding
/// education for new trials (proposal §5).
const String kEmptyStatePlacement = 'empty_state';

/// The existing feature-gate upgrade sheet — the ad system supplies its
/// copy/targeting; it only ever appears because the user hit a gate, so it's
/// never an interruption (proposal §5).
const String kFeatureGateSheetPlacement = 'feature_gate_sheet';

/// Card injected *inside* a long list at an interval (H4). Distinct from the
/// footer: appears between rows, once, on scrollable feeds.
const String kInListPlacement = 'in_list_card';

/// App-open centered modal (H4). Capped to at most once per day on the client
/// and never shown mid-task.
const String kModalPopupPlacement = 'app_open_modal';

/// How many content rows precede an injected in-list card (H4). One card is
/// injected, once, and only when the list is longer than this — so a short list
/// is never interrupted and a screen never shows more than one house promo.
const int kInListInterval = 6;

/// The one promotion for a placement, or null (AD_SYSTEM Phase H3). Mirrors the
/// illustrative provider in proposal §10.
///
/// There is deliberately **no client-side plan fast-path**: the SERVER decides
/// audience per campaign (a paid shop may still match an announcement), so the
/// client just asks and renders what comes back. The only client-side
/// short-circuit is the global [promosEnabledProvider] switch — when house
/// promos are off (or the snapshot is still unknown / failed closed), we don't
/// even ask. Fetch failures resolve to null (fail-silent) inside the repository.
///
/// `family` by placement so each slot resolves independently and is cached by
/// its key; `autoDispose` so a slot that scrolls out of the tree stops holding a
/// result (and refetches fresh when it returns).
final promotionProvider =
    FutureProvider.autoDispose.family<Promotion?, String>((ref, placement) async {
  if (!ref.watch(promosEnabledProvider)) return null;
  return ref.read(promotionsRepositoryProvider).fetch(placement);
});

/// Campaign ids the shop dismissed **this session**. The server already records
/// the dismissal (and its caps suppress the campaign on the next fetch), but a
/// dismiss must hide the card *immediately* without waiting for a refetch — this
/// set is that instant local memory. Keyed by campaign id so it survives a card
/// rebuild. Cleared naturally on app restart (the server's caps take over then).
final dismissedPromotionsProvider =
    NotifierProvider<DismissedPromotionsNotifier, Set<String>>(
  DismissedPromotionsNotifier.new,
);

class DismissedPromotionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void dismiss(String campaignId) {
    if (state.contains(campaignId)) return;
    state = {...state, campaignId};
  }
}
