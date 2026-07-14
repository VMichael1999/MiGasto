import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/data/repositories/expense_repository_impl.dart';
import 'package:mi_gasto/domain/entities/expense.dart';
import 'package:mi_gasto/domain/repositories/expense_repository.dart';

class MockDatabase implements LocalDatabase {
  @override
  Future<void> init() async {}
  @override
  Future<List<Expense>> getExpenses() async => [];
  @override
  Future<void> saveExpense(Expense expense) async {}
  @override
  Future<void> deleteExpense(String id) async {}
}

void main() {
  group('Category Learning & Overrides Tests', () {
    late ExpenseRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = MockDatabase();
      repository = ExpenseRepositoryImpl(db, prefs);
    });

    test('Learns category overrides and matches them', () async {
      // 1. Initially, should return null for a merchant
      var override = await repository.getCategoryOverride('Tambo Miraflores');
      expect(override, isNull);

      // 2. Save an override (User changes Tambo Miraflores to Compras)
      await repository.saveCategoryOverride('Tambo Miraflores', ExpenseCategory.compras);

      // 3. Verify it is saved and returned
      override = await repository.getCategoryOverride('Tambo Miraflores');
      expect(override, ExpenseCategory.compras);
    });

    test('Learns category overrides case-insensitively with trailing whitespace', () async {
      await repository.saveCategoryOverride('Tambo Miraflores', ExpenseCategory.compras);

      // Verify lowercase works
      var override = await repository.getCategoryOverride('tambo miraflores');
      expect(override, ExpenseCategory.compras);

      // Verify uppercase works
      override = await repository.getCategoryOverride('TAMBO MIRAFLORES');
      expect(override, ExpenseCategory.compras);

      // Verify with whitespace works
      override = await repository.getCategoryOverride('  Tambo Miraflores   ');
      expect(override, ExpenseCategory.compras);
    });
  });
}
