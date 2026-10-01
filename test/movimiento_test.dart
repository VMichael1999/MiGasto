import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/domain/duplicate_rule.dart';
import 'package:mi_gasto/data/services/nlp_classifier_service.dart';
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
  setUpAll(() {
    NlpClassifierService.configure(
        File('assets/category_rules.json').readAsStringSync());
  });

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

    test('apagado por defecto: el interruptor de ingresos automáticos', () {
      expect(container.read(autoSaveIncomeProvider), isFalse);
    });

    test('con "Guardar ingresos automáticamente" el ingreso queda confirmado', () async {
      container.read(autoSaveIncomeProvider.notifier).set(true);
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
      expect(list.single.estado, EstadoMovimiento.confirmado);
      expect(container.read(pendingExpenseProvider), isNull);
      // Y la preferencia llega a la clave que lee el código nativo.
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool(keyAutoSaveIncome), isTrue);
    });

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

  group('Cola nativa', () {
    const channel = MethodChannel('com.example.mi_gasto/accessibility');

    Future<ProviderContainer> containerWithQueue(String? queueJson) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'takeNativeQueue') return queueJson;
        return null;
      });
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await c.read(localDatabaseProvider).init();
      c.read(expensesStateProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      return c;
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('guarda los pagos detectados con la app cerrada', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c = await containerWithQueue(jsonEncode([
        {
          'amount': 25.5,
          'peer': 'Tambo',
          'provider': 'yape',
          'type': 'gasto',
          'rawText': 'Yapeaste S/ 25.50 a Tambo',
          'confirmed': true,
          'at': now,
        },
        {
          'amount': 15,
          'peer': 'Juan Pérez',
          'provider': 'yape',
          'type': 'ingreso',
          'rawText': 'Juan Pérez te yapeó S/ 15.00',
          'confirmed': false,
          'at': now,
        },
        // El mismo gasto llegó dos veces.
        {
          'amount': 25.5,
          'peer': 'Tambo',
          'provider': 'yape',
          'type': 'gasto',
          'rawText': 'Yapeaste S/ 25.50 a Tambo',
          'confirmed': true,
          'at': now + 5000,
        },
      ]));
      addTearDown(c.dispose);

      final list = c.read(expensesStateProvider);
      expect(list, hasLength(2));

      final gasto = list.firstWhere((m) => m.esGasto);
      expect(gasto.estado, EstadoMovimiento.confirmado);
      expect(gasto.category, Categoria.compras);
      expect(gasto.canal, CanalMovimiento.notificacion);
      expect(gasto.textoOriginal, 'Yapeaste S/ 25.50 a Tambo');

      final ingreso = list.firstWhere((m) => m.esIngreso);
      expect(ingreso.estado, EstadoMovimiento.pendiente);
      expect(ingreso.category, Categoria.transferenciaRecibida);
    });

    Map<String, dynamic> pendingIncome(String id, int at) => {
          'id': id,
          'amount': 15,
          'peer': 'Juan Pérez',
          'provider': 'yape',
          'type': 'ingreso',
          'rawText': 'Juan Pérez te yapeó S/ 15.00',
          'confirmed': false,
          'at': at,
        };

    test('«Guardar» del aviso confirma el ingreso pendiente', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c = await containerWithQueue(jsonEncode([
        pendingIncome('ref-1', now),
        {'action': 'confirm', 'id': 'ref-1', 'at': now + 1000},
      ]));
      addTearDown(c.dispose);

      final list = c.read(expensesStateProvider);
      expect(list, hasLength(1));
      expect(list.single.id, 'ref-1');
      expect(list.single.estado, EstadoMovimiento.confirmado);
    });

    test('«Ignorar» del aviso descarta el ingreso pendiente', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c = await containerWithQueue(jsonEncode([
        pendingIncome('ref-2', now),
        {'action': 'discard', 'id': 'ref-2', 'at': now + 1000},
      ]));
      addTearDown(c.dispose);

      expect(c.read(expensesStateProvider), isEmpty);
    });

    test('una orden del aviso para un movimiento que ya no existe no hace nada', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final c = await containerWithQueue(jsonEncode([
        {'action': 'confirm', 'id': 'no-existe', 'at': now},
        {'action': 'discard', 'id': 'no-existe', 'at': now},
      ]));
      addTearDown(c.dispose);

      expect(c.read(expensesStateProvider), isEmpty);
    });

    test('un pago de Apple Pay guarda tarjeta, canal Wallet y ubicación', () async {
      final c = await containerWithQueue(jsonEncode([
        {
          'amount': 25.5,
          'peer': 'Tambo',
          'provider': 'tarjeta',
          'type': 'gasto',
          'channel': 'wallet',
          'card': 'Visa BBVA ···4821',
          'latitude': -12.0914,
          'longitude': -77.0292,
          'rawText': 'Apple Pay: S/ 25.50 en Tambo',
          'confirmed': true,
          'at': DateTime.now().millisecondsSinceEpoch,
        },
      ]));
      addTearDown(c.dispose);

      final m = c.read(expensesStateProvider).single;
      expect(m.source, PaymentSource.tarjeta);
      expect(m.canal, CanalMovimiento.wallet);
      expect(m.tarjeta, 'Visa BBVA ···4821');
      expect(m.tieneUbicacion, isTrue);
      expect(m.estado, EstadoMovimiento.confirmado);
      expect(m.category, Categoria.compras);
    });

    test('una cola vacía no hace nada', () async {
      final c = await containerWithQueue('[]');
      addTearDown(c.dispose);
      expect(c.read(expensesStateProvider), isEmpty);
    });
  });
}
