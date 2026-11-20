import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/category_period.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

Movimiento _g(double amount, DateTime date) => Movimiento(
      id: '${date.microsecondsSinceEpoch}$amount',
      amount: amount,
      merchant: 'x',
      category: Categoria.servicios,
      source: PaymentSource.manual,
      date: date,
      tipo: TipoMovimiento.gasto,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
    );

void main() {
  group('periodRange', () {
    test('quincenal: del 1 al 15 y del 16 al fin de mes', () {
      final first = periodRange(DetailPeriod.quincenal, DateTime(2026, 11, 8));
      expect([first.start, first.end], [DateTime(2026, 11, 1), DateTime(2026, 11, 16)]);
      final second = periodRange(DetailPeriod.quincenal, DateTime(2026, 11, 20));
      expect([second.start, second.end], [DateTime(2026, 11, 16), DateTime(2026, 12, 1)]);
      expect(periodRange(DetailPeriod.quincenal, DateTime(2026, 11, 15)).end, DateTime(2026, 11, 16));
      expect(periodRange(DetailPeriod.quincenal, DateTime(2026, 11, 16)).start, DateTime(2026, 11, 16));
    });

    test('mensual, trimestral y semestral usan períodos del calendario', () {
      final d = DateTime(2026, 11, 20);
      expect(periodRange(DetailPeriod.mensual, d).start, DateTime(2026, 11, 1));
      expect(periodRange(DetailPeriod.mensual, d).end, DateTime(2026, 12, 1));
      expect(periodRange(DetailPeriod.trimestral, d).start, DateTime(2026, 10, 1));
      expect(periodRange(DetailPeriod.trimestral, d).end, DateTime(2027, 1, 1));
      expect(periodRange(DetailPeriod.trimestral, DateTime(2026, 2, 1)).start, DateTime(2026, 1, 1));
      expect(periodRange(DetailPeriod.semestral, d).start, DateTime(2026, 7, 1));
      expect(periodRange(DetailPeriod.semestral, d).end, DateTime(2027, 1, 1));
      expect(periodRange(DetailPeriod.semestral, DateTime(2026, 6, 30)).start, DateTime(2026, 1, 1));
    });

    test('un mes de febrero bisiesto termina el 1 de marzo', () {
      expect(periodRange(DetailPeriod.mensual, DateTime(2028, 2, 10)).end, DateTime(2028, 3, 1));
    });
  });

  test('shiftAnchor mueve al período anterior o siguiente, cruzando años', () {
    final q = DetailPeriod.quincenal;
    var a = shiftAnchor(q, DateTime(2026, 11, 20), -1);
    expect(periodRange(q, a).start, DateTime(2026, 11, 1));
    a = shiftAnchor(q, DateTime(2026, 11, 3), -1);
    expect(periodRange(q, a).start, DateTime(2026, 10, 16));
    a = shiftAnchor(DetailPeriod.mensual, DateTime(2026, 1, 10), -1);
    expect(periodRange(DetailPeriod.mensual, a).start, DateTime(2025, 12, 1));
    a = shiftAnchor(DetailPeriod.semestral, DateTime(2026, 8, 1), 1);
    expect(periodRange(DetailPeriod.semestral, a).start, DateTime(2027, 1, 1));
    a = shiftAnchor(DetailPeriod.trimestral, DateTime(2026, 10, 1), -1);
    expect(periodRange(DetailPeriod.trimestral, a).start, DateTime(2026, 7, 1));
  });

  group('evolutionBuckets', () {
    test('un mes se reparte en semanas y suma lo de cada tramo', () {
      final r = periodRange(DetailPeriod.mensual, DateTime(2026, 11, 20));
      final b = evolutionBuckets(
        [_g(10, DateTime(2026, 11, 1)), _g(20, DateTime(2026, 11, 7, 23)), _g(5, DateTime(2026, 11, 8)), _g(7, DateTime(2026, 11, 30))],
        r,
        DetailPeriod.mensual,
      );
      expect(b.length, 5); // 1-7, 8-14, 15-21, 22-28, 29-30
      expect(b.map((e) => e.total), [30, 5, 0, 0, 7]);
      expect(b.last.end, DateTime(2026, 12, 1)); // el último tramo no pasa del fin del período
    });

    test('una quincena en tramos de 3 días', () {
      final r = periodRange(DetailPeriod.quincenal, DateTime(2026, 11, 5));
      final b = evolutionBuckets([_g(4, DateTime(2026, 11, 15))], r, DetailPeriod.quincenal);
      expect(b.length, 5);
      expect(b.last.total, 4);
      expect(b.last.end, DateTime(2026, 11, 16));
    });

    test('trimestre y semestre: un tramo por mes', () {
      final tri = evolutionBuckets(const [], periodRange(DetailPeriod.trimestral, DateTime(2026, 11, 1)), DetailPeriod.trimestral);
      expect(tri.length, 3);
      final sem = evolutionBuckets([_g(9, DateTime(2026, 9, 10))], periodRange(DetailPeriod.semestral, DateTime(2026, 9, 1)), DetailPeriod.semestral);
      expect(sem.length, 6);
      expect(sem[2].total, 9); // septiembre es el tercer mes del semestre jul–dic
    });
  });

  test('categoryShare', () {
    expect(categoryShare(41, 100), 41);
    expect(categoryShare(0, 0), isNull);
  });
}
