
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

export 'app_colors.dart';
export 'app_tokens.dart';
export 'mg_colors.dart';

class AppTheme {
  // Alias de compatibilidad: neonGreen ahora apunta al violeta oficial #7C5CFF
  static const Color neonGreen = MgColors.acc;
  static const Color darkBg = MgColors.bg;
  static const Color cardBg = MgColors.card;
  static const Color lightBg = Color(0xFFF4F3F7);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        bg: MgColors.bg,
        surface: MgColors.card,
        ink: MgColors.ink,
        muted: MgColors.ink2,
        line: MgColors.line,
        error: MgColors.down,
        colors: AppColors.dark,
      );

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        bg: lightBg,
        surface: lightSurface,
        ink: const Color(0xFF16141B),
        muted: const Color(0xFF5B5866),
        line: const Color(0xFFE1DFE6),
        error: const Color(0xFFC23434),
        colors: AppColors.light,
      );

  static TextTheme _textTheme(Color ink, Color muted) {
    TextStyle f(
      double size,
      FontWeight w, {
      double? letterSpacing,
      Color? color,
      double height = 1.35,
      List<FontFeature>? fontFeatures,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          letterSpacing: letterSpacing,
          color: color ?? ink,
          height: height,
          fontFeatures: fontFeatures,
        );

    return TextTheme(
      displayLarge: f(42, FontWeight.w800, letterSpacing: -1.26, fontFeatures: AppText.tabular),
      displayMedium: f(33, FontWeight.w800, letterSpacing: -0.99, fontFeatures: AppText.tabular),
      headlineLarge: f(28, FontWeight.w800, letterSpacing: -0.84),
      headlineMedium: f(24, FontWeight.w700, letterSpacing: -0.48), // títulos de pantalla
      headlineSmall: f(20, FontWeight.w700, letterSpacing: -0.3),
      titleLarge: f(17, FontWeight.w700),
      titleMedium: f(15, FontWeight.w600),
      titleSmall: f(14, FontWeight.w600),
      bodyLarge: f(15, FontWeight.w400),
      bodyMedium: f(14, FontWeight.w400),
      bodySmall: f(13, FontWeight.w400, color: muted),
      labelLarge: f(13, FontWeight.w600),
      labelMedium: f(11.5, FontWeight.w500, color: muted),
      labelSmall: f(11, FontWeight.w500, color: muted),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
    required Color error,
    required AppColors colors,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: MgColors.acc,
      onPrimary: Colors.white,
      secondary: MgColors.up,
      onSecondary: Colors.black,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
      surfaceContainerHighest: brightness == Brightness.dark ? MgColors.soft : const Color(0xFFF0EFF4),
    );
    final text = _textTheme(ink, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: line,
      textTheme: text,
      extensions: [colors],
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: brightness == Brightness.dark ? MgColors.borderTenue : line,
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? MgColors.acc
                : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            color: selected ? MgColors.acc : muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MgColors.acc,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.primaryButton),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(AppSizes.primaryButton),
          side: BorderSide(color: line, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MgColors.acc,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? MgColors.soft : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: MgColors.acc, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: error, width: 1),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
        labelStyle: text.bodyMedium?.copyWith(color: muted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MgColors.acc;
          }
          return brightness == Brightness.dark ? MgColors.soft : line;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
