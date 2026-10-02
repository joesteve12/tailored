import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/promotions_repository.dart';
import '../models/promotion.dart';
import '../state/promotion_providers.dart';
import 'promo_block_renderer.dart';

/// The single native card that renders any campaign's block `content` (AD_SYSTEM
/// Phase H3). A visual sibling of BillingBanner's card — same radius/tint tokens
/// — so a promotion looks like the app, not like an ad unit (proposal §10).
///
/// Composes the ordered blocks, applies the campaign's card-level style (accent,
/// background image/gradient with an auto-scrim for contrast), shows a subtle
/// "Sponsored" label for sponsored inventory, and carries a dismiss affordance
/// (X → POST `dismissed`, and hide immediately this session). A `button` block
/// tap records a `clicked` event and follows its optional in-app `route`.
class PromoCard extends ConsumerWidget {
  const PromoCard({
    super.key,
    required this.promo,
    this.onDismissed,
    this.onNavigate,
  });

  final Promotion promo;

  /// Called after the card handles a dismiss (records + hides). A modal host
  /// passes this to also pop its dialog; inline slots leave it null.
  final VoidCallback? onDismissed;

  /// Overrides a `button` block's in-app navigation. A modal host passes this to
  /// pop its dialog *before* routing (so it doesn't navigate under the scrim);
  /// inline slots leave it null and the card pushes the route directly.
  final void Function(String route)? onNavigate;

  void _recordClick(WidgetRef ref, PromoBlock block) {
    ref.read(promotionsRepositoryProvider).recordEvent(
          campaignId: promo.campaignId,
          kind: 'clicked',
          placement: promo.placement,
        );
  }

  void _onButtonTap(BuildContext context, WidgetRef ref, PromoBlock block) {
    _recordClick(ref, block);
    // Optional in-app destination (e.g. the manage-plan screen for an upgrade
    // CTA). Content is operator-authored server-side, so a provided route is
    // trusted; absent route = the click is recorded and nothing navigates.
    final route = block.str('route');
    if (route != null) {
      if (onNavigate != null) {
        onNavigate!(route);
      } else {
        context.push(route);
      }
    }
  }

  void _dismiss(WidgetRef ref) {
    ref.read(promotionsRepositoryProvider).recordEvent(
          campaignId: promo.campaignId,
          kind: 'dismissed',
          placement: promo.placement,
        );
    // Hide instantly this session; the server's caps keep it away after refetch.
    ref.read(dismissedPromotionsProvider.notifier).dismiss(promo.campaignId);
    onDismissed?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.appTokens;

    final accent = _parseHex(promo.card?.accentHex) ?? scheme.primary;
    final background = _resolveBackground(promo);
    final hasImage = background.imageUrl != null;
    // Both an image and a gradient are "art" the card sits on — default body
    // text goes light over either, matching the builder's live preview (which
    // flips to white text over an image OR a 2-stop gradient).
    final overArt = hasImage || background.gradient != null;

    // The campaign accent is honoured everywhere — including over art — so an
    // operator's chosen colour (badges, stat, buttons, bullets) actually shows,
    // matching the builder's live preview. Only the default BODY text flips to
    // light over art, for legibility; a block that sets its own `color`
    // overrides even that (handled in the renderer). On a plain tinted card we
    // use the normal on-surface roles.
    final style = PromoRenderStyle(
      accent: accent,
      onAccent: _onColor(accent),
      primaryText: overArt ? Colors.white : scheme.onSurface,
      mutedText: overArt
          ? Colors.white.withValues(alpha: 0.82)
          : tokens.mutedForeground,
      onButtonTap: (block) => _onButtonTap(context, ref, block),
    );

    final content = _content(context, style);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Stack(
        children: [
          // ── Background layer ────────────────────────────────────────────────
          if (background.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                background.imageUrl!,
                fit: BoxFit.cover,
                // A broken background collapses to the plain accent tint rather
                // than breaking the card (fail-silent).
                errorBuilder: (_, __, ___) =>
                    ColoredBox(color: accent.withValues(alpha: 0.10)),
              ),
            )
          else if (background.gradient != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: background.gradient),
              ),
            ),
          // Auto-scrim: a bottom-heavy dark gradient so text stays legible over
          // any image (proposal H3 "card-level image background with auto-scrim").
          if (background.imageUrl != null)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xCC000000)],
                  ),
                ),
              ),
            ),
          // ── Content ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 40, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: content,
            ),
          ),
          // ── Dismiss affordance ──────────────────────────────────────────────
          Positioned(
            top: 4,
            right: 4,
            child: _DismissButton(
              color: style.mutedText,
              onTap: () => _dismiss(ref),
            ),
          ),
        ],
      ),
    );

    // Plain (imageless) cards get the same soft tinted fill BillingBanner uses,
    // so a promotion reads as a sibling of the billing nudge; image/gradient
    // cards paint their own background above.
    if (!hasImage && background.gradient == null) {
      return Material(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: card,
      );
    }
    return card;
  }

  /// The block widgets, plus a leading "Sponsored" label for sponsored inventory
  /// (proposal §7 — honesty separates our recommendation from a paid one).
  List<Widget> _content(BuildContext context, PromoRenderStyle style) {
    final widgets = <Widget>[];

    if (promo.isSponsored) {
      final label = promo.sponsorName != null
          ? 'Sponsored · ${promo.sponsorName}'
          : 'Sponsored';
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
            color: style.mutedText,
          ),
        ),
      ));
    }

    // Background blocks are painted at card level (not inline); everything else
    // renders in order with a small gap between blocks.
    final blocks = promo.content.where((b) => b.type != 'background').toList();
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0 || promo.isSponsored) {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(buildPromoBlock(context, blocks[i], style));
    }
    return widgets;
  }
}

/// Small circular dismiss (X) in the card corner.
class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.close, size: 16, color: color),
        ),
      ),
    );
  }
}

/// Resolved card background — at most one of [imageUrl] / [gradient] is set.
class _Background {
  const _Background({this.imageUrl, this.gradient});
  final String? imageUrl;
  final Gradient? gradient;
}

/// Prefer the `card` style; fall back to a `background` block's props.
_Background _resolveBackground(Promotion promo) {
  final card = promo.card;
  if (card?.backgroundImageUrl != null) {
    return _Background(imageUrl: card!.backgroundImageUrl);
  }
  final gradientHex = card?.backgroundGradientHex;
  if (gradientHex != null && gradientHex.length >= 2) {
    return _Background(gradient: _gradient(gradientHex));
  }

  // A `background` block is an alternative way to set the card background.
  for (final block in promo.content) {
    if (block.type != 'background') continue;
    final image = block.str('image');
    if (image != null) return _Background(imageUrl: image);
    final stops = block.strings('gradient');
    if (stops.length >= 2) return _Background(gradient: _gradient(stops));
  }
  return const _Background();
}

Gradient _gradient(List<String> hex) {
  final colors = [
    for (final h in hex) _parseHex(h) ?? Colors.transparent,
  ];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );
}

/// Parse a `#RRGGBB` / `#AARRGGBB` (or without the `#`) hex string to a Color.
/// Returns null on anything unparseable, so a bad value falls back to a default.
Color? _parseHex(String? raw) {
  if (raw == null) return null;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex'; // assume opaque
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

/// Black or white, whichever reads better on [background] (for filled buttons).
Color _onColor(Color background) {
  return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
