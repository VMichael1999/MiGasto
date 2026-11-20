import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/domain/scheduled_payment.dart';
import 'package:mi_gasto/presentation/dashboard/dashboard_side_cards.dart';
import 'package:mi_gasto/presentation/payments/scheduled_payments_providers.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  Future<ProviderContainer> pump(WidgetTester tester, {List<ScheduledPayment> initial = const []}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);
    for (final p in initial) {
      container.read(scheduledPaymentsProvider.notifier).upsert(p);
    }
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, _) => Padding(
                padding: const EdgeInsets.all(18),
                child: ScheduledPaymentsCard(
                  payments: ref.watch(scheduledPaymentsProvider),
                  hidden: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    return container;
  }

  ScheduledPayment sp(String id, String name, double amount, int inDays,
          {bool ingreso = false, bool monthly = true}) =>
      ScheduledPayment(
        id: id,
        name: name,
        amount: amount,
        tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
        category: ingreso ? Categoria.sueldo : Categoria.servicios,
        dueDate: dateOnly(DateTime.now()).add(Duration(days: inDays)),
        monthly: monthly,
      );

  testWidgets('sin pagos la tarjeta invita a agregar uno', (tester) async {
    await pump(tester);
    expect(find.text('Próximos pagos'), findsOneWidget);
    expect(find.textContaining('Aún no tienes pagos programados'), findsOneWidget);
  });

  testWidgets('muestra vencidos en ámbar, cobros en verde y deja fuera los lejanos', (tester) async {
    await pump(tester, initial: [
      sp('a', 'iCloud', 12.9, -3),
      sp('b', 'Sueldo', 15000, 10, ingreso: true),
      sp('c', 'Netflix', 44.9, 3),
      sp('d', 'Lejano', 99, 90),
    ]);
    expect(find.text('iCloud'), findsOneWidget);
    expect(find.textContaining('Vencido'), findsOneWidget);
    expect(find.text('+S/ 15,000.00'), findsOneWidget);
    expect(find.text('−S/ 44.90'), findsOneWidget);
    expect(find.text('Lejano'), findsNothing);
  });

  testWidgets('desde la hoja: agregar un pago, marcarlo como pagado y quitarlo', (tester) async {
    final container = await pump(tester, initial: [sp('a', 'Netflix', 44.9, 2)]);

    await tester.tap(find.text('Próximos pagos'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar'), findsOneWidget);

    // Agregar uno nuevo.
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre (ej. Netflix, Alquiler)'), 'Gimnasio');
    await tester.enterText(find.widgetWithText(TextField, 'Monto'), '99.9');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final list = container.read(scheduledPaymentsProvider);
    expect(list.map((p) => p.name), containsAll(['Netflix', 'Gimnasio']));
    expect(list.firstWhere((p) => p.name == 'Gimnasio').amount, 99.9);

    // Marcar como pagado el primero de la lista (el que vence antes): registra
    // el movimiento real y lo pasa al mes siguiente.
    final before = container.read(expensesStateProvider).length;
    final first = container.read(scheduledPaymentsProvider)
        .reduce((a, b) => a.dueDate.isBefore(b.dueDate) ? a : b);
    await tester.tap(find.byTooltip('Marcar como pagado').first);
    await tester.pumpAndSettle();
    final movs = container.read(expensesStateProvider);
    expect(movs.length, before + 1);
    expect(movs.first.merchant, first.name);
    expect(movs.first.amount, first.amount);
    expect(movs.first.isConfirmed, isTrue);
    final after = container.read(scheduledPaymentsProvider).firstWhere((p) => p.id == first.id);
    expect(after.dueDate.isAfter(first.dueDate), isTrue);

    // Quitar el otro.
    await tester.tap(find.byTooltip('Quitar').last);
    await tester.pumpAndSettle();
    expect(container.read(scheduledPaymentsProvider).length, 1);
  });

  test('pagar uno que no se repite lo quita; uno mensual atrasado salta al futuro', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final n = ScheduledPaymentsNotifier(prefs);
    final now = DateTime(2026, 11, 20);
    n.upsert(ScheduledPayment(
      id: 'u', name: 'Único', amount: 10, tipo: TipoMovimiento.gasto,
      category: Categoria.otros, dueDate: DateTime(2026, 11, 25),
    ));
    n.upsert(ScheduledPayment(
      id: 'm', name: 'Mensual', amount: 10, tipo: TipoMovimiento.gasto,
      category: Categoria.otros, dueDate: DateTime(2026, 8, 14), monthly: true,
    ));
    n.settle('u', now);
    n.settle('m', now);
    expect(n.state.map((p) => p.id), ['m']);
    expect(n.state.single.dueDate, DateTime(2026, 12, 14)); // primer 14 posterior a hoy
    // Persistido en el dispositivo.
    expect(prefs.getString(keyScheduledPayments), contains('Mensual'));
  });
}
