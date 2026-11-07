import 'package:flutter/material.dart';

/// Look: a card table. Deep felt green, cards that read like playing cards,
/// one brass accent for the action you are about to take.
///
/// Tokens (also used by the suit pips and score cards):
///  felt     #0C2E22 / #165039   table and raised felt
///  card     #F7FAF7             card face (light theme)
///  ink      #14231B             text on light surfaces and on brass
///  brass    #E2B04A             primary action, selected chips, winner
///  suitRed  #C94A3E             hearts, diamonds, mistakes
class AppTheme {
  static const ink = Color(0xFF14231B);
  static const brass = Color(0xFFE2B04A);
  static const suitRed = Color(0xFFC94A3E);

  /// Condensed bold for score numerals and titles (bundled, Apache 2.0).
  static const numeralFont = 'RobotoCondensed';

  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  /// True black background: saves battery on OLED and is easy on the eyes
  /// in a dark room.
  static ThemeData oled() => _build(_oledScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD9A02F),
    onPrimary: ink,
    primaryContainer: Color(0xFFD6EBDD),
    onPrimaryContainer: Color(0xFF0E3B2B),
    secondary: Color(0xFF1F6B45),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFCDE5D5),
    onSecondaryContainer: Color(0xFF0E3B2B),
    tertiary: Color(0xFF8A6A12),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF6E3B0),
    onTertiaryContainer: Color(0xFF3E2F06),
    error: Color(0xFFB3382C),
    onError: Colors.white,
    surface: Color(0xFFEAF1EB),
    onSurface: ink,
    onSurfaceVariant: Color(0xFF4A6356),
    outline: Color(0xFF7C9A8A),
    outlineVariant: Color(0xFFCADACF),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF7FAF7),
    surfaceContainer: Color(0xFFF7FAF7),
    surfaceContainerHigh: Color(0xFFE0EAE2),
    surfaceContainerHighest: Color(0xFFD6E3DA),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: brass,
    onPrimary: ink,
    primaryContainer: Color(0xFF1E5A41),
    onPrimaryContainer: Color(0xFFE6F2EA),
    secondary: Color(0xFF7FC4A0),
    onSecondary: ink,
    secondaryContainer: Color(0xFF1A4A36),
    onSecondaryContainer: Color(0xFFD4EBDD),
    tertiary: brass,
    onTertiary: ink,
    tertiaryContainer: Color(0xFF5A4515),
    onTertiaryContainer: Color(0xFFFFE9B3),
    error: Color(0xFFFF8A7A),
    onError: ink,
    surface: Color(0xFF0C2E22),
    onSurface: Color(0xFFE6EFE9),
    onSurfaceVariant: Color(0xFFA9C4B5),
    outline: Color(0xFF5E8A74),
    outlineVariant: Color(0xFF2C5A45),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Color(0xFF082219),
    surfaceContainerLow: Color(0xFF103325),
    surfaceContainer: Color(0xFF133829),
    surfaceContainerHigh: Color(0xFF174032),
    surfaceContainerHighest: Color(0xFF1B4636),
  );

  static final _oledScheme = _darkScheme.copyWith(
    surface: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: const Color(0xFF0B120E),
    surfaceContainer: const Color(0xFF0F1914),
    surfaceContainerHigh: const Color(0xFF15221B),
    surfaceContainerHighest: const Color(0xFF1B2B22),
    outlineVariant: const Color(0xFF24382E),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;
    TextStyle numerals(TextStyle? s, {double? size}) => (s ?? const TextStyle()).copyWith(
          fontFamily: numeralFont,
          fontWeight: FontWeight.w700,
          fontSize: size,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final text = base
        .copyWith(
          displaySmall: numerals(base.displaySmall, size: 44),
          headlineMedium: numerals(base.headlineMedium, size: 32),
          headlineSmall: numerals(base.headlineSmall, size: 26),
          titleLarge: numerals(base.titleLarge, size: 24),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final stadium = const StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: numerals(null, size: 28).copyWith(color: scheme.onSurface),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? ink : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            )),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 60),
          shape: stadium,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 60),
          shape: stadium,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: stadium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? ink : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHigh),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : scheme.outline),
      ),
      chipTheme: ChipThemeData(
        shape: stadium,
        side: BorderSide(color: scheme.outline),
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: ink,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        labelStyle: TextStyle(fontSize: 16, color: scheme.onSurface),
        secondaryLabelStyle: const TextStyle(fontSize: 16, color: ink, fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
