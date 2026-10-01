import '../../domain/entities/movimiento.dart';
import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Ícono de línea de cada categoría (reemplaza a los emojis).
AppIcons categoryIcon(Categoria category) {
  switch (category) {
    case Categoria.alimentacion:
      return AppIcons.food;
    case Categoria.transporte:
      return AppIcons.car;
    case Categoria.compras:
      return AppIcons.bag;
    case Categoria.servicios:
      return AppIcons.bolt;
    case Categoria.entretenimiento:
      return AppIcons.film;
    case Categoria.otros:
    case Categoria.otrosIngresos:
      return AppIcons.box;
    case Categoria.sueldo:
      return AppIcons.salary;
    case Categoria.transferenciaRecibida:
      return AppIcons.swap;
    case Categoria.venta:
      return AppIcons.hand;
  }
}

/// Ícono de una categoría: uno del set de la app o, en las categorías propias, uno que eligió el usuario.
class CategoryGlyph {
  const CategoryGlyph.app(AppIcons this._app) : _material = null;
  const CategoryGlyph.material(IconData this._material) : _app = null;

  final AppIcons? _app;
  final IconData? _material;

  Widget build({double size = AppIconSize.small, Color? color}) {
    final app = _app;
    if (app != null) return AppIcon(app, size: size, color: color);
    return Icon(_material, size: size + 2, color: color);
  }
}

CategoryGlyph glyphFor(Categoria category) => CategoryGlyph.app(categoryIcon(category));
