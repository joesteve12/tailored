import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/entitlements.dart';
import '../state/entitlements_notifier.dart';
import 'upgrade_prompt.dart';

/// A status-driven billing banner for the Home tab. Renders at most one message,
/// in priority order, and nothing at all when there's nothing to say (a healthy
/// paid/grandfathered shop well under its caps):
///
///   1. `past_due`     — payment overdue, renew to keep Studio (error tint)
///   2. over-limit     — a Starter shop has hit a cap; upgrade to grow (primary)
///   3. trial countdown — days left on the Studio trial (primary, low-key)
///
/// Silent while loading or on error — Home is a launchpad, and a billing nudge
/// is never worth a spinner or a red box there. Tapping any banner opens the
/// manage-plan screen.
class BillingBanner extends ConsumerWidget {
  const BillingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementsProvider).valueOrNull;
    if (ent == null) return const SizedBox.shrink();

    // Same predicate the house-promo slot yields to (AD_SYSTEM §7): keeps
    // "billing has something to say" defined in one place so precedence and the
    // rendered banner can't diverge. When true, _resolve always yields a spec.
    if (!ent.showsHomeBillingBanner) return const SizedBox.shrink();

    final banner = _resolve(context, ent);
    if (banner == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _BannerCard(spec: banner),
    );
  }

  _BannerSpec? _resolve(BuildContext context, Entitlements ent) {
    final scheme = Theme.of(context).colorScheme;

    // 1. Past due — the loudest state: a charge failed and the grace clock is
    // running. Full access for now, but act.
    if (ent.isPastDue) {
      return _BannerSpec(
        icon: Icons.error_outline,
        accent: scheme.error,
        title: 'Payment overdue',
        message:
            'Renew to keep your ${ent.planLabel} features before your access drops to Starter.',
        cta: 'Renew now',
      );
    }

    // 2. Over-limit — a Starter (or lapsed) shop is carrying MORE than a cap
    // allows (strictly over, not merely at it); existing work is safe, but they
    // can't add more until they upgrade or wind down. A shop using exactly its
    // allowance is healthy and gets no banner — it just meets the create-gate
    // (with its own upgrade prompt) if it tries to add another.
    if (ent.isAnyExceedingLimit) {
      return _BannerSpec(
        icon: Icons.lock_outline,
        accent: scheme.primary,
        title: "You've hit your ${ent.planLabel} limit",
        message:
            'Your data is safe. Upgrade to add more clients, orders, and team members.',
        cta: 'View plans',
      );
    }

    // 3. Trial countdown — only while actually trialing and the end is known.
    if (ent.isTrialing) {
      final days = ent.trialDaysLeft;
      if (days != null) {
        final dayLabel = days <= 0
            ? 'Your trial ends today'
            : '$days day${days == 1 ? '' : 's'} left on your ${ent.planLabel} trial';
        return _BannerSpec(
          icon: Icons.hourglass_bottom_outlined,
          accent: scheme.primary,
          title: dayLabel,
          message:
              'Choose a plan to keep ${ent.planLabel} features when your trial ends.',
          cta: 'Choose a plan',
        );
      }
    }

    return null;
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.cta,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String cta;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.spec});

  final _BannerSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return Material(
      color: spec.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: InkWell(
        onTap: () => context.push(kManagePlanPath),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(spec.icon, size: 22, color: spec.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.message,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          spec.cta,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: spec.accent,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: spec.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
