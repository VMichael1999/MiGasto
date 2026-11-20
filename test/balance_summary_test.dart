import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/balance_summary.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

Movimiento _m(double amount, DateTime date, {bool ingreso = false, bool confirmado = true}) => Movimiento(
      id: '${date.microsecondsSinceEpoch}-$amount',
      amount: amount,
      merchant: 'x',
      category: ingreso ? Categoria.sueldo : Categoria.compras,
      source: PaymentSource.manual,
      date: date,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: confirmado ? EstadoMovimiento.confirmado : EstadoMovimiento.pendiente,
    );

void main() {
  final now = DateTime(2026, 11, 20, 12);

  test('sin movimientos todo es cero', () {
    final s = computeBalanceSummary(const [], now);
    expect([s.prevBalance, s.income, s.spent, s.balance], [0, 0, 0, 0]);
  });

  test('suma el mes, arrastra el anterior y ignora pendientes y otros meses', () {
    final all = [
      _m(1000, DateTime(2026, 10, 5), ingreso: true),
      _m(300, DateTime(2026, 10, 9)),
      _m(15000, DateTime(2026, 11, 1), ingreso: true),
      _m(2000, DateTime(2026, 11, 3)),
      _m(500, DateTime(2026, 11, 4), confirmado: false), // pendiente: no cuenta
      _m(999, DateTime(2026, 9, 4), ingreso: true), // dos meses atrás: no cuenta
    ];
    final s = computeBalanceSummary(all, now);
    expect(s.prevBalance, 700);
    expect(s.income, 15000);
    expect(s.spent, 2000);
    expect(s.balance, 700 + 15000 - 2000);
  });

  test('enero mira a diciembre del año anterior', () {
    final jan = DateTime(2026, 1, 10);
    final s = computeBalanceSummary([_m(400, DateTime(2025, 12, 20), ingreso: true)], jan);
    expect(s.prevBalance, 400);
  });
}
