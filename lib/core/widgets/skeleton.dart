import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Skeleton loading primitives — the app-wide placeholder system.
///
/// Two pieces that compose:
///
/// * [Skeleton] (and [SkeletonCircle]) — a dumb, opaque block painted in the
///   theme's muted "absent content" tone. On its own it renders as a static
///   grey shape, which is a perfectly good (if still) fallback.
/// * [Shimmer] — wraps a group of skeletons and sweeps a light band across all
///   of them with a SINGLE animation controller. This is the efficient model:
///   one shader masks the whole subtree, rather than one controller per box.
///
/// Usage: build a placeholder that mirrors the real layout's shape (same
/// sizes, so nothing shifts when data lands), then wrap the group once:
///
/// ```dart
/// Shimmer(
///   child: Column(children: const [
///     Skeleton(width: 120, height: 20),
///     SizedBox(height: 8),
///     Skeleton(height: 12),
///   ]),
/// )
/// ```
///
/// Colours come from [AppTokens]/`ColorScheme`, so it's correct in light and
/// dark automatically. On surfaces that aren't the page background (e.g. the
/// dark revenue card), pass explicit `baseColor`/`highlightColor`.

/// The resting fill of a skeleton — a muted wash that reads as "content that
/// hasn't arrived" against the page background in either theme.
Color skeletonBaseColor(BuildContext context) => context.appTokens.muted;

/// The brighter band the [Shimmer] sweeps across. Always lighter than the base
/// in both themes (a light sweep), by nudging the muted tone toward white.
Color skeletonHighlightColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Color.lerp(
    skeletonBaseColor(context),
    Colors.white,
    isDark ? 0.12 : 0.55,
  )!;
}

/// A rounded rectangular placeholder block. Defaults to a text-line height and
/// the small radius; pass a [width] to size a line (null = fill the cross
/// axis), or set [radius] for larger shapes.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 12,
    this.radius,
    this.color,
  });

  final double? width;
  final double height;
  final double? radius;

  /// Overrides the resting fill — for skeletons on a non-default surface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? skeletonBaseColor(context),
        borderRadius: BorderRadius.circular(radius ?? context.appTokens.radiusSm),
      ),
    );
  }
}

/// A circular placeholder — dots, avatars, icon slots.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.diameter, this.color});

  final double diameter;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color ?? skeletonBaseColor(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Sweeps a light band across everything painted in [child]. Drive one per
/// loading region and put all that region's [Skeleton]s inside it.
///
/// Falls back to the plain (static) child when [enabled] is false or the
/// platform requests reduced motion — the boxes still show their resting fill,
/// so the layout is held either way.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1300),
  });

  final Widget child;
  final bool enabled;

  /// Override the token-derived colours — needed when the skeletons sit on a
  /// surface other than the page background.
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Shimmer old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.enabled || reduceMotion) return widget.child;

    final base = widget.baseColor ?? skeletonBaseColor(context);
    final highlight = widget.highlightColor ?? skeletonHighlightColor(context);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Slide the band from just off the left edge to just off the right.
        final slide = _controller.value * 2 - 1;
        final gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlidingGradientTransform(slide),
        );
        return ShaderMask(
          // srcATop replaces the child's pixels with the gradient only where
          // the child is opaque — so the skeleton boxes define the shape and
          // the gradient supplies base + moving highlight.
          blendMode: BlendMode.srcATop,
          shaderCallback: gradient.createShader,
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slide);

  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// A ready-made placeholder for one list row: an optional leading circle
/// (avatar/thumbnail), a stack of text lines (first line long, the rest short),
/// and an optional trailing block. Tune it to match a screen's real row, or
/// pass a custom `itemBuilder` to [SkeletonList] for anything more bespoke.
///
/// Line widths are proportional (via `widthFactor`), so a tile reads right at
/// any width without magic pixel numbers.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({
    super.key,
    this.hasLeading = true,
    this.leadingDiameter = 40,
    this.lineCount = 2,
    this.hasTrailing = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final bool hasLeading;
  final double leadingDiameter;
  final int lineCount;
  final bool hasTrailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonCircle(diameter: leadingDiameter),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < lineCount; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    // First line long; later lines short (the last shortest).
                    widthFactor: i == 0
                        ? 0.9
                        : (i == lineCount - 1 ? 0.5 : 0.68),
                    child: Skeleton(height: i == 0 ? 14 : 11),
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 12),
            const Skeleton(width: 44, height: 20),
          ],
        ],
      ),
    );
  }
}

/// A whole list of skeleton rows, swept by ONE shimmer — the drop-in loading
/// state for list-heavy screens.
///
/// Defaults to a column of [SkeletonTile]s (non-scrolling), which composes
/// inside anything: a `Column`, a `CustomScrollView` sliver via
/// `SliverToBoxAdapter`, or an `AsyncValue.when(loading: …)` body. Set
/// [scrollable] to make it a real scroll view instead — the drop-in for a
/// screen whose body would otherwise be a `ListView`.
///
/// Pass a custom [itemBuilder] to mirror a specific row; otherwise every row is
/// a default [SkeletonTile]. Keep [itemCount] roughly a screenful.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemBuilder,
    this.itemCount = 6,
    this.separatorHeight = 0,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
    this.enabled = true,
  });

  /// Builds a single row. Defaults to `(_ , _) => const SkeletonTile()`.
  final IndexedWidgetBuilder? itemBuilder;
  final int itemCount;

  /// Gap between rows. Use it to match a real list's separators/spacing.
  final double separatorHeight;
  final EdgeInsetsGeometry padding;

  /// When true, renders a scrolling `ListView` (needs bounded height from its
  /// parent, e.g. a Scaffold body). When false (default), a plain `Column`.
  final bool scrollable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final builder =
        itemBuilder ?? (BuildContext _, int __) => const SkeletonTile();

    final Widget content;
    if (scrollable) {
      content = ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
        itemBuilder: builder,
      );
    } else {
      content = Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              if (i > 0) SizedBox(height: separatorHeight),
              builder(context, i),
            ],
          ],
        ),
      );
    }

    return Shimmer(enabled: enabled, child: content);
  }
}
