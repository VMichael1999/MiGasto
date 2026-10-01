import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  group('Expenses Notifier & State Tests', () {
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      // Trigger DB initialization
      await container.read(localDatabaseProvider).init();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial loading is empty by default', () async {
      // Warm up the provider
      container.read(expensesStateProvider.notifier);
      // Wait for async load to settle
      await Future.delayed(const Duration(milliseconds: 100));
      
      final list = container.read(expensesStateProvider);
      expect(list.isEmpty, true);
      expect(container.read(budgetProvider), 1200.0);
    });

    test('Incoming transaction sets pending expense state', () async {
      expect(container.read(pendingExpenseProvider), isNull);

      await container.read(expensesStateProvider.notifier).triggerIncomingPayment(
        amount: 25.50,
        merchant: 'Tambo',
        providerStr: 'yape',
        rawText: 'Yapeaste S/ 25.50 a Tambo',
      );

      final pending = container.read(pendingExpenseProvider);
      expect(pending, isNotNull);
      expect(pending!.amount, 25.50);
      expect(pending.merchant, 'Tambo');
      expect(pending.category, Categoria.compras); // Tambo auto-classified as Compras
      expect(pending.isConfirmed, false);
    });

    test('Confirming pending expense adds it to state and learns category override', () async {
      await container.read(expensesStateProvider.notifier).triggerIncomingPayment(
        amount: 35.00,
        merchant: 'Tambo',
        providerStr: 'yape',
        rawText: 'Yapeaste S/ 35.00 a Tambo',
      );

      // Confirm with category 'compras'
      await container.read(expensesStateProvider.notifier).confirmPendingExpense(
        Categoria.compras,
        'Nota de prueba',
      );

      // Should be added to list
      final list = container.read(expensesStateProvider);
      expect(list.first.merchant, 'Tambo');
      expect(list.first.amount, 35.00);
      expect(list.first.category, Categoria.compras);
      expect(list.first.isConfirmed, true);

      // Verify pending is cleared
      expect(container.read(pendingExpenseProvider), isNull);

      // Verify category override is learned
      final learned = await container.read(expenseRepositoryProvider).getCategoryOverride('Tambo');
      expect(learned, Categoria.compras);
    });
  });
}
