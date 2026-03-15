import 'package:flutter/material.dart';

import 'pith_colors.dart';

ThemeData buildPithTheme() {
  const scheme = ColorScheme.dark(
    primary: PithColors.gold,
    secondary: PithColors.cream,
    surface: PithColors.surface,
    onPrimary: Color(0xFF111111),
    onSecondary: PithColors.background,
    onSurface: PithColors.cream,
    error: PithColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PithColors.background,
    textTheme: Typography.whiteMountainView.apply(
      bodyColor: PithColors.cream,
      displayColor: PithColors.cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PithColors.cardSurface.withValues(alpha: 0.8),
      hintStyle: const TextStyle(color: PithColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    ),
  );
}