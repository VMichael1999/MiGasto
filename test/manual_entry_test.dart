import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/expenses/manual_entry_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/shared/labels.dart';
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
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => context.push('/new'), child: const Text('abrir')),
          ),
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (_, _) => const ManualEntryScreen(initialType: TipoMovimiento.ingreso),
      ),
    ]);

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin monto no se puede guardar: el botón no muestra importe.
    expect(find.text('Guardar'), findsWidgets);
    expect(find.textContaining('Guardar ·'), findsNothing);

    for (final k in ['1', '8', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    expect(find.textContaining('180.00', findRichText: true), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Venta de bicicleta');
    await tester.pump();
    await tester.tap(find.text(categoryLabel(Categoria.otrosIngresos)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(categoryLabel(Categoria.venta)).last);
    await tester.pumpAndSettle();
    expect(find.text('Guardar · S/ 180.00'), findsOneWidget);

    await tester.tap(find.text('Guardar · S/ 180.00'));
    await tester.pumpAndSettle();

    final saved = container.read(expensesStateProvider).single;
    expect(saved.tipo, TipoMovimiento.ingreso);
    expect(saved.amount, 180.0);
    expect(saved.merchant, 'Venta de bicicleta');
    expect(saved.category, Categoria.venta);
    expect(saved.estado, EstadoMovimiento.confirmado);
    expect(saved.canal, CanalMovimiento.manual);
    expect(find.textContaining('Ingreso de S/ 180.00 guardado'), findsOneWidget);
  });

  testWidgets('el campo Comercio sugiere los comercios ya usados y se guarda con el elegido',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(expensesStateProvider.notifier);
    for (final m in ['Tambo', 'Tambo', 'Uber']) {
      await notifier.addManualMovimiento(
          tipo: TipoMovimiento.gasto, amount: 5, merchant: m, category: Categoria.compras);
    }

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => context.push('/new'), child: const Text('abrir')),
          ),
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (_, _) => const ManualEntryScreen(initialType: TipoMovimiento.gasto),
      ),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comercio', findRichText: true), findsWidgets);
    expect(find.text('Tambo'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);

    // Al escribir solo quedan los que coinciden.
    await tester.enterText(find.byType(TextField), 'tam');
    await tester.pump();
    expect(find.text('Uber'), findsNothing);

    await tester.tap(find.text('Tambo'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Tambo'), findsOneWidget);

    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.tap(find.text('Guardar · S/ 2.00'));
    await tester.pumpAndSettle();
    final saved = container.read(expensesStateProvider).first;
    expect(saved.merchant, 'Tambo');
    expect(saved.amount, 2.0);
  });
}
