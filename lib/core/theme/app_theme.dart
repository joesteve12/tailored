import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// App-wide light/dark themes, built from the design tokens in `tokens.json`.
///
/// Strategy: seed a full Material 3 `ColorScheme` from our brand `primary`
/// (so every role we *don't* define — tertiary, the container tiers, the
/// inverse roles, scrims, etc. — still gets a sensible, harmonized value),
/// then `copyWith` our exact token values on top of the roles we *do* own.
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
