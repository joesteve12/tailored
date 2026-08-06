import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Design tokens that have no first-class Material 3 equivalent.
///
/// Anything that maps onto a `ColorScheme` role (primary, surface, error,
/// outline, the `surfaceContainer*` tiers, …) lives on the scheme instead —
/// see `AppTheme`. This extension is only the leftovers: extra surface/content
/// pairs, chart series, the sidebar sub-palette, the radius steps, and the
/// typography scale.
///
/// Read it from a widget the same way you'd read the color scheme:
/// ```dart
/// final tokens = context.appTokens;      // -> AppTokens
/// final scheme = Theme.of(context).colorScheme;
/// ```
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.popover,
    required this.popoverForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.ring,
    required this.inputBackground,
    required this.switchBackground,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.fontDisplay,
    required this.fontDisplayFallback,
    required this.fontSans,
    required this.fontSansFallback,
    required this.fontWeightNormal,
    required this.fontWeightMedium,
  });

  // Extra surface/content roles (no ColorScheme home).
  final Color popover;
  final Color popoverForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;

  /// Focus-ring color. Distinct from the scheme's `outline`.
  final Color ring;

  /// Fill painted behind text inputs. (The `input` token itself is a
  /// transparent border color and is intentionally not carried here.)
  final Color inputBackground;
  final Color switchBackground;

  // Data-viz series.
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;

  // Sidebar sub-palette (its own mini color system).
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  // Corner radii, in logical pixels.
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  // Typography. Primary family plus CSS-style fallbacks (feed the fallbacks
  // into `TextStyle.fontFamilyFallback`).
  final String fontDisplay;
  final List<String> fontDisplayFallback;
  final String fontSans;
  final List<String> fontSansFallback;
  final FontWeight fontWeightNormal;
  final FontWeight fontWeightMedium;

  /// Light-theme token values (from `tokens.json` → `light`).
  static const AppTokens light = AppTokens(
    popover: Color(0xFFE4D4B4),
    popoverForeground: Color(0xFF1E1611),
    muted: Color(0xFFD9C8A4),
    mutedForeground: Color(0xFF7D6E62),
    accent: Color(0xFFD9C8A4),
    accentForeground: Color(0xFF1E1611),
    ring: Color(0xFFB54A2A),
    inputBackground: Color(0xFFD9C8A4),
    switchBackground: Color(0xFFC4AE88),
    chart1: Color(0xFFB54A2A),
    chart2: Color(0xFFD4714E),
    chart3: Color(0xFFC49A72),
    chart4: Color(0xFF8A5C3A),
    chart5: Color(0xFFE8C49A),
    sidebar: Color(0xFFE4D4B4),
    sidebarForeground: Color(0xFF1E1611),
    sidebarPrimary: Color(0xFFB54A2A),
    sidebarPrimaryForeground: Color(0xFFEDE0C8),
    sidebarAccent: Color(0xFFD9C8A4),
    sidebarAccentForeground: Color(0xFF1E1611),
    // #1E16111F (RRGGBBAA) -> 0x1F1E1611 (AARRGGBB)
    sidebarBorder: Color(0x1F1E1611),
    sidebarRing: Color(0xFFB54A2A),
    radiusSm: 8,
    radiusMd: 10,
    radiusLg: 12,
    radiusXl: 16,
    fontDisplay: 'Fraunces',
    fontDisplayFallback: <String>['Georgia', 'serif'],
    fontSans: 'Inter',
    fontSansFallback: <String>['system-ui', 'sans-serif'],
    fontWeightNormal: FontWeight.w400,
    fontWeightMedium: FontWeight.w500,
  );

  /// Dark-theme token values (from `tokens.json` → `dark`).
  static const AppTokens dark = AppTokens(
    popover: Color(0xFF241C18),
    popoverForeground: Color(0xFFEDE5D8),
    muted: Color(0xFF2C2218),
    mutedForeground: Color(0xFF8A7A6E),
    accent: Color(0xFF2C2218),
    accentForeground: Color(0xFFEDE5D8),
    ring: Color(0xFFD4714E),
    inputBackground: Color(0xFF2C2218),
    switchBackground: Color(0xFF3C3028),
    chart1: Color(0xFFD4714E),
    chart2: Color(0xFFE8966A),
    chart3: Color(0xFFC49A72),
    chart4: Color(0xFFA06A48),
    chart5: Color(0xFFE8C49A),
    sidebar: Color(0xFF241C18),
    sidebarForeground: Color(0xFFEDE5D8),
    sidebarPrimary: Color(0xFFD4714E),
    sidebarPrimaryForeground: Color(0xFF1C0E08),
    sidebarAccent: Color(0xFF2C2218),
    sidebarAccentForeground: Color(0xFFEDE5D8),
    // #EDE5D81A (RRGGBBAA) -> 0x1AEDE5D8 (AARRGGBB)
    sidebarBorder: Color(0x1AEDE5D8),
    sidebarRing: Color(0xFFD4714E),
    radiusSm: 8,
    radiusMd: 10,
    radiusLg: 12,
    radiusXl: 16,
    fontDisplay: 'Fraunces',
    fontDisplayFallback: <String>['Georgia', 'serif'],
    fontSans: 'Inter',
    fontSansFallback: <String>['system-ui', 'sans-serif'],
    fontWeightNormal: FontWeight.w400,
    fontWeightMedium: FontWeight.w500,
  );

  @override
  AppTokens copyWith({
    Color? popover,
    Color? popoverForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? ring,
    Color? inputBackground,
    Color? switchBackground,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    String? fontDisplay,
    List<String>? fontDisplayFallback,
    String? fontSans,
    List<String>? fontSansFallback,
    FontWeight? fontWeightNormal,
    FontWeight? fontWeightMedium,
  }) {
    return AppTokens(
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      ring: ring ?? this.ring,
      inputBackground: inputBackground ?? this.inputBackground,
      switchBackground: switchBackground ?? this.switchBackground,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
      sidebarPrimaryForeground:
          sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarAccentForeground:
          sidebarAccentForeground ?? this.sidebarAccentForeground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarRing: sidebarRing ?? this.sidebarRing,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      fontDisplay: fontDisplay ?? this.fontDisplay,
      fontDisplayFallback: fontDisplayFallback ?? this.fontDisplayFallback,
      fontSans: fontSans ?? this.fontSans,
      fontSansFallback: fontSansFallback ?? this.fontSansFallback,
      fontWeightNormal: fontWeightNormal ?? this.fontWeightNormal,
      fontWeightMedium: fontWeightMedium ?? this.fontWeightMedium,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    // Discrete (non-interpolatable) tokens snap at the midpoint.
    final bool snapToOther = t >= 0.5;
    return AppTokens(
      popover: Color.lerp(popover, other.popover, t)!,
      popoverForeground:
          Color.lerp(popoverForeground, other.popoverForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      switchBackground:
          Color.lerp(switchBackground, other.switchBackground, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarForeground:
          Color.lerp(sidebarForeground, other.sidebarForeground, t)!,
      sidebarPrimary: Color.lerp(sidebarPrimary, other.sidebarPrimary, t)!,
      sidebarPrimaryForeground: Color.lerp(
        sidebarPrimaryForeground,
        other.sidebarPrimaryForeground,
        t,
      )!,
      sidebarAccent: Color.lerp(sidebarAccent, other.sidebarAccent, t)!,
      sidebarAccentForeground: Color.lerp(
        sidebarAccentForeground,
        other.sidebarAccentForeground,
        t,
      )!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarRing: Color.lerp(sidebarRing, other.sidebarRing, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      fontDisplay: snapToOther ? other.fontDisplay : fontDisplay,
      fontDisplayFallback:
          snapToOther ? other.fontDisplayFallback : fontDisplayFallback,
      fontSans: snapToOther ? other.fontSans : fontSans,
      fontSansFallback:
          snapToOther ? other.fontSansFallback : fontSansFallback,
      fontWeightNormal:
          FontWeight.lerp(fontWeightNormal, other.fontWeightNormal, t) ??
              fontWeightNormal,
      fontWeightMedium:
          FontWeight.lerp(fontWeightMedium, other.fontWeightMedium, t) ??
              fontWeightMedium,
    );
  }
}

/// Sugar so widgets reach tokens the same way they reach the color scheme:
/// `context.appTokens.accent` alongside `Theme.of(context).colorScheme.primary`.
extension AppTokensX on BuildContext {
  AppTokens get appTokens => Theme.of(this).extension<AppTokens>()!;
}

/// Semantic status / category colors that have no home in the design tokens
/// or on any Material `ColorScheme` role.
///
/// These were previously hardcoded (raw hex and Material named swatches) and
/// duplicated across the order/payment/activity widgets. They are pulled here
/// verbatim — the exact colors those widgets already rendered — so moving to
/// them is a pure refactor with zero visual change.
///
/// The fixed values are deliberately NOT theme-aware (unlike [AppTokens]): the
/// old code used the same hex in light and dark, so they are plain
/// `static const`s. If the design system later defines real light/dark status
/// tokens, promote this onto a `ThemeExtension` and wire it into `AppTheme`.
///
/// A few statuses (cancelled orders, high priority, refunds) map onto the
/// Material error role instead of a fixed value. They stay theme-aware — see
/// the resolver methods at the bottom — rather than freezing the error hex,
/// which differs between light and dark.
class StatusColors {
  StatusColors._();

  // --- Order status (see `_statusMeta`) ---
  static const Color orderPending = Color(0xFFB8860B); // gold
  static const Color orderInProgress = Color(0xFF2563EB); // blue
  static const Color orderOnHold = Color(0xFF7C3AED); // purple
  static const Color orderReady = Color(0xFF0D9488); // teal
  static const Color orderDelivered = Color(0xFF16A34A); // green

  // --- Payment status (see `_paymentMeta`) ---
  static const Color paymentPaid = Color(0xFF16A34A); // green
  static const Color paymentPartial = Color(0xFFB8860B); // gold

  // --- Priority / attention ---
  /// Rush ('urgent' priority) orders and overdue due dates.
  static const Color urgent = Color(0xFFEA580C); // orange

  // --- Activity timeline: payment entries ---
  static const Color paymentAccent = Color(0xFF388E3C); // Colors.green.shade700
  static const Color paymentDot = Color(0xFF009688); // Colors.teal
  static const Color paymentChipBg = Color(0xFFE8F5E9); // Colors.green.shade50

  // --- Activity timeline: tips ---
  static const Color tipAccent = Color(0xFFFF8F00); // Colors.amber.shade800
  static const Color tipChipBg = Color(0xFFFFF8E1); // Colors.amber.shade50
  static const Color tipChipText = Color(0xFFFF6F00); // Colors.amber.shade900

  // --- Activity timeline: task events ---
  static const Color taskDot = Color(0xFF3F51B5); // Colors.indigo
  static const Color taskChipBg = Color(0xFFE8EAF6); // Colors.indigo.shade50
  static const Color taskChipText = Color(0xFF283593); // Colors.indigo.shade800

  // --- Activity timeline: status-change events ---
  static const Color statusDot = Color(0xFF009688); // Colors.teal
  static const Color statusChipBg = Color(0xFFE3F2FD); // Colors.blue.shade50
  static const Color statusChipText = Color(0xFF1565C0); // Colors.blue.shade800

  // --- Statuses that ride the Material error role ---
  // Represented here for completeness, but resolved against the active scheme
  // so they stay theme-aware (error is #9C2216 in light, #C43020 in dark).

  /// Cancelled orders.
  static Color cancelled(ColorScheme scheme) => scheme.error;

  /// 'high' priority orders (distinct from [urgent], which is 'urgent').
  static Color priorityHigh(ColorScheme scheme) => scheme.error;

  /// Refund activity entries. The paired chip uses the standard
  /// `errorContainer` / `onErrorContainer` roles directly.
  static Color refund(ColorScheme scheme) => scheme.error;
}
