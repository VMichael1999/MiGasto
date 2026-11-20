import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/balance_projection.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

Movimiento _m(String id, double amount, DateTime date, {bool ingreso = false}) => Movimiento(
      id: id,
      amount: amount,
      merchant: 'x',
      category: ingreso ? Categoria.otrosIngresos : Categoria.compras,
      source: PaymentSource.manual,
      date: date,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
    );

void main() {
  final now = DateTime(2026, 11, 20, 12);

  test('con menos de 3 movimientos no hay estimación', () {
    final r = projectBalance(
      movements: [_m('a', 10, now), _m('b', 20, now)],
      currentBalance: 100,
      now: now,
    );
    expect(r, isNull);
  });

  test('sin movimientos tampoco', () {
    expect(projectBalance(movements: const [], currentBalance: 0, now: now), isNull);
  });

  test('proyecta el ritmo neto diario de los últimos 30 días', () {
    // 10 días: +1000 de ingreso y -300 de gasto → neto +700 en 10 días = 70 al día.
    final start = DateTime(2026, 11, 11, 9);
    final movs = [
      _m('i', 1000, start, ingreso: true),
      _m('g1', 100, start.add(const Duration(days: 3))),
      _m('g2', 200, start.add(const Duration(days: 9))),
    ];
    final r = projectBalance(movements: movs, currentBalance: 500, now: now)!;
    expect(r.dailyNet, closeTo(70, 0.001));
    expect(r.projected, closeTo(500 + 70 * 30, 0.001));
  });

  test('un ritmo negativo baja el saldo estimado', () {
    final start = DateTime(2026, 11, 1, 9);
    final movs = [
      _m('a', 100, start),
      _m('b', 100, start.add(const Duration(days: 5))),
      _m('c', 100, start.add(const Duration(days: 10))),
    ];
    final r = projectBalance(movements: movs, currentBalance: 200, now: now)!;
    expect(r.dailyNet, lessThan(0));
    expect(r.projected, lessThan(200));
  });

  test('ignora movimientos pendientes y fuera de los últimos 30 días', () {
    final old = now.subtract(const Duration(days: 45));
    final movs = [_m('a', 10, old), _m('b', 10, old), _m('c', 10, old)];
    expect(projectBalance(movements: movs, currentBalance: 0, now: now), isNull);
  });

  test('un solo día movido no dispara la estimación (mínimo 7 días)', () {
    final movs = [
      _m('i', 700, now, ingreso: true),
      _m('a', 10, now),
      _m('b', 10, now),
    ];
    final r = projectBalance(movements: movs, currentBalance: 0, now: now)!;
    expect(r.dailyNet, closeTo(680 / 7, 0.001));
  });
}
