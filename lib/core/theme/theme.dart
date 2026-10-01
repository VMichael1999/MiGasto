import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  // Brand colors
  // Alias del modo oscuro; en pantallas nuevas usa context.appColors.
  static const Color yapePurple = Color(0xFF9B4FD6);
  static const Color plinTeal = Color(0xFF10BFAF);
  static const Color googlePayBlue = Color(0xFF5B9BF8);
  static const Color manualGray = Color(0xFF8A8794);

  // App Theme Accent Colors
  static const Color neonGreen = Color(0xFF8CE885);
  static const Color darkBg = Color(0xFF0F0E13);
  static const Color cardBg = Color(0xFF1B1922);

  // Modo claro
  static const Color lightBg = Color(0xFFF4F3F6);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static Color getSourceColor(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'yape':
        return yapePurple;
      case 'plin':
        return plinTeal;
      case 'googlepay':
      case 'google_pay':
        return googlePayBlue;
      default:
        return manualGray;
    }
  }

  static String getCategoryEmoji(dynamic category) {
    final catName = category.toString().split('.').last;
    switch (catName) {
      case 'alimentacion':
        return '🍔';
      case 'transporte':
        return '🚗';
      case 'compras':
        return '🛍️';
      case 'servicios':
        return '💡';
      case 'entretenimiento':
        return '🍿';
      default:
        return '📦';
    }
  }

  static String getCategoryNameEs(dynamic category) {
    final catName = category.toString().split('.').last;
    switch (catName) {
      case 'alimentacion':
        return 'Alimentación';
      case 'transporte':
        return 'Transporte';
      case 'compras':
        return 'Compras';
      case 'servicios':
        return 'Servicios';
      case 'entretenimiento':
        return 'Entretenimiento';
      default:
        return 'Otros';
    }
  }

  static Color getCategoryColor(dynamic category) {
    final catName = category.toString().split('.').last;
    switch (catName) {
      case 'alimentacion':
        return const Color(0xFFBC85E8); // Purple-lavender
      case 'transporte':
        return const Color(0xFF45A5F5); // Light blue
      case 'compras':
        return const Color(0xFFFFB74D); // Orange
      case 'servicios':
        return const Color(0xFF4DB6AC); // Teal
      case 'entretenimiento':
        return const Color(0xFFF06292); // Pink
      default:
        return Colors.grey;
    }
  }

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        bg: darkBg,
        surface: cardBg,
        ink: const Color(0xFFF2F0F5),
        muted: const Color(0xFFA5A1B0),
        line: const Color(0xFF2A2733),
        error: const Color(0xFFF07070),
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
    TextStyle o(double size, FontWeight w, {double spacing = 0, Color? color}) =>
        GoogleFonts.outfit(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          color: color ?? ink,
          height: 1.4,
        );
    return TextTheme(
      displayLarge: o(42, FontWeight.w700, spacing: -1.26), // saldo del Resumen
      displayMedium: o(38, FontWeight.w700, spacing: -1.14), // monto en ventana flotante
      headlineMedium: o(24, FontWeight.w700, spacing: -0.48), // título de pantalla
      headlineSmall: o(22, FontWeight.w700, spacing: -0.33),
      titleLarge: o(16.5, FontWeight.w600),
      titleMedium: o(15, FontWeight.w600),
      titleSmall: o(14.5, FontWeight.w600),
      bodyLarge: o(14.5, FontWeight.w400),
      bodyMedium: o(14, FontWeight.w400),
      bodySmall: o(12.5, FontWeight.w400, color: muted),
      labelLarge: o(13.5, FontWeight.w600),
      labelMedium: o(12, FontWeight.w500, color: muted),
      labelSmall: o(11, FontWeight.w400, color: muted),
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
      primary: neonGreen,
      onPrimary: darkBg,
      secondary: colors.income,
      onSecondary: bg,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
      surfaceContainerHighest: colors.raised,
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
          borderRadius: BorderRadius.circular(AppRadius.box),
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
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.brandInk
                : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            color: selected ? ink : muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: darkBg,
          minimumSize: const Size.fromHeight(AppSizes.primaryButton),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: text.titleLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(AppSizes.minTouch, AppSizes.actionButton),
          side: BorderSide(color: line, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          textStyle: text.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandInk,
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        hintStyle: text.bodyLarge?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? ink : line),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? neonGreen : muted),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.raised,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
