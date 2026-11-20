import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/domain/movement_comparison.dart';

Movimiento _m(
  String id,
  String merchant,
  double amount,
  DateTime date, {
  Categoria cat = Categoria.servicios,
  bool ingreso = false,
  bool confirmado = true,
}) =>
    Movimiento(
      id: id,
      amount: amount,
      merchant: merchant,
      category: ingreso ? Categoria.sueldo : cat,
      source: PaymentSource.manual,
      date: date,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: confirmado ? EstadoMovimiento.confirmado : EstadoMovimiento.pendiente,
    );

void main() {
  test('compara con el mismo comercio: la vez anterior y los meses', () {
    final current = _m('c', 'Netflix', 44.9, DateTime(2026, 11, 20));
    final all = [
      current,
      _m('a', 'Netflix', 39.9, DateTime(2026, 10, 20)),
      _m('b', 'netflix ', 39.9, DateTime(2026, 9, 20)), // mayúsculas y espacios no importan
      _m('x', 'Spotify', 19.9, DateTime(2026, 10, 18)), // otro comercio: no cuenta
    ];
    final r = compareMovement(current, all);

    expect(r.byMerchant, isTrue);
    expect(r.previous!.id, 'a'); // la más reciente anterior
    expect(r.months.length, 4);
    expect(r.months.map((m) => m.month.month), [8, 9, 10, 11]);
    expect(r.months.map((m) => m.total), [0, 39.9, 39.9, 44.9]);
    expect(r.current.total, 44.9);
    expect(r.previousMonth!.total, 39.9);
    expect(r.monthChangePercent, closeTo((44.9 - 39.9) / 39.9 * 100, 0.001));
    expect(r.averageOfPreviousMonths, closeTo(39.9, 0.001));
    expect(r.hasHistory, isTrue);
  });

  test('sin antecedentes del comercio compara con la categoría', () {
    final current = _m('c', 'Café nuevo', 12, DateTime(2026, 11, 5), cat: Categoria.alimentacion);
    final all = [
      current,
      _m('a', 'Wong', 300, DateTime(2026, 10, 3), cat: Categoria.alimentacion),
      _m('b', 'Tottus', 100, DateTime(2026, 11, 1), cat: Categoria.alimentacion),
      _m('z', 'Uber', 50, DateTime(2026, 10, 9), cat: Categoria.transporte),
    ];
    final r = compareMovement(current, all);

    expect(r.byMerchant, isFalse);
    expect(r.previous, isNull);
    expect(r.months.map((m) => m.total), [0, 0, 300, 112]); // el propio cuenta en su mes
    expect(r.monthChangePercent, closeTo((112 - 300) / 300 * 100, 0.001));
    expect(r.hasHistory, isTrue);
  });

  test('un movimiento sin nada parecido no tiene historial', () {
    final current = _m('c', 'Único', 10, DateTime(2026, 11, 5));
    final r = compareMovement(current, [current]);
    expect(r.hasHistory, isFalse);
    expect(r.monthChangePercent, isNull);
    expect(r.averageOfPreviousMonths, isNull);
    expect(r.current.total, 10);
  });

  test('ingresos y gastos no se mezclan, y los pendientes no cuentan', () {
    final current = _m('c', 'Sueldo', 15000, DateTime(2026, 11, 1), ingreso: true);
    final all = [
      current,
      _m('g', 'Sueldo', 999, DateTime(2026, 10, 1)), // gasto con el mismo nombre
      _m('p', 'Sueldo', 14000, DateTime(2026, 10, 1), ingreso: true, confirmado: false),
      _m('o', 'Sueldo', 14500, DateTime(2026, 10, 1), ingreso: true),
    ];
    final r = compareMovement(current, all);
    expect(r.previous!.id, 'o');
    expect(r.previousMonth!.total, 14500);
  });

  test('los meses cruzan de año', () {
    final current = _m('c', 'Gym', 90, DateTime(2026, 1, 15));
    final all = [current, _m('a', 'Gym', 80, DateTime(2025, 12, 15)), _m('b', 'Gym', 70, DateTime(2025, 11, 15))];
    final r = compareMovement(current, all);
    expect(r.months.map((m) => '${m.month.year}-${m.month.month}'), ['2025-10', '2025-11', '2025-12', '2026-1']);
    expect(r.months.map((m) => m.total), [0, 70, 80, 90]);
  });
}
