import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/debug_mock_data.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  double sum(Iterable<Movimiento> l) => l.fold(0.0, (s, m) => s + m.amount);

  for (final now in [
    DateTime(2026, 11, 20, 14, 30),
    DateTime(2026, 11, 1, 0, 30), // primer día del mes, recién empezado
    DateTime(2026, 1, 3, 9), // enero: los meses anteriores cruzan de año
  ]) {
    test('el mes en curso tiene un sueldo de 15 mil y unos 7,500 de gastos ($now)', () {
      final all = buildDebugMockMovements(now);
      final month = all.where((m) => m.date.year == now.year && m.date.month == now.month);
      expect(sum(month.where((m) => m.esIngreso)), 15000);
      final gastos = sum(month.where((m) => m.esGasto));
      expect(gastos, inInclusiveRange(7400, 7600));
    });

    test('todo es del pasado, confirmado y con id de ejemplo ($now)', () {
      final all = buildDebugMockMovements(now);
      expect(all, isNotEmpty);
      for (final m in all) {
        expect(m.date.isAfter(now), isFalse, reason: '${m.merchant} ${m.date}');
        expect(m.isConfirmed, isTrue);
        expect(isDebugMockId(m.id), isTrue);
      }
      expect(all.map((m) => m.id).toSet().length, all.length);
    });
  }

  test('incluye las suscripciones y transferencias pedidas', () {
    final names = buildDebugMockMovements(DateTime(2026, 11, 20)).map((m) => m.merchant).toSet();
    expect(names, containsAll(['iCloud', 'ChatGPT Plus', 'Netflix', 'Claude Pro']));
    expect(names.any((n) => n.startsWith('Yape') || n.startsWith('Plin')), isTrue);
  });

  test('hay datos de varios meses para las gráficas', () {
    final all = buildDebugMockMovements(DateTime(2026, 11, 20));
    final months = all.map((m) => '${m.date.year}-${m.date.month}').toSet();
    expect(months.length, 4);
  });
}
