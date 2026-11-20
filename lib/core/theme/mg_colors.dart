import 'package:flutter/material.dart';

/// Paleta oficial de tokens de color de MiGasto según migasto-flutter-prompt.md
abstract final class MgColors {
  static const bg      = Color(0xFF0A0A0D);  // fondo
  static const card    = Color(0xFF15151B);  // tarjetas
  static const card2   = Color(0xFF1C1C24);  // pulsado
  static const soft    = Color(0xFF1F1F27);  // campos, botón secundario
  static const line    = Color(0xFF26262F);  // separadores / bordes
  static const ink     = Color(0xFFF4F3F7);  // texto principal
  static const ink2    = Color(0xFF8B8898);  // texto secundario / etiquetas
  static const ink3    = Color(0xFF585666);  // texto tenue / deshabilitado
  static const acc     = Color(0xFF7C5CFF);  // violeta principal MiGasto
  static const acc2    = Color(0xFF9B82FF);  // violeta claro / acento 2
  static const accSoft = Color(0xFF1E1935);  // violeta fondo suave
  static const accLine = Color(0xFF3A2F6B);  // violeta borde
  static const up      = Color(0xFF2FD98A);  // ingresos
  static const down    = Color(0xFFFF5C6E);  // gastos
  static const warn    = Color(0xFFF5A524);  // límite cerca / advertencia

  /// Borde sutil para superficies oscuras (nivel card/soft)
  static final borderTenue = Colors.white.withValues(alpha: 0.06);
}

/// Colores fijos por categoría según la especificación
abstract final class MgCategoryColors {
  static const alquiler               = Color(0xFFA78BFA); // casa
  static const mercado                = Color(0xFFFF5C8A); // carrito
  static const restaurantesYOcasional = Color(0xFFF5A524); // cubiertos
  static const servicios              = Color(0xFF7C5CFF); // rayo
  static const transporte             = Color(0xFF22D3EE); // bus
  static const suscripciones          = Color(0xFFFF8A3D); // pantalla
  static const salud                  = Color(0xFF2FD98A); // corazón
  static const gastoHormiga           = Color(0xFF60A5FA); // hormiga
  static const hijos                  = Color(0xFFFB7185); // persona
  static const transferencias         = Color(0xFF94A3B8); // flechas
  static const sueldo                 = Color(0xFF2FD98A); // billetera
  static const ingresoExtra           = Color(0xFF34D399); // banco
  static const otros                  = Color(0xFF8B8898); // otros
}

/// Degradados clave del diseño
abstract final class MgGradients {
  /// Degradado violeta de la tarjeta principal de balance
  static const balanceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8054FF),
      Color(0xFF5027DE),
    ],
  );

  /// Degradado del botón de Registro Inteligente
  static const smartEntry = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF7C5CFF),
      Color(0xFF22D3EE),
    ],
  );

  /// Degradado del logo / mark
  static const brandMark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B82FF),
      Color(0xFF6A46F5),
    ],
  );
}
