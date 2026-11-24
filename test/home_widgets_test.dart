import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/navigation/navigation.dart';
import 'package:mi_gasto/data/services/home_widgets.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/shared/widget_snapshot.dart';

Movimiento _m(
  String merchant,
  double amount,
  DateTime date, {
  bool ingreso = false,
  bool pendiente = false,
  bool propia = false,
  Categoria? category,
}) =>
    Movimiento(
      id: 'id-$merchant',
      amount: amount,
      merchant: merchant,
      category: category ?? (ingreso ? Categoria.sueldo : Categoria.compras),
      source: PaymentSource.manual,
      date: date,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: pendiente ? EstadoMovimiento.pendiente : EstadoMovimiento.confirmado,
      entreMisCuentas: propia,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es', null));

  final now = DateTime(2026, 11, 24, 18);

  group('Resumen para los widgets', () {
    test('muestra las mismas cifras que Inicio', () {
      final s = WidgetSnapshot.build([
        _m('Saldo', 1000, DateTime(2026, 10, 5), ingreso: true),
        _m('Sueldo', 3500, DateTime(2026, 11, 1), ingreso: true),
        _m('Tambo', 12.5, DateTime(2026, 11, 20)),
        _m('Luz', 120, DateTime(2026, 11, 22), category: Categoria.servicios),
        // Por confirmar: no cuenta en el balance, pero se avisa.
        _m('Steam', 25.78, DateTime(2026, 11, 24), pendiente: true),
      ], now);

      expect(s['month'], 'Noviembre');
      expect(s['monthKey'], '2026-11');
      expect(s['balance'], 'S/ 4,367.50');
      expect(s['income'], 'S/ 3,500.00');
      expect(s['spent'], 'S/ 132.50');
      expect(s['percent'], 97); // 4367.5 de 4500
      expect(s['negative'], false);
      expect(s['pending'], 1);
    });

    test('los movimientos van del más reciente al más antiguo, con signo y color', () {
      final s = WidgetSnapshot.build([
        _m('Sueldo', 3500, DateTime(2026, 11, 1), ingreso: true),
        _m('Steam', 25.78, DateTime(2026, 11, 24), pendiente: true, category: Categoria.entretenimiento),
        _m('Mi otra cuenta', 50, DateTime(2026, 11, 23), propia: true),
      ], now);
      final recent = (s['recent'] as List).cast<Map<String, dynamic>>();

      expect(recent.map((r) => r['title']), ['Steam', 'Mi otra cuenta', 'Sueldo']);
      expect(recent[0]['amount'], '-S/ 25.78');
      expect(recent[0]['pending'], true);
      expect(recent[0]['color'], '#FF8A3D');
      expect(recent[0]['subtitle'], 'Entretenimiento');
      expect(recent[1]['amount'], 'S/ 50.00');
      expect(recent[1]['kind'], 'propia');
      expect(recent[1]['subtitle'], 'Entre mis cuentas');
      expect(recent[2]['amount'], '+S/ 3,500.00');
      expect(recent[2]['kind'], 'ingreso');
      expect(recent[2]['id'], 'id-Sueldo');
    });

    test('guarda hasta 6 movimientos', () {
      final many = [for (var i = 1; i <= 9; i++) _m('Gasto $i', i.toDouble(), DateTime(2026, 11, i))];
      final recent = WidgetSnapshot.build(many, now)['recent'] as List;
      expect(recent, hasLength(WidgetSnapshot.maxRecent));
      expect((recent.first as Map)['title'], 'Gasto 9');
    });

    test('un saldo negativo lleva signo y la barra queda en 0', () {
      final s = WidgetSnapshot.build([_m('Alquiler', 800, DateTime(2026, 11, 2))], now);
      expect(s['balance'], '-S/ 800.00');
      expect(s['negative'], true);
      expect(s['percent'], 0);
    });

    test('sin movimientos: todo en cero y la barra llena', () {
      final s = WidgetSnapshot.build([], now);
      expect(s['balance'], 'S/ 0.00');
      expect(s['percent'], 100);
      expect(s['recent'], isEmpty);
    });
  });

  group('Envío a los widgets', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('test/home_widgets');
    final calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'updateHomeWidgets');
        calls.add(call.arguments as String);
        return true;
      });
    });

    test('solo envía cuando cambia algo que se ve', () async {
      final widgets = HomeWidgets(channel: channel, supported: true);
      final list = [_m('Tambo', 12.5, DateTime(2026, 11, 20))];

      expect(await widgets.update(list, now), true);
      // Misma información un minuto después: no se vuelve a enviar.
      expect(await widgets.update(list, now.add(const Duration(minutes: 1))), false);
      expect(await widgets.update([...list, _m('Luz', 120, DateTime(2026, 11, 22))], now), true);

      expect(calls, hasLength(2));
      expect((jsonDecode(calls.last) as Map)['spent'], 'S/ 132.50');
    });

    test('en una plataforma sin widgets no hace nada', () async {
      final widgets = HomeWidgets(channel: channel, supported: false);
      expect(await widgets.update([], now), false);
      expect(calls, isEmpty);
    });
  });

  group('Enlaces de los widgets', () {
    test('cada enlace abre su pantalla', () {
      expect(deepLinkLocation(Uri.parse('migasto://new')), '/new');
      expect(deepLinkLocation(Uri.parse('migasto://new?type=ingreso')), '/new?type=ingreso');
      expect(deepLinkLocation(Uri.parse('migasto://movement/abc-123')), '/movement/abc-123');
      expect(deepLinkLocation(Uri.parse('migasto://movements')), '/expenses');
      expect(deepLinkLocation(Uri.parse('migasto://dashboard')), '/dashboard');
      expect(deepLinkLocation(Uri.parse('migasto://algo-raro')), '/dashboard');
    });
  });
}
