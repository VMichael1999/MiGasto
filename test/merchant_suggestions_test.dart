import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/shared/labels.dart';
import 'package:mi_gasto/shared/merchant_suggestions.dart';

void main() {
  var n = 0;
  Movimiento mov(String merchant, {int day = 1, TipoMovimiento tipo = TipoMovimiento.gasto,
      Categoria category = Categoria.compras}) =>
      Movimiento(
        id: '${n++}',
        amount: 10,
        merchant: merchant,
        category: category,
        source: PaymentSource.efectivo,
        date: DateTime(2026, 11, day),
        tipo: tipo,
      );

  List<String> names(List<MerchantSuggestion> l) => [for (final s in l) s.name];

  test('los más usados primero y, a igual cantidad, los más recientes', () {
    final all = [mov('Tambo', day: 1), mov('Uber', day: 3), mov('Tambo', day: 2), mov('Rappi', day: 5)];
    expect(names(merchantSuggestions(all, tipo: TipoMovimiento.gasto)), ['Tambo', 'Rappi', 'Uber']);
  });

  test('busca sin importar mayúsculas ni tildes y no repite lo ya escrito', () {
    final all = [mov('Café Bisetti'), mov('Cafetería Central'), mov('Tambo')];
    expect(names(merchantSuggestions(all, tipo: TipoMovimiento.gasto, query: 'CAFE')),
        containsAll(['Café Bisetti', 'Cafetería Central']));
    expect(merchantSuggestions(all, tipo: TipoMovimiento.gasto, query: 'tambo'), isEmpty);
  });

  test('un mismo comercio escrito distinto se sugiere una vez, como la última vez', () {
    final all = [mov('tambo ', day: 1), mov('Tambo', day: 9)];
    expect(names(merchantSuggestions(all, tipo: TipoMovimiento.gasto)), ['Tambo']);
  });

  test('gastos e ingresos van aparte, y no se sugieren los nombres automáticos', () {
    final all = [
      mov('Ana Pérez', tipo: TipoMovimiento.ingreso, category: Categoria.transferenciaRecibida),
      mov(categoryLabel(Categoria.compras)),
      mov('Desconocido'),
      mov('Tambo'),
    ];
    expect(names(merchantSuggestions(all, tipo: TipoMovimiento.gasto)), ['Tambo']);
    expect(names(merchantSuggestions(all, tipo: TipoMovimiento.ingreso)), ['Ana Pérez']);
  });

  test('respeta el límite', () {
    final all = [for (var i = 0; i < 10; i++) mov('Comercio $i', day: i + 1)];
    expect(merchantSuggestions(all, tipo: TipoMovimiento.gasto, limit: 3), hasLength(3));
  });
}
