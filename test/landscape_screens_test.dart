import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/expenses/expenses_screen.dart';
import 'package:mi_gasto/presentation/expenses/manual_entry_screen.dart';
import 'package:mi_gasto/presentation/plan/plan_providers.dart';
import 'package:mi_gasto/presentation/plan/plan_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/reports/reports_screen.dart';
import 'package:mi_gasto/presentation/settings/settings_screen.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  Future<void> show(WidgetTester tester, Widget screen, {Size size = const Size(844, 390)}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final now = DateTime.now().subtract(const Duration(minutes: 1));
    final m = Movimiento(
      id: 'g1',
      amount: 25.5,
      merchant: 'Tambo',
      category: Categoria.compras,
      source: PaymentSource.manual,
      date: now,
      tipo: TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
    );
    await container.read(expenseRepositoryProvider).saveExpense(m);
    await container.read(expensesStateProvider.notifier).restoreExpense(m);
    container.read(categoryLimitsProvider.notifier).setLimit(Categoria.compras, 100);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => screen)]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    ));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Stats en horizontal: categorías a un lado e ingresos vs gastos al otro', (tester) async {
    await show(tester, const ReportsScreen());
    expect(find.text('Gastos por categoría'), findsOneWidget);
    expect(find.text('Ingresos vs gastos'), findsOneWidget);
    // Los dos bloques quedan lado a lado, no uno bajo el otro.
    final left = tester.getTopLeft(find.text('Gastos por categoría')).dx;
    final right = tester.getTopLeft(find.text('Ingresos vs gastos')).dx;
    expect(right, greaterThan(left + 200));
  });

  testWidgets('Buscar en horizontal: filtros a la izquierda y lista a la derecha', (tester) async {
    await show(tester, const ExpensesScreen());
    final search = tester.getTopLeft(find.text('Todo')).dx;
    final list = tester.getTopLeft(find.text('Tambo').first).dx;
    expect(list, greaterThan(search + 200));
  });

  testWidgets('Plan en horizontal: meta a la izquierda y límites a la derecha', (tester) async {
    await show(tester, const PlanScreen());
    final goal = tester.getTopLeft(find.text('Define tu meta de ahorro')).dx;
    final limit = tester.getTopLeft(find.text('Compras').first).dx;
    expect(limit, greaterThan(goal + 200));
  });

  testWidgets('Perfil en horizontal: cuenta a la izquierda y datos a la derecha', (tester) async {
    await show(tester, const SettingsScreen());
    final account = tester.getTopLeft(find.text('Categorías')).dx;
    final data = tester.getTopLeft(find.text('Presupuesto mensual')).dx;
    expect(data, greaterThan(account + 200));
  });

  testWidgets('Nuevo gasto en horizontal: formulario y teclado lado a lado', (tester) async {
    await show(tester, const ManualEntryScreen());
    final form = tester.getTopLeft(find.text('Nuevo gasto')).dx;
    final keypad = tester.getTopLeft(find.text('5').last).dx;
    expect(keypad, greaterThan(form + 200));
  });
}
