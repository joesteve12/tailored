import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../promotions/state/promotion_providers.dart';
import '../../promotions/widgets/promo_slot.dart';
import '../models/entitlements.dart';
import '../state/entitlements_notifier.dart';

/// The billing route the upgrade prompts and banners send the shop to.
const String kManagePlanPath = '/settings/plan';

/// Show a bottom sheet explaining that a plan limit was hit and offering the
/// path to the plans screen. Purely a friendlier stand-in for the 402 the
/// backend would return anyway (proposal §5: frontend gating is UX).
Future<void> showUpgradeSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final tokens = sheetContext.appTokens;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // House-promo slot for the feature gate (proposal §5
              // `feature_gate_sheet`). Only ever seen because the user hit a
              // gate, so it's contextual, not an interruption; renders nothing
              // unless a campaign targets this shop. The concrete gate copy
              // below always stays as the explanation.
              const PromoSlot(
                placement: kFeatureGateSheetPlacement,
                padding: EdgeInsets.only(bottom: 16),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.workspace_premium_outlined,
                        size: 22, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: tokens.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(kManagePlanPath);
                },
                child: const Text('View plans'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Owner-facing copy for the create-limit prompt on each numeric dimension —
/// deliberately close to the backend's own 402 messages so the pre-emptive
/// prompt and the fallback 402 read consistently.
///
/// When [hideNumber] is true (a Starter shop — AD_SYSTEM decision 8 / proposal
/// §6: "Starter shops are never shown their usage"), the copy omits the count
/// entirely, mirroring the backend's `_QUOTA_MESSAGES_STARTER`. Trial (Studio
/// limits) and paid tiers keep the exact number.
({String title, String message}) _copyFor(
  QuotaDimension dim,
  int? limit, {
  bool hideNumber = false,
}) {
  if (hideNumber) {
    return switch (dim) {
      QuotaDimension.clients => (
          title: 'Client limit reached',
          message:
              "You've reached your plan's limit for clients. Upgrade to add more.",
        ),
      QuotaDimension.employees => (
          title: 'Employee limit reached',
          message:
              "You've reached your plan's limit for team members. Upgrade to add more of your team.",
        ),
      QuotaDimension.activeOrders => (
          title: 'Active-order limit reached',
          message:
              "You've reached your plan's limit for active orders. Upgrade to add more.",
        ),
    };
  }
  final n = limit?.toString() ?? 'your plan\'s';
  return switch (dim) {
    QuotaDimension.clients => (
        title: 'Client limit reached',
        message:
            "You've reached your plan's limit of $n clients. Upgrade to add more.",
      ),
    QuotaDimension.employees => (
        title: 'Employee limit reached',
        message:
            "Your plan includes $n employee${limit == 1 ? '' : 's'}. Upgrade to add more of your team.",
      ),
    QuotaDimension.activeOrders => (
        title: 'Active-order limit reached',
        message:
            "You've reached your plan's limit of $n active orders. Deliver or "
                "cancel an order to free a slot, or upgrade for more.",
      ),
  };
}

/// Gate a create action against the shop's plan. Refreshes the shared
/// entitlements snapshot (so the banner and meters update too), and if the shop
/// is at/over the cap for [dim] shows the upgrade sheet and returns `false`;
/// otherwise returns `true` and the caller proceeds.
///
/// Fail-open by design: on any load error, or while the snapshot is unknown, it
/// returns `true` and lets the request through — the backend's 402 is the real
/// gate, and blocking on a UI-only failure would trap a paying shop.
Future<bool> guardCreate(
  BuildContext context,
  WidgetRef ref,
  QuotaDimension dim,
) async {
  await ref.read(entitlementsProvider.notifier).refresh();
  final ent = ref.read(entitlementsProvider).valueOrNull;
  if (ent == null || !ent.isOverLimit(dim)) return true;

  if (!context.mounted) return false;
  // Starter shops get the numberless copy (usage-hiding, decision 8); the number
  // is kept for trial (Studio limits) and paid tiers.
  final copy = _copyFor(dim, ent.limitFor(dim), hideNumber: ent.isStarter);
  await showUpgradeSheet(context, title: copy.title, message: copy.message);
  return false;
}
