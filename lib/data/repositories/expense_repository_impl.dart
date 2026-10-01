import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasource/local_database.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalDatabase _db;
  final SharedPreferences _prefs;

  static const String _keyBudget = 'migasto_monthly_budget_v2';
  static const String _keyProvidersEnabled = 'migasto_providers_enabled_v2';
  static const String _keyAliases = 'migasto_aliases_v1';
  static const String _keyCategoryOverrides = 'migasto_category_overrides_v2';

  ExpenseRepositoryImpl(this._db, this._prefs);

  @override
  Future<List<Movimiento>> getExpenses() => _db.getExpenses();

  @override
  Future<void> saveExpense(Movimiento expense) => _db.saveExpense(expense);

  @override
  Future<void> updateExpense(Movimiento expense) => _db.saveExpense(expense);

  @override
  Future<void> deleteExpense(String id) => _db.deleteExpense(id);

  @override
  Future<void> saveCategoryOverride(String merchant, Categoria category) async {
    final overrides = _getOverridesMap();
    overrides[merchant.toLowerCase().trim()] = category.name;
    await _prefs.setString(_keyCategoryOverrides, jsonEncode(overrides));
  }

  @override
  Future<Categoria?> getCategoryOverride(String merchant) async {
    final overrides = _getOverridesMap();
    final key = merchant.toLowerCase().trim();
    if (overrides.containsKey(key)) {
      final name = overrides[key]!;
      return Categoria.values.firstWhere(
        (c) => c.name == name,
        orElse: () => Categoria.otros,
      );
    }
    return null;
  }

  @override
  Map<String, String> getAllCategoryOverrides() {
    return _getOverridesMap();
  }

  @override
  Future<void> deleteCategoryOverride(String merchant) async {
    final overrides = _getOverridesMap();
    overrides.remove(merchant.toLowerCase().trim());
    await _prefs.setString(_keyCategoryOverrides, jsonEncode(overrides));
  }

  @override
  Future<void> clearAllCategoryOverrides() async {
    await _prefs.remove(_keyCategoryOverrides);
  }

  Map<String, String> _getOverridesMap() {
    final raw = _prefs.getString(_keyCategoryOverrides);
    if (raw == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  @override
  Map<String, String> getAllAliases() {
    final raw = _prefs.getString(_keyAliases);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveAlias(String merchant, String alias) async {
    final aliases = getAllAliases();
    aliases[aliasKey(merchant)] = alias.trim();
    await _prefs.setString(_keyAliases, jsonEncode(aliases));
  }

  @override
  Future<void> deleteAlias(String merchant) async {
    final aliases = getAllAliases()..remove(aliasKey(merchant));
    await _prefs.setString(_keyAliases, jsonEncode(aliases));
  }

  @override
  Future<void> saveBudget(double budget) async {
    await _prefs.setDouble(_keyBudget, budget);
  }

  @override
  double getBudget() {
    return _prefs.getDouble(_keyBudget) ?? 1200.0;
  }

  @override
  Future<void> saveProviders(Map<String, bool> providers) async {
    await _prefs.setString(_keyProvidersEnabled, jsonEncode(providers));
  }

  @override
  Map<String, bool> getProviders() {
    final raw = _prefs.getString(_keyProvidersEnabled);
    if (raw == null) {
      return {
        'yape': true,
        'plin': true,
        'googlePay': true,
      };
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, v as bool));
    } catch (_) {
      return {
        'yape': true,
        'plin': true,
        'googlePay': true,
      };
    }
  }
}
