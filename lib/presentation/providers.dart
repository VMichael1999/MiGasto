import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/datasource/local_database.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../domain/entities/expense.dart';
import '../domain/repositories/expense_repository.dart';
import '../data/services/nlp_classifier_service.dart';

// 1. SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences inside main() and override this provider');
});

// 2. LocalDatabase Provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return DatabaseManager(prefs);
});

// 3. ExpenseRepository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  return ExpenseRepositoryImpl(db, prefs);
});

// 4. Pending Expense State Provider
final pendingExpenseProvider = StateProvider<Expense?>((ref) => null);

// 5. Budget State Provider
final budgetProvider = StateProvider<double>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getBudget();
});

// 6. Active Providers Configuration Provider
final providersEnabledProvider = StateNotifierProvider<ProvidersEnabledNotifier, Map<String, bool>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return ProvidersEnabledNotifier(repo);
});

class ProvidersEnabledNotifier extends StateNotifier<Map<String, bool>> {
  final ExpenseRepository _repo;

  ProvidersEnabledNotifier(this._repo) : super(_repo.getProviders());

  void toggleProvider(String key) {
    final updated = Map<String, bool>.from(state);
    if (updated.containsKey(key)) {
      updated[key] = !updated[key]!;
      _repo.saveProviders(updated);
      state = updated;
    }
  }
}

// 7. Expenses State Notifier Provider
final expensesStateProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return ExpensesNotifier(repo, ref);
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repo;
  final Ref _ref;
  static const _channel = MethodChannel('com.example.mi_gasto/accessibility');
  final _uuid = const Uuid();

  ExpensesNotifier(this._repo, this._ref) : super([]) {
    _loadExpenses();
    _initChannel();
  }

  Future<void> _loadExpenses() async {
    final list = await _repo.getExpenses();

    list.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) {
      state = list;
    }
  }

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTransactionDetected') {
        final map = call.arguments as Map;
        final amount = (map['amount'] as num).toDouble();
        final peerName = map['peerName'] as String;
        final providerStr = map['provider'] as String;
        final rawText = map['rawText'] as String;

        // Check if provider is enabled
        final activeProviders = _ref.read(providersEnabledProvider);
        if (activeProviders[providerStr] == true) {
          triggerIncomingPayment(
            amount: amount,
            merchant: peerName,
            providerStr: providerStr,
            rawText: rawText,
          );
        }
      } else if (call.method == 'onTransactionSaved') {
        _loadExpenses();
      }
    });
  }

  Future<void> triggerIncomingPayment({
    required double amount,
    required String merchant,
    required String providerStr,
    required String rawText,
  }) async {
    final source = PaymentSource.values.firstWhere(
      (s) => s.name == providerStr,
      orElse: () => PaymentSource.manual,
    );

    // 1. Check if we have learned overrides for this merchant
    ExpenseCategory? predictedCategory = await _repo.getCategoryOverride(merchant);

    // 2. If no overrides found, run rules-based NLP classifier
    predictedCategory ??= NlpClassifierService.classify(rawText, merchant);

    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: predictedCategory,
      source: source,
      date: DateTime.now(),
      isConfirmed: false,
      notes: rawText,
    );

    _ref.read(pendingExpenseProvider.notifier).state = expense;
  }

  Future<void> confirmPendingExpense(ExpenseCategory finalCategory, String notes) async {
    final pending = _ref.read(pendingExpenseProvider);
    if (pending == null) return;

    final confirmed = pending.copyWith(
      category: finalCategory,
      notes: notes,
      isConfirmed: true,
    );

    // Save learning preference
    await _repo.saveCategoryOverride(pending.merchant, finalCategory);

    // Save to database
    await _repo.saveExpense(confirmed);
    
    // Update local state
    state = [confirmed, ...state]..sort((a, b) => b.date.compareTo(a.date));
    
    // Clear pending alerts
    _ref.read(pendingExpenseProvider.notifier).state = null;
  }

  void discardPendingExpense() {
    _ref.read(pendingExpenseProvider.notifier).state = null;
  }

  Future<void> addManualExpense(double amount, String merchant, ExpenseCategory category) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: category,
      source: PaymentSource.manual,
      date: DateTime.now(),
      isConfirmed: true,
      notes: 'Registro manual',
    );
    await _repo.saveExpense(expense);
    state = [expense, ...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> updateExpense(Expense updated) async {
    await _repo.updateExpense(updated);
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  Future<void> updateBudget(double newBudget) async {
    await _repo.saveBudget(newBudget);
    _ref.read(budgetProvider.notifier).state = newBudget;
  }
}

// Checking Native Platform permissions helpers
final permissionsCheckerProvider = Provider((ref) {
  const channel = MethodChannel('com.example.mi_gasto/accessibility');

  return PermissionsChecker(channel);
});

class PermissionsChecker {
  final MethodChannel _channel;

  PermissionsChecker(this._channel);

  Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      // Ignore
    }
  }

  Future<bool> isOverlayGranted() async {
    try {
      final bool? result = await _channel.invokeMethod('isOverlayPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {
      // Ignore
    }
  }

  Future<void> simulateNotification(String text) async {
    try {
      await _channel.invokeMethod('simulateNotification', {'text': text});
    } catch (_) {
      // Ignore
    }
  }
}

// 8. Profile Name State Provider
final profileNameProvider = StateNotifierProvider<ProfileStringNotifier, String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ProfileStringNotifier(prefs, 'profile_name', '');
});

// 9. Profile Email State Provider
final profileEmailProvider = StateNotifierProvider<ProfileStringNotifier, String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ProfileStringNotifier(prefs, 'profile_email', '');
});

class ProfileStringNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  final String _key;

  ProfileStringNotifier(this._prefs, this._key, String defaultValue)
      : super(_prefs.getString(_key) ?? defaultValue);

  Future<void> updateValue(String newValue) async {
    await _prefs.setString(_key, newValue);
    state = newValue;
  }
}

// 10. Passcode Security State Provider
final passcodeEnabledProvider = StateNotifierProvider<PasscodeNotifier, bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return PasscodeNotifier(prefs);
});

class PasscodeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'migasto_passcode_enabled';

  PasscodeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle() async {
    final next = !state;
    await _prefs.setBool(_key, next);
    state = next;
  }
}
