import 'package:flutter/material.dart';

ThemeData buildPithTheme() {
  const background = Color(0xFF0A0C12);
  const surface = Color(0xFF161B22);
  const cardSurface = Color(0xFF1E293B);
  const gold = Color(0xFFF4C025);
  const cream = Color(0xFFF4EBD0);
  const muted = Color(0xFF9AA8C0);

  const scheme = ColorScheme.dark(
    primary: gold,
    secondary: cream,
    surface: surface,
    onPrimary: Color(0xFF111111),
    onSecondary: background,
    onSurface: cream,
    error: Color(0xFFF06A6A),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: Typography.whiteMountainView.apply(
      bodyColor: cream,
      displayColor: cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardSurface.withValues(alpha: 0.8),
      hintStyle: const TextStyle(color: muted),
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