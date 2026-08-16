import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// App-wide light/dark themes, built from the design tokens in `tokens.json`.
///
/// Strategy: seed a full Material 3 `ColorScheme` from our brand `primary`
/// (so the roles we don't care to pin — inverse roles, scrims, etc. — still
/// get a sensible, harmonized value), then `copyWith` our exact token values on
/// top of the roles we *do* own. That now includes the *container* and
/// *tertiary* roles: the shadcn palette has no container concept, so left to
/// the seed they render a cool salmon/indigo cast that bleeds through every
/// soft-brand surface against the warm cream palette — so we pin them to warm
/// palette values too (see the copyWith blocks below).
///
/// Tokens without a Material role (popover, muted, accent, ring, charts,
/// sidebar palette, radii, typography) live on the [AppTokens] theme
/// extension instead — read them via `context.appTokens`.
///
/// Rule for everything built after this file: never reach for a raw
/// Color/hex value in a widget. Always go through Theme.of(context) or
/// `context.appTokens`, so future palette changes stay contained here.
class AppTheme {
  AppTheme._();

  // Brand primary — also the seed for both schemes.
  static const Color _primaryLight = Color(0xFFB54A2A);
  static const Color _primaryDark = Color(0xFFD4714E);

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primaryLight,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primaryLight,
      onPrimary: const Color(0xFFEDE0C8), // primaryForeground
      secondary: const Color(0xFFD9C8A4),
      onSecondary: const Color(0xFF1E1611), // secondaryForeground
      surface: const Color(0xFFEDE0C8), // background
      onSurface: const Color(0xFF1E1611), // foreground (== cardForeground)
      error: const Color(0xFF9C2216), // destructive
      onError: const Color(0xFFEDE0C8), // destructiveForeground
      outline: const Color(0x1F1E1611), // border (#1E16111F -> AARRGGBB)
      // The *container* and *tertiary* roles. Our shadcn-derived palette has no
      // "container" concept, so left unset these fall back to the cool fromSeed
      // tones — a salmon/indigo cast that bleeds through every soft-brand
      // surface (FABs, avatars, the "On Time" task pill, empty-state icons,
      // toasts) against the warm cream palette. Same problem the surface ramp
      // above already had; pin them to warm palette values so nothing leaks.
      // primaryContainer is a soft clay tint of `primary`; secondary/tertiary
      // ride their base tokens (secondary tan, chart brass) so a "container"
      // simply collapses onto the shadcn colour it was always meant to be.
      primaryContainer: const Color(0xFFE8C4B0),
      onPrimaryContainer: const Color(0xFF5C2416),
      secondaryContainer: const Color(0xFFD9C8A4), // == secondary (tan)
      onSecondaryContainer: const Color(0xFF1E1611),
      tertiary: const Color(0xFFC49A72), // chart3 (brass accent)
      onTertiary: const Color(0xFF1E1611),
      tertiaryContainer: const Color(0xFFE8C49A), // chart5 (soft brass)
      onTertiaryContainer: const Color(0xFF4A3418),
      // errorContainer is derived from the *seed*, not our `error` override, so
      // it lands as a cool pink that bleeds through the "Delayed" task pill,
      // error toasts and delete badges. Pin it to a soft warm red keyed off the
      // `destructive` hue, with `destructive` itself as the on-colour.
      errorContainer: const Color(0xFFF5D9D3),
      onErrorContainer: const Color(0xFF9C2216), // == destructive
      // Kill M3's elevation overlay everywhere. The seed tint reads cool
      // (a muddy indigo-ish cast) against this warm cream palette, so every
      // elevated Material surface — the AppBar on scroll, menus, dialogs —
      // gets it turned off. Depth comes from real shadows, not tint.
      surfaceTint: Colors.transparent,
      // The warm tan surface ramp. Only `surfaceContainerLow` was overridden
      // before, so the higher tiers fell back to the cool fromSeed neutrals —
      // which is what made the payment card (surfaceContainerHigh) look indigo.
      // Ordered lightest -> darkest so elevated surfaces read as warmer paper.
      surfaceContainerLowest: const Color(0xFFEDE0C8),
      surfaceContainerLow: const Color(0xFFE4D4B4), // card default tier
      surfaceContainer: const Color(0xFFDFCEAC),
      surfaceContainerHigh: const Color(0xFFD9C8A4),
      surfaceContainerHighest: const Color(0xFFCFBB92),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Inter is the sans body face; Fraunces (the display voice) is opted
      // into per-widget via AppTokens.fontDisplay.
      fontFamily: AppTokens.light.fontSans,
      fontFamilyFallback: AppTokens.light.fontSansFallback,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.light],
      appBarTheme: _appBarTheme(scheme),
      floatingActionButtonTheme: _fabTheme(scheme),
      navigationBarTheme: _navigationBarTheme(AppTokens.light),
      navigationRailTheme: _navigationRailTheme(AppTokens.light),
      inputDecorationTheme: _inputDecorationTheme(AppTokens.light, scheme),
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _primaryDark,
      onPrimary: const Color(0xFF1C0E08), // primaryForeground
      secondary: const Color(0xFF2C2218),
      onSecondary: const Color(0xFFEDE5D8), // secondaryForeground
      surface: const Color(0xFF1C1512), // background
      onSurface: const Color(0xFFEDE5D8), // foreground (== cardForeground)
      error: const Color(0xFFC43020), // destructive
      onError: const Color(0xFFFBF5ED), // destructiveForeground
      outline: const Color(0x1AEDE5D8), // border (#EDE5D81A -> AARRGGBB)
      // Container/tertiary roles — see the light scheme for the why. Dark
      // already read acceptably from the seed, but pin it too so both modes are
      // deterministic and warm rather than one being seed-derived.
      primaryContainer: const Color(0xFF4A2618), // dark clay tint of `primary`
      onPrimaryContainer: const Color(0xFFF5C9B4),
      secondaryContainer: const Color(0xFF2C2218), // == secondary
      onSecondaryContainer: const Color(0xFFEDE5D8),
      tertiary: const Color(0xFFC49A72), // chart3 (brass accent)
      onTertiary: const Color(0xFF1C0E08),
      tertiaryContainer: const Color(0xFF4A3420), // soft brass, dark
      onTertiaryContainer: const Color(0xFFE8C49A),
      // See light: keep the error container a warm red rather than the seed's
      // cool pink.
      errorContainer: const Color(0xFF4A1A14),
      onErrorContainer: const Color(0xFFF2C7BF),
      // See the light scheme: turn off the cool M3 elevation overlay and give
      // the surface-container ramp warm values so elevated surfaces (the
      // AppBar on scroll, the payment card) don't pick up an indigo cast.
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: const Color(0xFF181210),
      surfaceContainerLow: const Color(0xFF241C18), // card default tier
      surfaceContainer: const Color(0xFF282019),
      surfaceContainerHigh: const Color(0xFF2C2218),
      surfaceContainerHighest: const Color(0xFF3C3028),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTokens.dark.fontSans,
      fontFamilyFallback: AppTokens.dark.fontSansFallback,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.dark],
      appBarTheme: _appBarTheme(scheme),
      floatingActionButtonTheme: _fabTheme(scheme),
      navigationBarTheme: _navigationBarTheme(AppTokens.dark),
      navigationRailTheme: _navigationRailTheme(AppTokens.dark),
      inputDecorationTheme: _inputDecorationTheme(AppTokens.dark, scheme),
    );
  }

  // The AppBar sits on the warm `surface`, flat. `surfaceTintColor:
  // transparent` and `scrolledUnderElevation: 0` stop M3 from blending its
  // elevation overlay in when content scrolls under it — that overlay is what
  // gave the bar a cool indigo-ish cast against the warm palette.
  static AppBarTheme _appBarTheme(ColorScheme scheme) {
    return AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
    );
  }

  // FABs default to `primaryContainer` in M3, which is the cool seed tint that
  // bleeds against this palette. Give them the solid brand `primary` (with the
  // cream `onPrimary`) instead — the same terracotta fill the primary buttons
  // and the swipe-to-complete action already use.
  static FloatingActionButtonThemeData _fabTheme(ColorScheme scheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    );
  }

  // The nav shell (bottom bar below md, rail at md+) is styled from the
  // `sidebar*` token family rather than the seed-derived surface tiers, so it
  // reads as the design's warm tan chrome instead of M3's tinted
  // `surfaceContainer`. Selected items use `sidebarPrimary` (terracotta) on a
  // subtle `sidebarAccent` indicator; the bar itself is `sidebar`.
  static NavigationBarThemeData _navigationBarTheme(AppTokens t) {
    return NavigationBarThemeData(
      backgroundColor: t.sidebar,
      indicatorColor: t.sidebarAccent,
      // Kill the elevation tint so the bar stays flat tan, not pink.
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? t.sidebarPrimary : t.sidebarForeground,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? t.fontWeightMedium : t.fontWeightNormal,
          color: selected ? t.sidebarPrimary : t.sidebarForeground,
        );
      }),
    );
  }

  // Text fields: filled with the `inputBackground` token, a subtle `outline`
  // (the alpha-correct `border` token) at rest, the `ring` token on focus, and
  // the scheme's `error` (your `destructive`) on error. Corners use `radiusMd`.
  static InputDecorationTheme _inputDecorationTheme(
    AppTokens t,
    ColorScheme scheme,
  ) {
    final BorderRadius radius = BorderRadius.circular(t.radiusMd);
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: t.inputBackground,
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(t.ring, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      disabledBorder: border(scheme.outline),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(AppTokens t) {
    return NavigationRailThemeData(
      backgroundColor: t.sidebar,
      indicatorColor: t.sidebarAccent,
      selectedIconTheme: IconThemeData(color: t.sidebarPrimary),
      unselectedIconTheme: IconThemeData(color: t.sidebarForeground),
      selectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: t.fontWeightMedium,
        color: t.sidebarPrimary,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: t.fontWeightNormal,
        color: t.sidebarForeground,
      ),
    );
  }
}
