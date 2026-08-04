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
      // card -> the tier Flutter's M3 Card reads by default.
      surfaceContainerLow: const Color(0xFFE4D4B4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.light],
      navigationBarTheme: _navigationBarTheme(AppTokens.light),
      navigationRailTheme: _navigationRailTheme(AppTokens.light),
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
      // card -> the tier Flutter's M3 Card reads by default.
      surfaceContainerLow: const Color(0xFF241C18),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.dark],
      navigationBarTheme: _navigationBarTheme(AppTokens.dark),
      navigationRailTheme: _navigationRailTheme(AppTokens.dark),
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
