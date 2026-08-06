import 'package:flutter/material.dart';

/// A small uppercase, letter-spaced caption used to head a group of fields on
/// the form screens — the "OUTFIT ITEMS" / "DUE DATE" / "PRIORITY" style label
/// from the design. Kept in one place so every form heads its sections with
/// the exact same weight, tracking, and colour rather than each screen
/// re-deriving the recipe (which is how the labels drift apart).
///
/// The style mirrors the one already used on the order list / payment cards:
/// `labelSmall`, `w700`, ~1.4 letter-spacing, on the muted `onSurfaceVariant`
/// role so it recedes behind the field values it introduces.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.trailing,
  });

  final String text;

  /// Optional widget pinned to the trailing edge on the same baseline — a
  /// count ("2/3"), a small action, an inline spinner. Omitted, the label is
  /// just the text.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
    );
    if (trailing == null) return label;
    return Row(
      children: [
        label,
        const Spacer(),
        trailing!,
      ],
    );
  }
}
