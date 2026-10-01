import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/shared/widgets/overlay_timer_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _pending(TipoMovimiento tipo) => Movimiento(
      id: tipo.name,
      amount: 25.5,
      merchant: tipo == TipoMovimiento.gasto ? 'Tambo' : 'Juan Pérez',
      category: tipo == TipoMovimiento.gasto ? Categoria.compras : Categoria.transferenciaRecibida,
      source: PaymentSource.yape,
      date: DateTime(2026, 9, 27, 12, 41),
      tipo: tipo,
      canal: CanalMovimiento.notificacion,
      estado: EstadoMovimiento.pendiente,
    );

void main() {
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: OverlayTimerWidget(child: Text('contenido'))),
      ),
    ));
  }

  testWidgets('un gasto se guarda solo a los 4 segundos', (tester) async {
    await pumpApp(tester);
    container.read(pendingExpenseProvider.notifier).state = _pending(TipoMovimiento.gasto);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Descartar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.textContaining('Se guarda en'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    final saved = container.read(expensesStateProvider);
    expect(saved, hasLength(1));
    expect(saved.single.estado, EstadoMovimiento.confirmado);
    expect(container.read(pendingExpenseProvider), isNull);
  });

  testWidgets('tocar la ventana pausa la cuenta regresiva', (tester) async {
    await pumpApp(tester);
    container.read(pendingExpenseProvider.notifier).state = _pending(TipoMovimiento.gasto);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(const Offset(200, 120));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('En pausa'), findsWidgets);
    expect(container.read(expensesStateProvider), isEmpty);
    expect(container.read(pendingExpenseProvider), isNotNull);
  });

  testWidgets('un ingreso no se guarda solo', (tester) async {
    await pumpApp(tester);
    container.read(pendingExpenseProvider.notifier).state = _pending(TipoMovimiento.ingreso);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ignorar'), findsOneWidget);
    expect(find.text('Guardar ingreso'), findsOneWidget);
    expect(find.textContaining('No se guarda hasta que lo confirmes'), findsOneWidget);
    expect(find.textContaining('Se guarda en'), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    expect(container.read(expensesStateProvider), isEmpty);
    expect(container.read(pendingExpenseProvider), isNotNull);

    await tester.tap(find.text('Guardar ingreso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final saved = container.read(expensesStateProvider);
    expect(saved, hasLength(1));
    expect(saved.single.tipo, TipoMovimiento.ingreso);
    expect(saved.single.estado, EstadoMovimiento.confirmado);
  });
}
