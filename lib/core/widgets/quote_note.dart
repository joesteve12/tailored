import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A free-text note rendered as a pull-quote — a large serif quotation mark in
/// the brand primary, with the note itself set in the app's usual sans (Inter)
/// beside and below it. The serif glyph does the "quote" work while the body
/// stays consistent with the rest of the app's copy; reads as "the app is
/// quoting someone" rather than a plain field.
///
/// Reusable across every place a human-authored note appears (orders, clients,
/// tasks …). It renders only the quote itself — no "Notes" heading and no outer
/// spacing — so callers control the surrounding layout and decide whether to
/// label it. Guard on emptiness at the call site; this always paints.
///
/// The quotation glyph is positioned in a left gutter (out of flow) so long
/// notes wrap cleanly under it. Colours and the serif face come from the theme
/// ([AppTokens.fontDisplay] / [ColorScheme]) so it tracks light/dark and any
/// palette change.
class QuoteNote extends StatelessWidget {
  const QuoteNote({super.key, required this.text});

  /// The note to quote. Assumed non-empty — callers skip rendering otherwise.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The oversized opening quote mark, anchored top-left in the gutter the
        // text indents past. Not italic — it's the glyph doing the "quote"
        // work, so the body stays upright and legible.
        Positioned(
          left: 0,
          top: 0,
          child: Text(
            '“',
            style: TextStyle(
              fontFamily: tokens.fontDisplay,
              fontFamilyFallback: tokens.fontDisplayFallback,
              fontSize: 58,
              height: 1,
              color: scheme.primary,
            ),
          ),
        ),
        Padding(
          // Clears the quote mark: pushed right of the glyph and down past its
          // cap so the first line sits alongside its lower half.
          padding: const EdgeInsets.only(left: 34, top: 18),
          child: Text(
            // Body stays in the sans (Inter) voice — only the quote glyph is
            // the serif accent — but set in italic so it reads as quoted
            // speech, consistent with the rest of the app's copy.
            text,
            style: TextStyle(
              fontFamily: tokens.fontSans,
              fontFamilyFallback: tokens.fontSansFallback,
              fontSize: 15.5,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
