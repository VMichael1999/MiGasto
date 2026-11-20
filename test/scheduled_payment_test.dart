import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/domain/scheduled_payment.dart';

ScheduledPayment _p(String id, DateTime due, {bool monthly = false, bool ingreso = false}) =>
    ScheduledPayment(
      id: id,
      name: id,
      amount: 10,
      tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      category: ingreso ? Categoria.sueldo : Categoria.servicios,
      dueDate: due,
      monthly: monthly,
    );

void main() {
  final now = DateTime(2026, 11, 20, 15);

  test('addMonths ajusta el día al último del mes más corto', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29)); // bisiesto
    expect(addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
    expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
  });

  test('vencido es solo si la fecha ya pasó; hoy todavía no', () {
    expect(_p('a', DateTime(2026, 11, 19)).isOverdue(now), isTrue);
    expect(_p('b', DateTime(2026, 11, 20)).isOverdue(now), isFalse);
    expect(_p('c', DateTime(2026, 11, 21)).isOverdue(now), isFalse);
  });

  test('los próximos incluyen vencidos y los de 30 días, en orden, sin los lejanos', () {
    final all = [
      _p('lejano', DateTime(2027, 1, 20)),
      _p('en10', DateTime(2026, 11, 30)),
      _p('vencido', DateTime(2026, 11, 10)),
      _p('en30', DateTime(2026, 12, 20)),
      _p('en31', DateTime(2026, 12, 21)),
    ];
    final up = upcomingPayments(all, now);
    expect(up.map((p) => p.id), ['vencido', 'en10', 'en30']);
  });

  test('nextMonth conserva todo y mueve la fecha un mes', () {
    final p = _p('x', DateTime(2026, 11, 14), monthly: true).nextMonth();
    expect(p.dueDate, DateTime(2026, 12, 14));
    expect(p.monthly, isTrue);
    expect(p.id, 'x');
  });

  test('ida y vuelta por JSON; un JSON dañado se descarta', () {
    final p = _p('x', DateTime(2026, 11, 14, 18), monthly: true, ingreso: true);
    final back = ScheduledPayment.fromJson(p.toJson())!;
    expect(back.name, 'x');
    expect(back.esIngreso, isTrue);
    expect(back.dueDate, DateTime(2026, 11, 14));
    expect(back.monthly, isTrue);
    expect(ScheduledPayment.fromJson({'id': 1}), isNull);
  });
}
