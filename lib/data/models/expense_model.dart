import 'package:isar/isar.dart';

part 'expense_model.g.dart';

/// Colección de movimientos. Conserva el nombre `ExpenseModel` para no perder
/// los datos ya guardados: los campos nuevos se leen con valor vacío en los
/// registros viejos y el mapeo en `local_database.dart` los completa.
@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;

  late String uuid;
  late double amount;
  late String merchant;
  late String categoryName;
  late String sourceName;
  late DateTime date;
  late String notes;
  late bool isConfirmed;

  // Agregados con Movimiento (vacío = registro anterior).
  String tipoName = '';
  String estadoName = '';
  String canalName = '';
  String? tarjeta;
  double? latitud;
  double? longitud;
  double? precision;
  String? lugar;
  String textoOriginal = '';
}
