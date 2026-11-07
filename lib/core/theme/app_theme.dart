import 'package:flutter/material.dart';

/// Green felt table look, large tap targets.
class AppTheme {
  static const _felt = Color(0xFF1F6B45);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// True black background: saves battery on OLED and is easy on the eyes
  /// in a dark room.
  static ThemeData oled() => _build(Brightness.dark, oled: true);

  static ThemeData _build(Brightness brightness, {bool oled = false}) {
    final dark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: _felt,
      brightness: brightness,
      surface: dark ? const Color(0xFF0F1A14) : null,
    );
    if (oled) scheme = scheme.copyWith(surface: Colors.black);
    final appBarColor = oled
        ? Colors.black
        : dark
            ? const Color(0xFF14261C)
            : _felt;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: oled ? Colors.black : null,
      ),
      cardTheme: oled
          ? const CardThemeData(color: Color(0xFF121212))
          : const CardThemeData(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 60),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        labelStyle: TextStyle(fontSize: 16),
      ),
    );
  }
}
