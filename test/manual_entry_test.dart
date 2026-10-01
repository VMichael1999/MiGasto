import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/expenses/manual_entry_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('registra un ingreso manual con el teclado numérico', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => context.push('/new'), child: const Text('abrir')),
          ),
        ),
      ),
      GoRoute(path: '/new', builder: (_, __) => const ManualEntryScreen()),
    ]);

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin monto ni detalle no se puede guardar.
    expect(find.text('Guardar gasto'), findsOneWidget);

    await tester.tap(find.text('Ingreso'));
    await tester.pump();
    for (final k in ['1', '8', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    expect(find.textContaining('180.00', findRichText: true), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Venta de bicicleta');
    await tester.pump();
    await tester.tap(find.text('Venta'));
    await tester.pump();
    expect(find.text('Guardar ingreso · S/ 180.00'), findsOneWidget);

    await tester.tap(find.text('Guardar ingreso · S/ 180.00'));
    await tester.pumpAndSettle();

    final saved = container.read(expensesStateProvider).single;
    expect(saved.tipo, TipoMovimiento.ingreso);
    expect(saved.amount, 180.0);
    expect(saved.merchant, 'Venta de bicicleta');
    expect(saved.category, Categoria.venta);
    expect(saved.estado, EstadoMovimiento.confirmado);
    expect(saved.canal, CanalMovimiento.manual);
    expect(find.text('Ingreso guardado'), findsOneWidget);
  });
}
