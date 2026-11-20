import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/ai/ai_screen.dart';
import 'package:mi_gasto/presentation/expenses/expenses_screen.dart';
import 'package:mi_gasto/presentation/expenses/manual_entry_screen.dart';
import 'package:mi_gasto/presentation/onboarding/login_screen.dart';
import 'package:mi_gasto/presentation/onboarding/onboarding_screen.dart';
import 'package:mi_gasto/core/widgets/charts.dart';
import 'package:mi_gasto/presentation/plan/plan_providers.dart';
import 'package:mi_gasto/presentation/reports/fullscreen_chart_screen.dart';
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

  testWidgets('MiGastoIA en horizontal: sugerencias a la izquierda y chat con entrada a la derecha', (tester) async {
    await show(tester, const AiScreen());
    final hint = find.text('Pregúntale a MiGastoIA');
    expect(hint, findsOneWidget);
    // La entrada queda a la derecha de las sugerencias, que van en columna.
    expect(tester.getTopLeft(hint).dx, greaterThan(270));
    expect(tester.getTopLeft(find.byIcon(Icons.auto_awesome_rounded).first).dx, lessThan(270));
    expect(tester.takeException(), isNull);
    // El avatar programa un parpadeo: se desmonta y se deja correr el reloj.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('MiGastoIA en vertical: sugerencias sobre la entrada', (tester) async {
    await show(tester, const AiScreen(), size: const Size(390, 844));
    expect(find.text('Pregúntale a MiGastoIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // El avatar programa un parpadeo: se desmonta y se deja correr el reloj.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Login en horizontal: bienvenida a la izquierda y formulario a la derecha', (tester) async {
    await show(tester, const LoginScreen());
    expect(tester.getTopLeft(find.text('Hola de nuevo')).dx, lessThan(422));
    expect(tester.getTopLeft(find.text('Ingresar')).dx, greaterThan(422));
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Continuar como invitado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding en horizontal: arte a la izquierda y texto con botón a la derecha', (tester) async {
    await show(tester, const OnboardingScreen());
    expect(tester.getTopLeft(find.text('Siguiente')).dx, greaterThan(422));
    expect(find.text('Saltar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Gastos por categoría en horizontal: gráfico a la izquierda y desglose a la derecha', (tester) async {
    FullscreenChartScreen screen() => FullscreenChartScreen(
          month: DateTime(2026, 11),
          spaceName: 'Personal',
          segments: const [
            DonutSegment(label: 'Servicios', value: 300, color: Colors.purple),
            DonutSegment(label: 'Compras', value: 100, color: Colors.blue),
          ],
          catList: const [
            MapEntry(Categoria.servicios, 300),
            MapEntry(Categoria.compras, 100),
          ],
          total: 400,
          isHide: false,
          initialChartIndex: 1,
        );
    await show(tester, screen());
    final chartTotal = tester.getTopLeft(find.text('S/ 400.00'));
    final breakdown = tester.getTopLeft(find.text('Desglose por categoría'));
    expect(chartTotal.dx, lessThan(383));
    expect(breakdown.dx, greaterThan(383));
    // Las métricas rápidas quedan visibles sin desplazar.
    expect(find.text('Mayor gasto'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Mayor gasto')).dy, lessThan(390));
    expect(tester.takeException(), isNull);
  });
}
