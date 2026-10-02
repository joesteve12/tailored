import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/promotion.dart';
import '../state/promotion_providers.dart';
import 'promo_card.dart';

/// Process-lifetime guard: the app-open modal fires **at most once per cold
/// start** (a fresh app process). A top-level flag resets only when the isolate
/// is recreated (a real cold start), so navigating away from and back to Home,
/// or a warm resume, never re-shows it within the same launch. (Changed from the
/// former ≤once/calendar-day cap at the product owner's request — H5 round.)
bool _shownThisColdStart = false;

/// A zero-size trigger that shows the app-open promotion modal **once per cold
/// start** (AD_SYSTEM Phase H4, proposal §7). Mount it on a launch surface
/// (Home) — NOT inside any create/checkout/document flow — so the modal only
/// ever appears at app-open, never mid-task.
///
/// It renders nothing itself; when a campaign resolves for the `app_open_modal`
/// placement (which already requires house promos to be globally on) and it
/// hasn't fired yet this launch, it pops a centered dialog with a scrim over the
/// current screen. Everything else (audience, frequency, dismissal caps) was
/// decided server-side.
class AppOpenPromoTrigger extends ConsumerStatefulWidget {
  const AppOpenPromoTrigger({super.key});

  @override
  ConsumerState<AppOpenPromoTrigger> createState() =>
      _AppOpenPromoTriggerState();
}

class _AppOpenPromoTriggerState extends ConsumerState<AppOpenPromoTrigger> {
  // Guards to at most one attempt per app session — set synchronously the moment
  // a candidate is seen, so a rebuild can't schedule a second dialog.
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final promo = ref.watch(promotionProvider(kModalPopupPlacement)).valueOrNull;
    if (promo != null && promo.isRenderable && !_handled) {
      _handled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShow(promo);
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _maybeShow(Promotion promo) async {
    // Don't resurrect a card the shop already dismissed this session.
    if (ref.read(dismissedPromotionsProvider).contains(promo.campaignId)) return;

    // Once per cold start: the process-lifetime flag survives navigation and
    // warm resumes, and resets only on a fresh launch.
    if (_shownThisColdStart) return;
    _shownThisColdStart = true;

    if (!mounted) return;
    await showPromoDialog(context, ref, promo);
  }
}

/// Show one promotion as a centered, dismissable dialog with a scrim. The
/// card's dismiss (X) and any CTA both pop the dialog; a CTA also routes on
/// after popping so it doesn't navigate underneath the scrim.
Future<void> showPromoDialog(
  BuildContext context,
  WidgetRef ref,
  Promotion promo,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: PromoCard(
        promo: promo,
        onDismissed: () => Navigator.of(dialogContext).pop(),
        onNavigate: (route) {
          Navigator.of(dialogContext).pop();
          context.push(route);
        },
      ),
    ),
  );
}
