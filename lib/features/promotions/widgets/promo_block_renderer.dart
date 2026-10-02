import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/promotion.dart';

/// Renders one promotion [PromoBlock] as a native widget (AD_SYSTEM Phase H3 —
/// the SDUI Level-3 block engine). The card is composed by mapping each block in
/// `content[]` through here; this is NOT a fixed-template picker.
///
/// **Forward-compatible by contract:** a block `type` this build doesn't know
/// renders as `SizedBox.shrink()` (skipped, never a crash), so a newer campaign
/// degrades gracefully on an older app (LOCKED decision 6). Every prop is read
/// with a safe default for the same reason.
///
/// Colours come from [PromoRenderStyle], which the card fills from the theme +
/// the campaign's `card` accent and flips to a light-on-dark palette when the
/// card sits on a background image (auto-scrim).
Widget buildPromoBlock(
  BuildContext context,
  PromoBlock block,
  PromoRenderStyle style,
) {
  switch (block.type) {
    case 'heading':
      return _heading(context, block, style);
    case 'paragraph':
      return _paragraph(block, style);
    case 'bullets':
      return _bullets(block, style);
    case 'badge':
      return _badge(block, style);
    case 'stat':
      // Static, operator-authored copy (e.g. "300 orders" describing a Studio
      // benefit) — NOT the shop's live usage. The "Starter never sees its usage"
      // guardrail is enforced author-side in the builder (H6); the renderer only
      // ever shows the text the campaign carries.
      return _stat(context, block, style);
    case 'image':
      return _image(context, block);
    case 'row':
    case 'columns':
      return _row(context, block, style);
    case 'column':
    case 'stack':
      // Vertical container: stacks its children top-to-bottom. Makes the split
      // layout row[ image, column[heading, bullets, button] ] work via the
      // existing recursion (the multi-block cell is a nested column).
      return _column(context, block, style);
    case 'button':
      return _button(context, block, style);
    case 'spacer':
      return SizedBox(height: block.number('height') ?? 12);
    case 'divider':
      return _divider(style);
    case 'background':
      // Card-level directive handled by PromoCard (it paints the background +
      // scrim); nothing to render inline.
      return const SizedBox.shrink();
    default:
      // Unknown block type — skip it, never break the card.
      return const SizedBox.shrink();
  }
}

Widget _heading(BuildContext context, PromoBlock block, PromoRenderStyle style) {
  final text = block.str('text');
  if (text == null) return const SizedBox.shrink();
  final tokens = context.appTokens;
  final align = block.str('align');
  return _aligned(align, Text(
    text,
    textAlign: _textAlignFor(align),
    style: TextStyle(
      fontFamily: tokens.fontDisplay,
      fontFamilyFallback: tokens.fontDisplayFallback,
      fontSize: block.number('size') ?? 20,
      fontWeight: FontWeight.w600,
      height: 1.15,
      color: _hexColor(block.str('color')) ?? style.primaryText,
    ),
  ));
}

Widget _paragraph(PromoBlock block, PromoRenderStyle style) {
  final text = block.str('text');
  if (text == null) return const SizedBox.shrink();
  final align = block.str('align');
  return _aligned(align, Text(
    text,
    textAlign: _textAlignFor(align),
    style: TextStyle(
      fontSize: block.number('size') ?? 13,
      height: 1.4,
      color: _hexColor(block.str('color')) ?? style.mutedText,
    ),
  ));
}

Widget _bullets(PromoBlock block, PromoRenderStyle style) {
  final items = block.strings('items');
  if (items.isEmpty) return const SizedBox.shrink();
  return _aligned(block.str('align'), Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: style.accent, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: style.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  ));
}

Widget _badge(PromoBlock block, PromoRenderStyle style) {
  final text = block.str('text');
  if (text == null) return const SizedBox.shrink();
  final color = _hexColor(block.str('color')) ?? style.accent;
  return _aligned(block.str('align'), Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      ),
    ),
  ));
}

Widget _stat(BuildContext context, PromoBlock block, PromoRenderStyle style) {
  final value = block.str('value');
  if (value == null) return const SizedBox.shrink();
  final label = block.str('label');
  final tokens = context.appTokens;
  final align = block.str('align');
  final color = _hexColor(block.str('color')) ?? style.accent;
  return _aligned(align, Column(
    crossAxisAlignment: _crossFor(align),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        textAlign: _textAlignFor(align),
        style: TextStyle(
          fontFamily: tokens.fontDisplay,
          fontFamilyFallback: tokens.fontDisplayFallback,
          fontSize: block.number('size') ?? 28,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: color,
        ),
      ),
      if (label != null) ...[
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: _textAlignFor(align),
          style: TextStyle(fontSize: 11, color: style.mutedText),
        ),
      ],
    ],
  ));
}

