import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mg_colors.dart';

/// Tokens de espaciado según migasto-flutter-prompt.md y el prototipo HTML.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double card = 15; // padding interno de tarjetas: 15
  static const double lg = 16;
  static const double xl = 18; // padding horizontal de pantalla (.pad { padding: 0 18px })
  static const double xxl = 24;
}

/// Radios de borde según la especificación:
/// Tarjetas 20–24, botones y campos 16, chips 11–14, mark 32.
class AppRadius {
  static const double chip = 12; // chips 11-14
  static const double chipPill = 999;
  static const double small = 10;
  static const double icon = 12; // cuadrito redondeado de categoría
  static const double field = 16; // campos en casilla (alto 56) y botones
  static const double button = 16; // botón principal: 16
  static const double card = 20; // tarjetas base: 20
  static const double cardLarge = 24; // tarjeta de balance: 24
  static const double box = 20; // cajas de ajustes / listas
  static const double sheet = 24; // hojas modales inferiores
  static const double fab = 28; // botón circular de registrar
  static const double mark = 32; // mark / logo squircle: 32
}

/// Dimensiones clave de controles
class AppSizes {
  static const double iconButton = 44;
  static const double minTouch = 48;
  static const double primaryButton = 54;
  static const double field = 56; // campo en casilla de 56 de alto
  static const double chipHeight = 34;
  static const double categoryIcon = 40;
  static const double fab = 56;
  static const double track = 6; // barra de progreso de 6 px
  static const double overlayTimeline = 4;
}

/// Curvas y duraciones de animación
class AppMotion {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration counter = Duration(milliseconds: 350);
  static const Duration overlayTimer = Duration(seconds: 4);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve tabPill = Curves.easeOutBack; // píldora de la barra inferior
}

/// Estilos de texto especializados (Inter + cifras tabulares para montos)
class AppText {
  static const String fontFamily = 'Inter';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Tipografía de montos según la especificación:
  /// Inter 800, tabular figures, letterSpacing: -0.03em.
  static TextStyle money({
    double size = 33,
    FontWeight weight = FontWeight.w800,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * -0.03,
      color: color ?? MgColors.ink,
      fontFeatures: tabular,
      height: 1.15,
    );
  }

  /// Aplica cifras tabulares a un estilo existente.
  static TextStyle amount(TextStyle base) =>
      base.copyWith(fontFeatures: tabular);
}
