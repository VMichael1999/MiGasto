import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/core/widgets/adaptive_sheet.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/expenses/movement_comparison_sheet.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _m(String id, String merchant, double amount, DateTime date,
        {Categoria cat = Categoria.servicios}) =>
    Movimiento(
      id: id,
      amount: amount,
      merchant: merchant,
      category: cat,
      source: PaymentSource.manual,
      date: date,
      tipo: TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  // Abre la comparación de [current] con el resto de movimientos de [others].
  Future<void> open(WidgetTester tester, Size size, Movimiento current, List<Movimiento> others) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final n = container.read(expensesStateProvider.notifier);
    for (final m in [current, ...others]) {
      await container.read(expenseRepositoryProvider).saveExpense(m);
      await n.restoreExpense(m);
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showMovementComparison(context, current),
                child: const Text('comparar'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('comparar'));
    await tester.pumpAndSettle();
  }

  final now = DateTime.now().subtract(const Duration(minutes: 1));
  DateTime monthsAgo(int n) => DateTime(now.year, now.month - n, 5, 10);

  testWidgets('con historial: la vez anterior, la diferencia y los meses', (tester) async {
    final current = _m('c', 'Netflix', 44.9, now);
    await open(tester, const Size(420, 900), current, [
      _m('a', 'Netflix', 39.9, monthsAgo(1)),
      _m('b', 'Netflix', 39.9, monthsAgo(2)),
    ]);

    expect(find.text('Comparar'), findsOneWidget);
    expect(find.text('Netflix · mismo comercio'), findsOneWidget);
    expect(find.text('Ahora'), findsOneWidget);
    expect(find.text('Vez anterior'), findsOneWidget);
    expect(find.text('S/ 44.90'), findsWidgets);
    expect(find.text('S/ 39.90'), findsWidgets);
    expect(find.textContaining('+S/ 5.00 (13 % más) respecto a la vez anterior'), findsOneWidget);
    expect(find.textContaining('13 % más que en'), findsOneWidget);
    // El mes en curso no ha terminado: se avisa para no sacar conclusiones apresuradas.
    expect(find.textContaining('el mes aún no termina'), findsOneWidget);
    expect(find.textContaining('Promedio de los meses anteriores: S/ 39.90'), findsOneWidget);
    expect(find.textContaining('Últimos 4 meses'), findsOneWidget);
  });

  testWidgets('la primera vez lo dice en lugar de inventar una comparación', (tester) async {
    final current = _m('c', 'Café nuevo', 12, now, cat: Categoria.alimentacion);
    await open(tester, const Size(420, 900), current, []);

    expect(find.textContaining('categoría (es la primera vez de «Café nuevo»)'), findsOneWidget);
    expect(find.textContaining('Es la primera vez que registras esto'), findsOneWidget);
    expect(find.text('Vez anterior'), findsNothing);
  });

  testWidgets('horizontal: se abre como panel lateral y cabe sin desbordarse', (tester) async {
    final current = _m('c', 'Netflix', 44.9, now);
    await open(tester, const Size(844, 390), current, [_m('a', 'Netflix', 39.9, monthsAgo(1))]);

    expect(find.byType(LandscapeSheet), findsOneWidget);
    final panel = tester.getRect(find.descendant(of: find.byType(LandscapeSheet), matching: find.byType(Material)).first);
    expect(panel.right, 844);
    expect(find.text('Netflix · mismo comercio'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Al ser más alto que la pantalla, se puede desplazar hasta el final.
    await tester.drag(find.text('Comparar'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.textContaining('Promedio de los meses anteriores'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