Widget _image(BuildContext context, PromoBlock block) {
  final url = block.str('url');
  if (url == null) return const SizedBox.shrink();
  final radius = context.appTokens.radiusMd;
  final height = block.number('height');
  final image = Image.network(
    url,
    fit: BoxFit.cover,
    width: double.infinity,
    height: height,
    // A broken image URL must never break the card — collapse it (fail-silent),
    // matching the app's other Image.network sites.
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: image,
  );
}

Widget _row(BuildContext context, PromoBlock block, PromoRenderStyle style) {
  final children = block.children();
  if (children.isEmpty) return const SizedBox.shrink();
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        _rowCell(context, children[i], style),
      ],
    ],
  );
}

/// One cell of a `row`/`columns`. Width control is a per-child prop: a fixed
/// `width` pins the cell to that many logical pixels (wrapped in a SizedBox); a
/// numeric `flex` sets its share of the remaining space (Expanded flex). With
/// neither prop the cell is an equal Expanded (flex 1), so existing row content
/// is unchanged.
Widget _rowCell(BuildContext context, PromoBlock child, PromoRenderStyle style) {
  final rendered = buildPromoBlock(context, child, style);
  final width = child.number('width');
  if (width != null) {
    return SizedBox(width: width, child: rendered);
  }
  final flex = (child.number('flex') ?? 1).round();
  return Expanded(flex: flex < 1 ? 1 : flex, child: rendered);
}

/// Vertical container (`column`/`stack`): renders [PromoBlock.children]
/// top-to-bottom, each via the recursion, with the card's 8px stacking gap
/// between them. `mainAxisSize.min` so a column nested inside a row cell sizes to
/// its content rather than trying to fill the row's height.
Widget _column(BuildContext context, PromoBlock block, PromoRenderStyle style) {
  final children = block.children();
  if (children.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        buildPromoBlock(context, children[i], style),
      ],
    ],
  );
}

Widget _button(BuildContext context, PromoBlock block, PromoRenderStyle style) {
  final label = block.str('label');
  if (label == null) return const SizedBox.shrink();
  final align = block.str('align');
  final fill = _hexColor(block.str('color')) ?? style.accent;
  return Align(
    alignment: _alignmentFor(align),
    child: Material(
      color: fill,
      borderRadius: BorderRadius.circular(context.appTokens.radiusMd),
      child: InkWell(
        onTap: () => style.onButtonTap(block),
        borderRadius: BorderRadius.circular(context.appTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: style.onAccent,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _divider(PromoRenderStyle style) {
  return Container(
    height: 1,
    color: style.primaryText.withValues(alpha: 0.12),
  );
}

// ── Per-block alignment + colour (H5 builder: Size/Align/Colour controls) ─────
// All default to the prior left/start behaviour, so a campaign without these
// props renders byte-for-byte as before (forward-compat, LOCKED decision 6): an
// older app simply ignores `align`/`color`.

/// Wrap a leaf block so it positions horizontally in the card column. Left/absent
/// returns the child untouched (identical to the pre-H5 layout); center/right
/// wrap in a full-width Align.
Widget _aligned(String? align, Widget child) {
  switch (align) {
    case 'center':
      return Align(alignment: Alignment.center, child: child);
    case 'right':
      return Align(alignment: Alignment.centerRight, child: child);
    default:
      return child; // left / null — unchanged
  }
}

Alignment _alignmentFor(String? align) {
  switch (align) {
    case 'center':
      return Alignment.center;
    case 'right':
      return Alignment.centerRight;
    default:
      return Alignment.centerLeft;
  }
}

TextAlign _textAlignFor(String? align) {
  switch (align) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

CrossAxisAlignment _crossFor(String? align) {
  switch (align) {
    case 'center':
      return CrossAxisAlignment.center;
    case 'right':
      return CrossAxisAlignment.end;
    default:
      return CrossAxisAlignment.start;
  }
}

/// Parse `#RRGGBB` / `#AARRGGBB` (or without the `#`) to a Color; null on anything
/// unparseable so a bad value falls back to the theme colour. Mirrors
/// promo_card.dart's `_parseHex`.
Color? _hexColor(String? raw) {
  if (raw == null) return null;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

/// The resolved colours + button handler a card threads through its block tree.
/// Built once by [PromoCard] from the theme + the campaign's accent, and flipped
/// to a light-on-dark palette when the card sits on a background image (scrim).
@immutable
class PromoRenderStyle {
  const PromoRenderStyle({
    required this.accent,
    required this.onAccent,
    required this.primaryText,
    required this.mutedText,
    required this.onButtonTap,
  });

  /// The campaign accent (its `card.accent`, or the theme primary).
  final Color accent;

  /// Readable foreground on top of [accent] (for filled buttons).
  final Color onAccent;

  /// Main text colour (dark-on-light normally; near-white over a scrim).
  final Color primaryText;

  /// Secondary text colour (muted / white70 over a scrim).
  final Color mutedText;

  /// Invoked when a `button` block is tapped — records the click + navigates.
  final void Function(PromoBlock block) onButtonTap;
}
