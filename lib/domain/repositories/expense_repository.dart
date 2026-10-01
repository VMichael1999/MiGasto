import '../entities/movimiento.dart';

abstract class ExpenseRepository {
  Future<List<Movimiento>> getExpenses();
  Future<void> saveExpense(Movimiento expense);
  Future<void> updateExpense(Movimiento expense);
  Future<void> deleteExpense(String id);

  // Category Override / Machine Learning override helpers
  Future<void> saveCategoryOverride(String merchant, Categoria category);
  Future<Categoria?> getCategoryOverride(String merchant);
  Map<String, String> getAllCategoryOverrides();
  Future<void> deleteCategoryOverride(String merchant);
  Future<void> clearAllCategoryOverrides();

  // General Settings persistence
  Future<void> saveBudget(double budget);
  double getBudget();

  Future<void> saveProviders(Map<String, bool> providers);
  Map<String, bool> getProviders();
}
