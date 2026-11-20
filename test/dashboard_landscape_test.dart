import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/dashboard/dashboard_screen.dart';
import 'package:mi_gasto/presentation/plan/plan_providers.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _m(String id, double amount, DateTime date,
        {bool ingreso = false, Categoria cat = Categoria.compras}) =>
    Movimiento(
      id: id,
      amount: amount,
      merchant: 'Comercio $id',
      category: ingreso ? Categoria.otrosIngresos : cat,
      source: PaymentSource.manual,
      date: date,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  Future<ProviderContainer> open(WidgetTester tester, Size size, List<Movimiento> movs) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(expensesStateProvider.notifier);
    for (final m in movs) {
      await container.read(expenseRepositoryProvider).saveExpense(m);
      await notifier.restoreExpense(m);
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const DashboardScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  testWidgets('horizontal sin datos: tres columnas y avisos en vez de cifras', (tester) async {
    await open(tester, const Size(844, 390), []);

    expect(find.text('Balance disponible'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Presupuestos'), findsOneWidget);
    expect(find.text('Gastos por categoría'), findsOneWidget);
    expect(find.text('Saldo a 30 días'), findsOneWidget);
    expect(find.text('Aún no tienes límites. Créalos en Plan.'), findsOneWidget);

    // La lupa de Movimientos queda en el borde derecho de su columna (la del
    // medio va de 281 a 563, con 18 de margen y el botón de 38 con el ícono de 19),
    // no pegada al contador.
    final lupa = tester.getRect(find.byIcon(Icons.search_rounded).first);
    expect(lupa.right, closeTo(563 - 18 - 9.5, 3));
    expect(find.text('Aún no hay gastos este mes.'), findsOneWidget);
    expect(find.textContaining('Registra al menos 3 movimientos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal con datos reales: límite, categorías y estimación', (tester) async {
    final now = DateTime.now();
    // Movimientos siempre en el pasado (un minuto atrás cuenta como hoy).
    final day = now.subtract(const Duration(minutes: 1));
    final container = await open(tester, const Size(932, 430), [
      _m('i', 1000, day.subtract(const Duration(days: 8)), ingreso: true),
      _m('a', 120, day.subtract(const Duration(days: 2))),
      _m('b', 80, day, cat: Categoria.transporte),
    ]);
    container.read(categoryLimitsProvider.notifier).setLimit(Categoria.compras, 200);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Compras'), findsWidgets);
    expect(find.textContaining('de S/ 200.00'), findsOneWidget);
    expect(find.text('Estimación'), findsOneWidget);
    expect(find.textContaining('por día'), findsOneWidget);
    expect(find.textContaining('Registra al menos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en vertical sigue siendo una sola columna sin las tarjetas laterales', (tester) async {
    await open(tester, const Size(420, 900), []);

    expect(find.text('Balance disponible'), findsOneWidget);
    expect(find.text('Presupuestos'), findsNothing);
    expect(find.text('Saldo a 30 días'), findsNothing);
  });
}
