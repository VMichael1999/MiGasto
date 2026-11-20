import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/plan/category_detail_screen.dart';
import 'package:mi_gasto/presentation/plan/plan_providers.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _g(String id, String merchant, double amount, DateTime date, Categoria cat) => Movimiento(
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

  final now = DateTime.now();
  // Movimientos de este mes (en el pasado: un minuto atrás y minutos antes).
  final t1 = now.subtract(const Duration(minutes: 1));
  final t2 = now.subtract(const Duration(minutes: 2));

  Future<void> open(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final n = container.read(expensesStateProvider.notifier);
    for (final m in [
      _g('a', 'Luz del Sur', 25, t1, Categoria.servicios),
      _g('b', 'Movistar', 15, t2, Categoria.servicios),
      _g('c', 'Wong', 60, t1, Categoria.compras),
    ]) {
      await container.read(expenseRepositoryProvider).saveExpense(m);
      await n.restoreExpense(m);
    }
    container.read(categoryLimitsProvider.notifier).setLimit(Categoria.servicios, 200);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CategoryDetailScreen(categoryId: 'servicios'),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('horizontal: dona y total a la izquierda; evolución y movimientos a la derecha', (tester) async {
    await open(tester, const Size(844, 390));

    expect(find.text('Servicios'), findsWidgets);
    expect(find.text('S/ 40.00'), findsWidgets); // total de la categoría
    expect(find.text('40 % de tus gastos del período'), findsOneWidget); // 40 de 100
    expect(find.text('Evolución'), findsOneWidget);
    expect(find.text('Luz del Sur'), findsOneWidget);
    expect(find.text('Movistar'), findsOneWidget);
    expect(find.text('Wong'), findsNothing); // otra categoría

    // Dos zonas lado a lado.
    final left = tester.getTopLeft(find.text('Mensual')).dx;
    final right = tester.getTopLeft(find.text('Evolución')).dx;
    expect(right, greaterThan(left + 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('los períodos cambian el rango, la evolución y ocultan el límite fuera del mes', (tester) async {
    await open(tester, const Size(844, 390));

    expect(find.text('Límite del mes'), findsOneWidget);

    // Los chips se desplazan en horizontal: se lleva el que se quiere a la vista.
    await tester.ensureVisible(find.text('Trimestral'));
    await tester.tap(find.text('Trimestral'));
    await tester.pumpAndSettle();
    expect(find.textContaining(' – '), findsWidgets); // «Oct – Dic 2026»
    expect(find.text('Límite del mes'), findsNothing);
    expect(find.text('S/ 40.00'), findsWidgets);

    await tester.ensureVisible(find.text('Quincenal'));
    await tester.tap(find.text('Quincenal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('–'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ir al período anterior vacía la lista y no se puede avanzar más allá de hoy', (tester) async {
    await open(tester, const Size(844, 390));

    final next = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sin movimientos'), findsOneWidget);
    expect(find.text('Luz del Sur'), findsNothing);
    expect(find.text('Aún no hay gastos en este período'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
  });

  testWidgets('vertical: una sola columna con el mismo contenido', (tester) async {
    await open(tester, const Size(420, 900));

    expect(find.text('40 % de tus gastos del período'), findsOneWidget);
    expect(find.text('Evolución'), findsOneWidget);
    expect(find.text('Luz del Sur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
