import 'package:isar/isar.dart';

part 'expense_model.g.dart';

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
}
