import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/domain/duplicate_rule.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _m({
  double amount = 25.5,
  PaymentSource source = PaymentSource.yape,
  DateTime? date,
  TipoMovimiento tipo = TipoMovimiento.gasto,
}) =>
    Movimiento(
      id: 'x',
      amount: amount,
      merchant: 'Tambo',
      category: Categoria.compras,
      source: source,
      date: date ?? DateTime(2026, 9, 27, 12, 41),
      tipo: tipo,
    );

void main() {
  group('Regla de duplicados', () {
    final base = DateTime(2026, 9, 27, 12, 41);

    test('mismo monto y fuente a 1 minuto es duplicado', () {
      expect(
        isDuplicateMovement([_m(date: base)],
            amount: 25.5,
            source: PaymentSource.yape,
            date: base.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('a más de 2 minutos no es duplicado', () {
      expect(
        isDuplicateMovement([_m(date: base)],
            amount: 25.5,
            source: PaymentSource.yape,
            date: base.add(const Duration(minutes: 3))),
        isFalse,
      );
    });

    test('otra fuente u otro monto no es duplicado', () {
      expect(
        isDuplicateMovement([_m(date: base)],
            amount: 25.5, source: PaymentSource.plin, date: base),
        isFalse,
      );
      expect(
        isDuplicateMovement([_m(date: base)],
            amount: 30, source: PaymentSource.yape, date: base),
        isFalse,
      );
    });
  });

  group('Migración de registros anteriores', () {
    test('un gasto viejo se lee como gasto confirmado por notificación', () async {
      SharedPreferences.setMockInitialValues({
        'migasto_fallback_expenses': jsonEncode([
          {
            'id': 'a',
            'amount': 25.5,
            'merchant': 'Tambo',
            'category': 'compras',
            'source': 'yape',
            'date': '2026-09-27T12:41:00.000',
            'notes': 'Yapeaste S/ 25.50 a Tambo',
            'isConfirmed': true,
          },
          {
            'id': 'b',
            'amount': 10,
            'merchant': 'Efectivo',
            'category': 'otros',
            'source': 'manual',
            'date': '2026-09-26T10:00:00.000',
            'notes': 'Registro manual',
            'isConfirmed': false,
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final list = await DatabaseManager(prefs).getExpenses();

      final a = list.firstWhere((e) => e.id == 'a');
      expect(a.tipo, TipoMovimiento.gasto);
      expect(a.estado, EstadoMovimiento.confirmado);
      expect(a.canal, CanalMovimiento.notificacion);
      expect(a.textoOriginal, 'Yapeaste S/ 25.50 a Tambo');

      final b = list.firstWhere((e) => e.id == 'b');
      expect(b.estado, EstadoMovimiento.pendiente);
      expect(b.canal, CanalMovimiento.manual);
      expect(b.textoOriginal, '');
    });

    test('los campos nuevos se guardan y se leen', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = DatabaseManager(prefs);
      await db.saveExpense(Movimiento(
        id: 'c',
        amount: 180,
        merchant: 'Venta de bicicleta',
        category: Categoria.venta,
        source: PaymentSource.yape,
        date: DateTime(2026, 9, 27, 13, 5),
        tipo: TipoMovimiento.ingreso,
        canal: CanalMovimiento.manual,
        estado: EstadoMovimiento.confirmado,
        tarjeta: 'Visa BBVA ···4821',
        latitud: -12.09,
        longitud: -77.03,
        precision: 15,
        lugar: 'Av. Arequipa 3120, San Isidro',
        textoOriginal: 'texto',
      ));
      final read = (await db.getExpenses()).single;
      expect(read.tipo, TipoMovimiento.ingreso);
      expect(read.category, Categoria.venta);
      expect(read.tarjeta, 'Visa BBVA ···4821');
      expect(read.latitud, -12.09);
      expect(read.precision, 15);
      expect(read.lugar, 'Av. Arequipa 3120, San Isidro');
    });
  });

  group('Ingresos', () {
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container.read(localDatabaseProvider).init();
      container.read(expensesStateProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() => container.dispose());

    test('un ingreso detectado queda pendiente y no cuenta como confirmado', () async {
      final notifier = container.read(expensesStateProvider.notifier);
      await notifier.triggerIncomingPayment(
        amount: 15,
        merchant: 'Juan Pérez',
        providerStr: 'yape',
        rawText: 'Juan Pérez te yapeó S/ 15.00',
        tipoStr: 'ingreso',
      );

      final list = container.read(expensesStateProvider);
      expect(list, hasLength(1));
      expect(list.single.tipo, TipoMovimiento.ingreso);
      expect(list.single.estado, EstadoMovimiento.pendiente);
      expect(list.single.category, Categoria.transferenciaRecibida);
      expect(container.read(pendingExpenseProvider), isNotNull);

      // Ignorar el aviso no lo borra: sigue en "Por confirmar".
      notifier.discardPendingExpense();
      expect(container.read(pendingExpenseProvider), isNull);
      expect(container.read(expensesStateProvider).single.isConfirmed, isFalse);

      await notifier.confirmMovimiento(list.single.id);
      expect(container.read(expensesStateProvider).single.isConfirmed, isTrue);
    });

    test('un gasto detectado no se guarda hasta confirmarlo', () async {
      final notifier = container.read(expensesStateProvider.notifier);
      await notifier.triggerIncomingPayment(
        amount: 25.5,
        merchant: 'Tambo',
        providerStr: 'yape',
        rawText: 'Yapeaste S/ 25.50 a Tambo',
      );
      expect(container.read(expensesStateProvider), isEmpty);
      expect(container.read(pendingExpenseProvider)!.tipo, TipoMovimiento.gasto);
    });

    test('el mismo pago por dos vías se registra una sola vez', () async {
      final notifier = container.read(expensesStateProvider.notifier);
      Future<void> pay() => notifier.triggerIncomingPayment(
            amount: 15,
            merchant: 'Juan Pérez',
            providerStr: 'yape',
            rawText: 'Juan Pérez te yapeó S/ 15.00',
            tipoStr: 'ingreso',
          );
      await pay();
      await pay();
      expect(container.read(expensesStateProvider), hasLength(1));
    });

    test('restoreExpense devuelve un gasto eliminado', () async {
      final notifier = container.read(expensesStateProvider.notifier);
      await notifier.addManualExpense(20, 'Menú', Categoria.alimentacion);
      final m = container.read(expensesStateProvider).single;
      await notifier.deleteExpense(m.id);
      expect(container.read(expensesStateProvider), isEmpty);
      await notifier.restoreExpense(m);
      expect(container.read(expensesStateProvider).single.id, m.id);
    });
  });
}
