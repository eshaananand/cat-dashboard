import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  const seed = Color(0xFF00796B);
  final dark = brightness == Brightness.dark;
  final colorScheme =
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
        primary: seed,
        secondary: const Color(0xFFE05D44),
        tertiary: const Color(0xFFF2B84B),
        surface: dark ? const Color(0xFF15201E) : Colors.white,
        surfaceContainerHighest: dark
            ? const Color(0xFF253331)
            : const Color(0xFFF3F6F5),
      );

  final baseTextTheme =
      const TextTheme(
        displaySmall: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45, letterSpacing: 0),
        bodyMedium: TextStyle(fontSize: 13, height: 1.35, letterSpacing: 0),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0,
        ),
      ).apply(
        bodyColor: dark ? const Color(0xFFE5EEEA) : const Color(0xFF14332F),
        displayColor: dark ? const Color(0xFFE5EEEA) : const Color(0xFF14332F),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0D1413)
        : const Color(0xFFF5F7F7),
    dividerColor: dark ? const Color(0xFF2A3A37) : const Color(0xFFE1E7E5),
    textTheme: baseTextTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: dark ? const Color(0xFF0D1413) : const Color(0xFFF5F7F7),
      foregroundColor: dark ? const Color(0xFFE5EEEA) : const Color(0xFF14332F),
      titleTextStyle: TextStyle(
        color: dark ? const Color(0xFFE5EEEA) : const Color(0xFF14332F),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
  );
}
