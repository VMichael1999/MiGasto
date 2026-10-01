import 'package:flutter/material.dart';

/// Tokens de espaciado, radios, tamaños y motion tomados del rediseño v0.2.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18; // padding horizontal de pantalla
  static const double xxl = 22;
}

class AppRadius {
  static const double chip = 999;
  static const double small = 9;
  static const double icon = 11; // ícono de categoría en listas
  static const double field = 13; // campos, botones de ícono, segmentos
  static const double card = 14; // tarjetas pequeñas, chips de estado
  static const double button = 15; // botón principal
  static const double box = 16; // cajas de ajustes
  static const double sheet = 22; // hojas y ventana flotante
  static const double fab = 18; // botón agregar de la barra inferior
}

class AppSizes {
  static const double iconButton = 44;
  static const double minTouch = 48;
  static const double primaryButton = 54;
  static const double actionButton = 46; // botones de la ventana flotante
  static const double field = 50;
  static const double chipHeight = 34;
  static const double categoryIcon = 36;
  static const double fab = 52;
  static const double track = 8; // barra de presupuesto
  static const double overlayTimeline = 4;
}

class AppMotion {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration counter = Duration(milliseconds: 350); // < 400 ms
  static const Duration overlayTimer = Duration(seconds: 4);
  static const Curve standard = Curves.easeOutCubic;
}

/// Estilos de texto fuera del `TextTheme` estándar.
class AppText {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Aplica cifras tabulares a un estilo; úsalo en montos.
  static TextStyle amount(TextStyle base) =>
      base.copyWith(fontFeatures: tabular);
}
