import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../../domain/entities/movimiento.dart';

/// Cuadrito redondeado (por defecto 38×38, radio 12) con el color de fondo suave
/// y el ícono representativo de la categoría.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 38,
    this.iconSize = 19,
    this.radius = 12,
    this.customColor,
    this.customIcon,
  });

  final Categoria? category;
  final double size;
  final double iconSize;
  final double radius;
  final Color? customColor;
  final IconData? customIcon;

  static Color colorForCategory(Categoria? cat) {
    if (cat == null) return MgCategoryColors.otros;
    switch (cat) {
      case Categoria.alimentacion:
        return MgCategoryColors.restaurantesYOcasional;
      case Categoria.transporte:
        return MgCategoryColors.transporte;
      case Categoria.servicios:
        return MgCategoryColors.servicios;
      case Categoria.compras:
        return MgCategoryColors.mercado;
      case Categoria.entretenimiento:
        return MgCategoryColors.suscripciones;
      case Categoria.otros:
        return MgCategoryColors.gastoHormiga;
      case Categoria.sueldo:
        return MgCategoryColors.sueldo;
      case Categoria.transferenciaRecibida:
        return MgCategoryColors.transferencias;
      case Categoria.venta:
        return MgCategoryColors.ingresoExtra;
      case Categoria.otrosIngresos:
        return MgCategoryColors.ingresoExtra;
    }
  }

  static IconData iconForCategory(Categoria? cat) {
    if (cat == null) return Icons.category_outlined;
    switch (cat) {
      case Categoria.alimentacion:
        return Icons.restaurant_outlined;
      case Categoria.transporte:
        return Icons.directions_bus_outlined;
      case Categoria.servicios:
        return Icons.bolt_outlined;
      case Categoria.compras:
        return Icons.shopping_bag_outlined;
      case Categoria.entretenimiento:
        return Icons.tv_outlined;
      case Categoria.otros:
        return Icons.more_horiz;
      case Categoria.sueldo:
        return Icons.account_balance_wallet_outlined;
      case Categoria.transferenciaRecibida:
        return Icons.swap_horiz;
      case Categoria.venta:
        return Icons.storefront_outlined;
      case Categoria.otrosIngresos:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = customColor ?? colorForCategory(category);
    final iconData = customIcon ?? iconForCategory(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: iconSize,
          color: catColor,
        ),
      ),
    );
  }
}
