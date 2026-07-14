import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';

abstract class LocalDatabase {
  Future<void> init();
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> deleteExpense(String id);
}

class DatabaseManager implements LocalDatabase {
  final SharedPreferences _prefs;
  Isar? _isar;
  bool _useFallback = false;

  static const String _keyFallbackExpenses = 'migasto_fallback_expenses';

  DatabaseManager(this._prefs);

  @override
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Only open if not already open
      _isar = Isar.getInstance();
      _isar ??= await Isar.open(
        [ExpenseModelSchema],
        directory: dir.path,
      );
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      _useFallback = true;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    if (_useFallback || _isar == null) {
      return _loadFallbackExpenses();
    }
    try {
      final models = await _isar!.expenseModels.where().findAll();
      return models.map(_fromModel).toList();
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      return _loadFallbackExpenses();
    }
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    if (_useFallback || _isar == null) {
      await _saveFallbackExpense(expense);
      return;
    }
    try {
      final existing = await _isar!.expenseModels
          .filter()
          .uuidEqualTo(expense.id)
          .findFirst();

      final model = _toModel(expense);
      if (existing != null) {
        model.id = existing.id; // Retain Isar primary key
      }

      await _isar!.writeTxn(() async {
        await _isar!.expenseModels.put(model);
      });
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      await _saveFallbackExpense(expense);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    if (_useFallback || _isar == null) {
      await _deleteFallbackExpense(id);
      return;
    }
    try {
      final existing = await _isar!.expenseModels
          .filter()
          .uuidEqualTo(id)
          .findFirst();
      if (existing != null) {
        await _isar!.writeTxn(() async {
          await _isar!.expenseModels.delete(existing.id);
        });
      }
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      await _deleteFallbackExpense(id);
    }
  }

  // Fallback storage helpers (SharedPreferences JSON list)
  List<Expense> _loadFallbackExpenses() {
    final raw = _prefs.getString(_keyFallbackExpenses);
    if (raw == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return Expense(
          id: map['id'],
          amount: (map['amount'] as num).toDouble(),
          merchant: map['merchant'],
          category: ExpenseCategory.values.firstWhere(
            (c) => c.name == map['category'],
            orElse: () => ExpenseCategory.otros,
          ),
          source: PaymentSource.values.firstWhere(
            (s) => s.name == map['source'],
            orElse: () => PaymentSource.manual,
          ),
          date: DateTime.parse(map['date']),
          notes: map['notes'] ?? '',
          isConfirmed: map['isConfirmed'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      return [];
    }
  }

  Future<void> _saveFallbackExpense(Expense expense) async {
    final list = _loadFallbackExpenses();
    final index = list.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      list[index] = expense;
    } else {
      list.add(expense);
    }
    await _saveAllFallback(list);
  }

  Future<void> _deleteFallbackExpense(String id) async {
    final list = _loadFallbackExpenses();
    list.removeWhere((e) => e.id == id);
    await _saveAllFallback(list);
  }

  Future<void> _saveAllFallback(List<Expense> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'amount': e.amount,
      'merchant': e.merchant,
      'category': e.category.name,
      'source': e.source.name,
      'date': e.date.toIso8601String(),
      'notes': e.notes,
      'isConfirmed': e.isConfirmed,
    }).toList();
    await _prefs.setString(_keyFallbackExpenses, jsonEncode(jsonList));
  }

  // Model mapper logic
  ExpenseModel _toModel(Expense entity) {
    return ExpenseModel()
      ..uuid = entity.id
      ..amount = entity.amount
      ..merchant = entity.merchant
      ..categoryName = entity.category.name
      ..sourceName = entity.source.name
      ..date = entity.date
      ..notes = entity.notes
      ..isConfirmed = entity.isConfirmed;
  }

  Expense _fromModel(ExpenseModel model) {
    return Expense(
      id: model.uuid,
      amount: model.amount,
      merchant: model.merchant,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == model.categoryName,
        orElse: () => ExpenseCategory.otros,
      ),
      source: PaymentSource.values.firstWhere(
        (s) => s.name == model.sourceName,
        orElse: () => PaymentSource.manual,
      ),
      date: model.date,
      notes: model.notes,
      isConfirmed: model.isConfirmed,
    );
  }
}
