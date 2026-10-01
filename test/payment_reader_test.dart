import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/payment_reader.dart';

/// Textos con el formato de las notificaciones de Yape, Plin y Google Wallet.
/// Cuando se reúnan las notificaciones reales de la fase 0 del plan, se suman
/// aquí sin cambiar el código.
void main() {
  late PaymentReader reader;

  setUpAll(() {
    reader = PaymentReader.fromJson(
        File('assets/reader_rules.json').readAsStringSync());
  });

  ParsedPayment? read(String text) => reader.parse(text);

  group('gastos', () {
    test('Yapeaste a un comercio', () {
      final p = read('Yapeaste S/ 25.50 a Tambo')!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 25.5);
      expect(p.peer, 'Tambo');
      expect(p.provider, 'yape');
    });

    test('Pagaste con Google Wallet', () {
      final p = read('Google Wallet Compra por S/ 95.00 en Saga Falabella')!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 95.0);
      expect(p.peer, 'Saga Falabella');
      expect(p.provider, 'googlePay');
    });

    test('Google Wallet sin verbo se toma como gasto', () {
      final p = read('Google Pay S/ 8.90 Oxxo')!;
      expect(p.isIncome, isFalse);
      expect(p.provider, 'googlePay');
    });

    test('el comercio no arrastra "con Google Wallet"', () {
      final p = read('Compra por S/ 89.20 en Metro con Google Wallet')!;
      expect(p.peer, 'Metro');
      expect(p.provider, 'googlePay');
    });

    test('notificación real de Yape: pago recibido', () {
      const t = 'Yape! MICHAEL ANTHONY VALDIVIEZO MAZA te envió un pago por S/ 1';
      final p = read('Confirmación de Pago $t $t')!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 1.0);
      expect(p.provider, 'yape');
      expect(p.peer, 'MICHAEL ANTHONY VALDIVIEZO MAZA');
    });

    test('constancia real de Yape al enviar: el nombre va después del monto', () {
      final p = read('¡Yapeaste! S/ 1 Michael Anthony Valdiviezo Maza 01 oct. 2026 '
          '09:48 a. m. DATOS DE LA TRANSACCIÓN Nro. de celular *** *** 277 Destino Dale')!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 1.0);
      expect(p.provider, 'yape');
      expect(p.peer, 'Michael Anthony Valdiviezo Maza');
    });

    test('constancia real de Yape al pagar un servicio: la empresa es el nombre', () {
      final p = read('¡Yapeaste el servicio! S/ 134.85 BanBif 01 oct. 2026 12:36 p. m. '
          'DATOS DE LA TRANSACCIÓN Servicio: Pago de Cuotas Prestamos Código de cliente: '
          '73654903 Titular: VALDIVIEZO MAZ* Nº de operación: 05205445')!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 134.85);
      expect(p.provider, 'yape');
      expect(p.peer, 'BanBif');
    });

    test('Plin enviado', () {
      final p = read('Plin: enviaste S/ 37.00 a Cineplanet')!;
      expect(p.isIncome, isFalse);
      expect(p.provider, 'plin');
      expect(p.peer, 'Cineplanet');
    });
  });

  group('ingresos', () {
    test('"Juan te yapeó" es ingreso, no gasto', () {
      final p = read('Juan Pérez te yapeó S/ 15.00')!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 15.0);
      expect(p.peer, 'Juan Pérez');
    });

    test('"Recibiste ... de" es ingreso', () {
      final p = read('Yape: Recibiste S/ 12.50 de KFC')!;
      expect(p.isIncome, isTrue);
      expect(p.peer, 'KFC');
    });

    test('"Has recibido un Yape de"', () {
      final p = read('Has recibido un Yape de María López por S/ 40.00')!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 40.0);
      expect(p.peer, 'María López');
    });

    test('Plin recibido', () {
      final p = read('Te plineó Carlos Ruiz S/ 85.00 · Plin')!;
      expect(p.isIncome, isTrue);
      expect(p.provider, 'plin');
    });
  });

  group('montos', () {
    test('miles con coma y decimales con punto', () {
      expect(read('Yapeaste S/ 1,200.50 a Wong')!.amount, 1200.5);
    });

    test('decimal con coma', () {
      expect(read('Yapeaste S/ 12,50 a Wong')!.amount, 12.5);
    });

    test('sin decimales', () {
      expect(read('Yapeaste S/ 30 a Wong')!.amount, 30.0);
    });
  });

  group('no se inventa nada', () {
    test('texto de otra app', () {
      expect(read('Tu pedido llegó. Total S/ 20.00'), isNull);
    });

    test('Yape sin monto', () {
      expect(read('Yape: tienes una nueva promoción'), isNull);
    });

    test('Yape con monto pero sin saber si entra o sale', () {
      expect(read('Yape S/ 20.00'), isNull);
    });

    test('"explin" no cuenta como Plin', () {
      expect(read('Explin S/ 20.00 pagaste'), isNull);
    });
  });

  group('número de operación', () {
    final rules = jsonDecode(File('assets/reader_rules.json').readAsStringSync()) as Map<String, dynamic>;
    final regex = RegExp(rules['operationId'] as String, caseSensitive: false);

    String? op(String text) => regex.firstMatch(text)?.group(1);

    test('lo toma de las constancias reales de Yape', () {
      expect(op('DATOS DE LA TRANSACCIÓN Nro. de celular *** *** 277 Destino Dale Nro. de operación 01614398 Más en Yape'),
          '01614398');
      expect(op('Titular: VALDIVIEZO MAZ* Nº de operación: 05205445 Yapear otro servicio'), '05205445');
    });

    test('la fecha y hora de la constancia identifican el pago si falta el número', () {
      final stamp = RegExp(rules['operationStamp'] as String, caseSensitive: false, unicode: true);
      expect(stamp.firstMatch('¡Yapeaste! S/ 1 Michael 01 oct. 2026 09:48 a. m. DATOS')?.group(0),
          '01 oct. 2026 09:48 a. m.');
      expect(stamp.firstMatch('S/ 134.85 BanBif 01 oct. 2026 12:36 p. m. DATOS')?.group(0),
          '01 oct. 2026 12:36 p. m.');
      expect(stamp.hasMatch('Yape! MICHAEL te envió un pago por S/ 1'), isFalse);
    });

    test('un texto sin número de operación no inventa uno', () {
      expect(op('Yape! MICHAEL te envió un pago por S/ 1'), isNull);
      expect(op('Código de cliente: 73654903'), isNull);
    });
  });
}
