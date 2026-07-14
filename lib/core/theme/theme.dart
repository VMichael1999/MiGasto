import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color yapePurple = Color(0xFF6B2A8C);
  static const Color plinTeal = Color(0xFF00B5A3);
  static const Color googlePayBlue = Color(0xFF1A73E8);
  static const Color manualGray = Color(0xFF5F6368);

  // App Theme Accent Colors
  static const Color neonGreen = Color(0xFF8CE885);
  static const Color darkBg = Color(0xFF0F0E13);
  static const Color cardBg = Color(0xFF1B1922);

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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        onPrimary: Colors.black,
        surface: cardBg,
        onSurface: Colors.white,
        surfaceContainerHighest: darkBg,
        secondary: Color(0xFF22202A),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: Color(0xFF25232F),
            width: 1,
          ),
        ),
        color: cardBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF131219),
        indicatorColor: neonGreen.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: neonGreen);
          }
          return const IconThemeData(color: Colors.grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(color: neonGreen, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return GoogleFonts.outfit(color: Colors.grey, fontSize: 11);
        }),
      ),
    );
  }
}
