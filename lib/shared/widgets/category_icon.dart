import '../../domain/entities/expense.dart';
import 'app_icons.dart';

/// Ícono de línea de cada categoría (reemplaza a los emojis).
AppIcons categoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.alimentacion:
      return AppIcons.food;
    case ExpenseCategory.transporte:
      return AppIcons.car;
    case ExpenseCategory.compras:
      return AppIcons.bag;
    case ExpenseCategory.servicios:
      return AppIcons.bolt;
    case ExpenseCategory.entretenimiento:
      return AppIcons.film;
    case ExpenseCategory.otros:
      return AppIcons.box;
  }
}
