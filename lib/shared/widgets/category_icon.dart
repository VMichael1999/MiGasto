import '../../domain/entities/movimiento.dart';
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
