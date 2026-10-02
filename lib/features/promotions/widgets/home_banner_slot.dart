import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/state/entitlements_notifier.dart';
import '../../billing/widgets/billing_banner.dart';
import '../state/promotion_providers.dart';
import 'promo_slot.dart';

/// The Home `home_banner` slot (AD_SYSTEM Phase H3). A thin precedence wrapper
/// that expresses the load-bearing rule by ORDER (proposal §7/§10):
///
///   1. **Billing always wins.** If the billing banner has something to say
///      (past-due / over-limit / trial countdown), show it and never a promo.
///   2. else a **house promotion** for `home_banner`, when the global switch is
///      on and one resolves for this shop.
///   3. else **nothing** (`SizedBox.shrink`).
///
/// This is the singular Home slot — at most one thing renders here, ever. Silent
/// while the entitlements snapshot is unknown, so a logged-out/loading frame
/// shows neither (both systems fail closed).
class HomeBannerSlot extends ConsumerWidget {
  const HomeBannerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementsProvider).valueOrNull;
    if (ent == null) return const SizedBox.shrink();

    // 1. Billing pre-empts everything (BillingBanner supplies its own spacing).
    if (ent.showsHomeBillingBanner) {
      return const BillingBanner();
    }

    // 2. House promo — only when promos are globally on (fails closed on
    // disabled/unknown; NOT plan-filtered — the server decides audience). The
    // slot itself renders nothing when no campaign resolves, matching
    // BillingBanner's bottom spacing when one does.
    if (!ent.promosEnabled) return const SizedBox.shrink();

    return const PromoSlot(
      placement: kHomeBannerPlacement,
      padding: EdgeInsets.only(bottom: 12),
    );
  }
}
