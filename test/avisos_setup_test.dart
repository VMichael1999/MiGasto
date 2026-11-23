import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/setup/avisos_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  Future<void> open(WidgetTester tester, {Movimiento? last}) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    if (last != null) {
      await container.read(expenseRepositoryProvider).saveExpense(last);
      await container.read(expensesStateProvider.notifier).restoreExpense(last);
    }
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('ajustes'))),
      GoRoute(path: '/guia', builder: (_, _) => const AvisosSetupScreen()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    ));
    // Se abre desde Ajustes, así que hay a dónde volver.
    router.push('/guia');
    await tester.pumpAndSettle();
  }

  testWidgets('explica los tres caminos con la acción «Registrar aviso de pago»', (tester) async {
    await open(tester);
    expect(find.text('Registra lo que pagas con Yape, Plin y tu banco.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Paso 1: MiGasto ya agregó la acción a Atajos. Listo')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Paso 2: Correos del banco')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Paso 3: SMS del banco.*19896')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Paso 4: Constancias en pantalla.*Tocar atrás')), findsOneWidget);
    expect(find.text('Abrir Atajos'), findsOneWidget);
    expect(find.textContaining('Cuando llegue tu primer aviso'), findsOneWidget);
  });

  testWidgets('con un aviso ya registrado muestra cuándo llegó', (tester) async {
    await open(tester,
        last: Movimiento(
          id: 'a1',
          amount: 25.78,
          merchant: 'WL *STEAM PURCHASE',
          category: Categoria.entretenimiento,
          source: PaymentSource.tarjeta,
          date: DateTime(2026, 11, 23, 14, 5),
          tipo: TipoMovimiento.gasto,
          canal: CanalMovimiento.notificacion,
          estado: EstadoMovimiento.confirmado,
        ));
    expect(find.textContaining('Último aviso registrado: 23 nov, 14:05'), findsOneWidget);
  });

  testWidgets('Cerrar vuelve a la pantalla anterior', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('ajustes'), findsOneWidget);
  });
}
