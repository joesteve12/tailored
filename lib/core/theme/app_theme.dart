import 'package:flutter/material.dart';

/// Placeholder color tokens — deliberately not styled to match anything
/// yet. Swap `seedColor` (or break this out into a fully custom
/// ColorScheme) once the Dribbble reference shows up.
///
/// Rule for everything built after this file: never reach for a raw
/// Color/hex value in a widget. Always go through Theme.of(context) or
/// these ThemeData objects, so the eventual real-palette swap stays
/// contained to this one file instead of becoming a find-and-replace
/// across the whole app.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      );
}
