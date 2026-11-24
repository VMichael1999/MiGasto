import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/payment_reader.dart';
import 'package:mi_gasto/domain/balance_summary.dart';
import 'package:mi_gasto/domain/cuentas_propias.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  group('el nombre del pago es el del perfil', () {
    test('nombre completo del banco y perfil más corto', () {
      expect(esMismoTitular('MICHAEL ANTHONY VALDIVIEZO MAZA', 'Michael Valdiviezo'), isTrue);
    });

    test('nombre recortado con asterisco, como lo escribe Yape', () {
      expect(esMismoTitular('Michael Valdiviezo M*', 'Michael Anthony Valdiviezo Maza'), isTrue);
    });

    test('tildes y mayúsculas no importan', () {
      expect(esMismoTitular('JOSÉ PÉREZ', 'Jose Perez'), isTrue);
    });

    test('otra persona con el mismo nombre de pila no es el usuario', () {
      expect(esMismoTitular('Michael Torres', 'Michael Valdiviezo'), isFalse);
    });

    test('con un perfil de una sola palabra no se adivina', () {
      expect(esMismoTitular('Michael Valdiviezo', 'Michael'), isFalse);
      expect(esMismoTitular('Michael Valdiviezo', ''), isFalse);
    });

    test('un comercio no es el usuario', () {
      expect(esMismoTitular('Tambo', 'Michael Valdiviezo'), isFalse);
    });
  });

  group('el texto dice que fue a otra cuenta tuya', () {
    late PaymentReader reader;
    setUpAll(() => reader = PaymentReader.fromJson(File('assets/reader_rules.json').readAsStringSync()));

    test('se reconoce', () {
      expect(reader.isOwnTransfer('Yapeaste S/ 100 a tu cuenta BCP'), isTrue);
      expect(reader.isOwnTransfer('Transferencia entre tus cuentas por S/ 300'), isTrue);
      expect(reader.isOwnTransfer('Plineaste S/ 50 a tu otra cuenta'), isTrue);
    });

    test('un pago a otra persona o un abono de sueldo no lo es', () {
      expect(reader.isOwnTransfer('Yapeaste S/ 25 a Tambo'), isFalse);
      expect(reader.isOwnTransfer('Transferiste S/ 300.00 a Juan Perez desde tu cuenta de ahorros'), isFalse);
      expect(reader.isOwnTransfer('Abono a tu cuenta: S/ 3,200.00 de EMPRESA SAC'), isFalse);
    });
  });

  test('una transferencia entre mis cuentas no suma a gastos ni ingresos', () {
    final now = DateTime(2026, 11, 20, 12);
    Movimiento m(double amount, TipoMovimiento tipo, {bool propia = false}) => Movimiento(
          id: '$amount-${tipo.name}-$propia',
          amount: amount,
          merchant: 'x',
          category: tipo == TipoMovimiento.ingreso ? Categoria.otrosIngresos : Categoria.otros,
          source: PaymentSource.yape,
          date: DateTime(2026, 11, 10),
          tipo: tipo,
          estado: EstadoMovimiento.confirmado,
          entreMisCuentas: propia,
        );
    final s = computeBalanceSummary([
      m(1000, TipoMovimiento.ingreso),
      m(200, TipoMovimiento.gasto),
      m(500, TipoMovimiento.gasto, propia: true),
      m(500, TipoMovimiento.ingreso, propia: true),
    ], now);
    expect(s.income, 1000);
    expect(s.spent, 200);
  });
}
