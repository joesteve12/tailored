import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../core/widgets/feedback.dart';
import '../data/billing_repository.dart';
import '../models/billing_responses.dart';
import '../models/entitlements.dart';
import '../screens/checkout_webview_screen.dart';
import '../state/entitlements_notifier.dart';

/// Route for the checkout WebView, registered in app_router. Kept next to the
/// screen that pushes it so the two can't drift.
const String kCheckoutPath = '/billing/checkout';

/// The "Plan & billing" screen (`/settings/plan`). Shows the shop's current
/// plan, status, trial/renewal countdown, live usage meters, and the saved-card
/// renewal mode; lets a shop subscribe to Studio through the in-app Paystack
/// checkout and turn off auto-renew.
///
/// Everything shown is read from `GET /me/entitlements`; every action goes
/// through the Phase 4/4B billing endpoints. Enforcement stays on the backend —
/// this screen only reflects and initiates.
class ManagePlanScreen extends ConsumerStatefulWidget {
  const ManagePlanScreen({super.key});

  @override
  ConsumerState<ManagePlanScreen> createState() => _ManagePlanScreenState();
}

class _ManagePlanScreenState extends ConsumerState<ManagePlanScreen> {
  // Which action is mid-flight, so exactly one spinner shows and the buttons
  // disable together. Null = idle.
  String? _busy;

