import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);

  // Category Override / Machine Learning override helpers
  Future<void> saveCategoryOverride(String merchant, ExpenseCategory category);
  Future<ExpenseCategory?> getCategoryOverride(String merchant);
  Map<String, String> getAllCategoryOverrides();
  Future<void> deleteCategoryOverride(String merchant);
  Future<void> clearAllCategoryOverrides();

  // General Settings persistence
  Future<void> saveBudget(double budget);
  double getBudget();

  Future<void> saveProviders(Map<String, bool> providers);
  Map<String, bool> getProviders();
}
