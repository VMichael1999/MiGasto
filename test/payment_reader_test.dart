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
}
