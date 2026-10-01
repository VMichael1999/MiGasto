import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/data/services/location_service.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/expenses/movement_detail_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocation implements LocationService {
  _FakeLocation(this.result);
  final LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> captureCurrent() async {
    calls++;
    return result;
  }

  @override
  Future<void> openAppSettings() async {}
}

Movimiento _gasto({bool located = false, EstadoMovimiento estado = EstadoMovimiento.confirmado}) =>
    Movimiento(
      id: 'g1',
      amount: 25.5,
      merchant: 'Tambo',
      category: Categoria.compras,
      source: PaymentSource.tarjeta,
      date: DateTime(2026, 9, 27, 12, 41),
      canal: CanalMovimiento.wallet,
      estado: estado,
      tarjeta: 'Visa BBVA ···4821',
      latitud: located ? -12.09 : null,
      longitud: located ? -77.03 : null,
      precision: located ? 15 : null,
      lugar: located ? 'Av. Arequipa 3120, San Isidro' : null,
      textoOriginal: 'Compra por S/ 25.50 en Tambo',
    );

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  Future<ProviderContainer> open(
    WidgetTester tester, {
    required Movimiento movimiento,
    LocationService? location,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (location != null) locationServiceProvider.overrideWithValue(location),
    ]);
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);
    await container.read(expenseRepositoryProvider).saveExpense(movimiento);
    await container.read(expensesStateProvider.notifier).restoreExpense(movimiento);

    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/movement/g1',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/movement/:id',
          builder: (_, state) => MovementDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('agrega la ubicación al tocar el botón', (tester) async {
    final fake = _FakeLocation(const LocationResult.ok(CapturedLocation(
      latitude: -12.09,
      longitude: -77.03,
      accuracy: 15,
      place: 'Av. Arequipa 3120, San Isidro',
    )));
    final c = await open(tester, movimiento: _gasto(), location: fake);

    expect(find.text('Agregar ubicación'), findsOneWidget);
    await tester.tap(find.text('Agregar ubicación'));
    await tester.pumpAndSettle();

    expect(fake.calls, 1);
    final saved = c.read(expensesStateProvider).single;
    expect(saved.tieneUbicacion, isTrue);
    expect(saved.lugar, 'Av. Arequipa 3120, San Isidro');
    expect(find.text('Av. Arequipa 3120, San Isidro'), findsOneWidget);
    expect(find.textContaining('precisión ±15 m'), findsOneWidget);
  });

  testWidgets('si el permiso se niega no guarda nada y explica por qué', (tester) async {
    final fake = _FakeLocation(const LocationResult.failed(LocationFailure.denied));
    final c = await open(tester, movimiento: _gasto(), location: fake);

    await tester.tap(find.text('Agregar ubicación'));
    await tester.pumpAndSettle();

    expect(c.read(expensesStateProvider).single.tieneUbicacion, isFalse);
    expect(find.textContaining('Sin el permiso de ubicación'), findsOneWidget);
  });

  testWidgets('quita la ubicación de un solo gasto', (tester) async {
    final c = await open(tester, movimiento: _gasto(located: true));

    await tester.tap(find.text('Quitar la ubicación de este gasto'));
    await tester.pumpAndSettle();

    final saved = c.read(expensesStateProvider).single;
    expect(saved.tieneUbicacion, isFalse);
    expect(saved.lugar, isNull);
    expect(find.text('Agregar ubicación'), findsOneWidget);
  });

  testWidgets('muestra cómo se registró, la tarjeta y el texto original', (tester) async {
    await open(tester, movimiento: _gasto());
    expect(find.text('Automático, desde Wallet'), findsOneWidget);
    expect(find.text('Tarjeta · Visa BBVA ···4821'), findsOneWidget);
    expect(find.text('Texto original'), findsOneWidget);
  });

  testWidgets('un movimiento pendiente se confirma desde el detalle', (tester) async {
    final c = await open(tester, movimiento: _gasto(estado: EstadoMovimiento.pendiente));
    expect(find.text('Por confirmar'), findsOneWidget);

    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(c.read(expensesStateProvider).single.isConfirmed, isTrue);
  });

  test('borrar todas las ubicaciones conserva los movimientos', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final notifier = c.read(expensesStateProvider.notifier);
    await notifier.restoreExpense(_gasto(located: true));
    await notifier.clearAllLocations();

    final list = c.read(expensesStateProvider);
    expect(list, hasLength(1));
    expect(list.single.tieneUbicacion, isFalse);
    expect(list.single.lugar, isNull);
  });
}