  Future<void> _startCheckout(String interval) async {
    if (_busy != null) return;
    setState(() => _busy = 'checkout_$interval');
    try {
      final checkout = await ref
          .read(billingRepositoryProvider)
          .checkout(interval: interval);
      if (!mounted) return;
      final confirmed = await context.push<bool>(
        kCheckoutPath,
        extra: CheckoutArgs(
          authorizationUrl: checkout.authorizationUrl,
          reference: checkout.reference,
        ),
      );
      // Re-check regardless of how the WebView closed — a late webhook may have
      // applied the charge even if the shop backed out of the page.
      await ref.read(entitlementsProvider.notifier).refresh();
      if (!mounted) return;
      final ent = ref.read(entitlementsProvider).valueOrNull;
      if (confirmed == true || (ent != null && !ent.isStarter && !ent.isPastDue)) {
        showSuccessSnackbar(context, "You're on ${ent?.planLabel ?? 'Studio'} — thank you!");
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: 'Checkout failed');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _cancelAutoRenew() async {
    if (_busy != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn off auto-renew?'),
        content: const Text(
          'Your saved card will no longer be charged automatically. You keep '
          'your current plan until it expires, then renew manually with any '
          'payment method.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep auto-renew'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = 'cancel_auto');
    try {
      await ref.read(billingRepositoryProvider).cancelAutoRenew();
      await ref.read(entitlementsProvider.notifier).refresh();
      if (mounted) showSuccessSnackbar(context, 'Auto-renew turned off');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e, action: "Couldn't turn off auto-renew");
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// The app's origin (API base URL minus the `/api/v1` suffix), where the
  /// public legal pages are served.
  String get _legalOrigin =>
      ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('$_legalOrigin$path');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch returned false');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the page.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entAsync = ref.watch(entitlementsProvider);

    // Live plan prices (admin-editable). Null while loading / on error — the
    // card then shows a price placeholder but the buttons still work, since the
    // charge amount is authoritative on the backend.
    final plans = ref.watch(planOptionsProvider).valueOrNull;
    PlanOption? studioOption;
    if (plans != null) {
      for (final p in plans) {
        if (p.planCode == 'studio') {
          studioOption = p;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plan & billing')),
      body: entAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.read(entitlementsProvider.notifier).refresh(),
        ),
        data: (ent) => RefreshIndicator(
          // Refresh BOTH the entitlements and the live plan prices — the prices
          // (and the annual-saving caption) come from planOptionsProvider, so a
          // pull-to-refresh must recompute it or an admin-panel price change
          // wouldn't show until the screen is left and reopened.
          onRefresh: () => Future.wait([
            ref.read(entitlementsProvider.notifier).refresh(),
            ref.refresh(planOptionsProvider.future),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _PlanHeader(ent: ent),
              const SizedBox(height: 16),
              // Starter shops are NEVER shown their usage — no meters, no counts
              // (AD_SYSTEM decision 8 / proposal §6). The server still computes
              // usage for targeting/enforcement; the client just doesn't render
              // it. Trial (Studio limits) and paid tiers keep the meters.
              if (!ent.isStarter) ...[
                _UsageCard(ent: ent),
                const SizedBox(height: 16),
              ],
              if (ent.autoRenew) ...[
                _AutoRenewCard(
                  ent: ent,
                  busy: _busy == 'cancel_auto',
                  onCancel: _busy == null ? _cancelAutoRenew : null,
                ),
                const SizedBox(height: 16),
              ],
              _ChoosePlanCard(
                ent: ent,
                studioOption: studioOption,
                busyInterval: switch (_busy) {
                  'checkout_monthly' => 'monthly',
                  'checkout_annual' => 'annual',
                  _ => null,
                },
                anyBusy: _busy != null,
                onSubscribe: _startCheckout,
              ),
              const SizedBox(height: 14),
              Text(
                'Prices include 7.5% VAT. Payments are processed securely by '
                'Paystack. Paying with a card turns on automatic renewal; paying '
                'by transfer, USSD, or bank keeps renewal manual. No card details '
                'are stored on our servers.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: context.appTokens.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LegalLink('Terms', () => _openLegal('/legal/terms')),
                  Text('·', style: TextStyle(color: context.appTokens.mutedForeground)),
                  _LegalLink('Privacy', () => _openLegal('/legal/privacy')),
                  Text('·', style: TextStyle(color: context.appTokens.mutedForeground)),
                  _LegalLink('Auto-renewal', () => _openLegal('/legal/auto-renewal')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small inline text link into the public legal pages.
class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/// Rounded card shell used across this screen — matches the More hub's cards.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

/// Plan name, a status chip, and the trial/renewal countdown line.
class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.ent});

  final Entitlements ent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ent.planLabel,
                style: TextStyle(
                  fontFamily: tokens.fontDisplay,
                  fontFamilyFallback: tokens.fontDisplayFallback,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              if (ent.status != null) _StatusChip(status: ent.status!),
            ],
          ),
          if (_subtitle(ent) case final line?) ...[
            const SizedBox(height: 6),
            Text(
              line,
              style: TextStyle(fontSize: 13, color: tokens.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }

  String? _subtitle(Entitlements ent) {
    if (ent.isTrialing) {
      final d = ent.trialDaysLeft;
      if (d == null) return 'Free trial in progress';
      return d <= 0
          ? 'Your trial ends today'
          : 'Trial ends in $d day${d == 1 ? '' : 's'}';
    }
    if (ent.isPastDue) {
      return 'Payment overdue — renew to keep your plan.';
    }
    final end = ent.currentPeriodEnd;
    if (end != null) {
      final d = ent.renewalDaysLeft ?? 0;
      final when = ent.autoRenew ? 'Renews' : 'Expires';
      return '$when in $d day${d == 1 ? '' : 's'} (${_fmtDate(end)})';
    }
    if (ent.isStarter) {
      return 'The free plan. Upgrade any time to grow your shop.';
    }
    return null;
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // past_due rides the error role; everything else the brand primary.
    final accent = status == 'past_due' ? scheme.error : scheme.primary;
    final label = switch (status) {
      'trialing' => 'Trial',
      'active' => 'Active',
      'past_due' => 'Overdue',
      'canceled' => 'Canceled',
      'grandfathered' => 'Included',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

/// Live usage meters for the three numeric-limit dimensions.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.ent});

  final Entitlements ent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          _Meter(
            label: 'Active orders',
            used: ent.usage.activeOrders,
            limit: ent.limits.activeOrders,
          ),
          const SizedBox(height: 12),
          _Meter(
            label: 'Clients',
            used: ent.usage.clients,
            limit: ent.limits.clients,
          ),
          const SizedBox(height: 12),
          _Meter(
            label: 'Team members',
            used: ent.usage.employees,
            limit: ent.limits.employees,
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.used, required this.limit});

  final String label;
  final int used;

  /// `null` = unlimited.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    final unlimited = limit == null;
    final atLimit = !unlimited && used >= limit!;
    final fraction =
        unlimited ? 0.0 : (limit == 0 ? 1.0 : (used / limit!).clamp(0.0, 1.0));
    final barColor = atLimit ? scheme.error : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
            Text(
              unlimited ? '$used · Unlimited' : '$used / $limit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: atLimit ? scheme.error : tokens.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: unlimited ? null : fraction,
            minHeight: 6,
            backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

/// Saved-card / auto-renew row, shown only when the shop is on auto-renew.
class _AutoRenewCard extends StatelessWidget {
  const _AutoRenewCard({
    required this.ent,
    required this.busy,
    required this.onCancel,
  });

  final Entitlements ent;
  final bool busy;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-renew is on',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ent.cardLast4 != null
                          ? 'Renews automatically · card ending ${ent.cardLast4}'
                          : 'Renews automatically on your saved card',
                      style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: busy ? null : onCancel,
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Turn off auto-renew'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The subscribe / renew card. On Starter it's an upgrade CTA; on a paid plan
/// it's a renew CTA. Two intervals — monthly and annual (2 months free).
class _ChoosePlanCard extends StatelessWidget {
  const _ChoosePlanCard({
    required this.ent,
    required this.studioOption,
    required this.busyInterval,
    required this.anyBusy,
    required this.onSubscribe,
  });

  final Entitlements ent;

  /// The Studio plan + its live prices, or null while plans are loading / on
  /// error. Prices are read from this, never hardcoded, so an admin-panel price
  /// change is reflected here.
  final PlanOption? studioOption;

  /// 'monthly' | 'annual' | null — which button shows a spinner.
  final String? busyInterval;
  final bool anyBusy;
  final void Function(String interval) onSubscribe;

  /// Formats an interval price for a button, or a placeholder while prices load.
  String _priceLabel(double? naira, String suffix) =>
      naira == null ? '…' : '${formatNaira(naira)}$suffix';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    // A paid, active (non-trial, non-lapsed) Studio/Atelier shop is renewing;
    // everyone else is subscribing/upgrading.
    final renewing = !ent.isStarter && ent.status == 'active';
    final heading = renewing ? 'Renew Studio' : 'Studio';
    final blurb = renewing
        ? 'Extend your plan for another cycle.'
        : 'Unlimited analytics, custom templates, per-worker workflow, '
            'unwatermarked documents, and far higher limits.';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontFamily: tokens.fontDisplay,
              fontFamilyFallback: tokens.fontDisplayFallback,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            blurb,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          _PriceButton(
            title: 'Monthly',
            price: _priceLabel(studioOption?.monthlyNaira, '/mo'),
            filled: true,
            busy: busyInterval == 'monthly',
            onPressed: anyBusy ? null : () => onSubscribe('monthly'),
          ),
          const SizedBox(height: 10),
          _PriceButton(
            title: 'Annual',
            price: _priceLabel(studioOption?.annualNaira, '/yr'),
            note: studioOption?.annualSavingNote,
            filled: false,
            busy: busyInterval == 'annual',
            onPressed: anyBusy ? null : () => onSubscribe('annual'),
          ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.title,
    required this.price,
    required this.filled,
    required this.busy,
    required this.onPressed,
    this.note,
  });

  final String title;
  final String price;
  final String? note;
  final bool filled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final child = busy
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$title · ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (note != null) ...[
                const SizedBox(width: 8),
                Text(
                  note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: filled ? scheme.onPrimary : scheme.primary,
                  ),
                ),
              ],
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
