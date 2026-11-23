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

  // Textos reales capturados en teléfonos (ver docs/investigacion-notificaciones-pagos.md).
  group('la app que avisa da la fuente', () {
    const yapeApp = 'com.bcp.innovacxion.yapeapp';

    test('yape recibido con código de seguridad, que no dice «Yape»', () {
      const text = 'Confirmación de Pago Sasha Sal* te envió un pago por S/ 5.5. El cód. de seguridad es: 667';
      final p = reader.parse(text, app: yapeApp)!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 5.5);
      expect(p.peer, 'Sasha Sal');
      expect(p.provider, 'yape');
      // Sin saber de qué app vino no se adivina la fuente.
      expect(reader.parse(text), isNull);
    });

    test('la publicidad de Yape no es un pago', () {
      expect(reader.parse('¡Suerte asegurada!🍀 Gana hasta S/3,000 afiliándote a Dinero Más Seguro🔒¡Todos ganan!',
          app: yapeApp), isNull);
      expect(reader.parse('Tu dinero seguro a S/ 4.99 al mes💜 Protege tus cuentas Yape y BCP y participa por S/5,000. T&C.',
          app: yapeApp), isNull);
    });

    test('una app de banco no impone fuente: el texto decide', () {
      expect(reader.parse('Interbank Ingresaste a tu Banca por Internet.', app: 'pe.com.interbank.mobilebanking'),
          isNull);
    });

    test('las apps escuchadas son paquetes de Perú, sin los equivocados', () {
      final rules = jsonDecode(File('assets/reader_rules.json').readAsStringSync()) as Map<String, dynamic>;
      final apps = (rules['apps'] as List).cast<String>();
      expect(apps, containsAll(['com.bcp.innovacxion.yapeapp', 'com.bcp.bank.bcp', 'com.bbva.nxt_peru',
          'pe.com.interbank.mobilebanking', 'pe.com.scotiabank.blpm.android.client', 'pe.com.banbif.pnappmobile']));
      // com.bbva.bbvacontigo es BBVA España y com.banbif.plin no existe.
      expect(apps, isNot(contains('com.bbva.bbvacontigo')));
      expect(apps, isNot(contains('com.banbif.plin')));
      expect((rules['providerByApp'] as Map).keys, everyElement(isIn(apps)));
    });
  });

  group('Plin en las apps de los bancos', () {
    const bbva = 'com.bbva.nxt_peru';
    const interbank = 'pe.com.interbank.mobilebanking';

    test('BBVA: Plin recibido, con emoji y «S/1 .»', () {
      final p = reader.parse('¡Recibiste un Plin! 💸 ADRIAN ISSAC MAMANI te plineó S/1 .', app: bbva)!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 1.0);
      expect(p.peer, 'ADRIAN ISSAC MAMANI');
      expect(p.provider, 'plin');
    });

    test('BBVA: Plin enviado', () {
      final p = reader.parse('¡Enviaste un Plin! Plineaste S/1 a Adrian I Mamani Q .', app: bbva)!;
      expect(p.isIncome, isFalse);
      expect(p.peer, 'Adrian I Mamani Q');
      expect(p.provider, 'plin');
    });

    test('BBVA: cobro con QR', () {
      final p = reader.parse('Cobro con QR VICTOR RAUL MAMANI QUEA te hizo un pago de S/ 20.0', app: bbva)!;
      expect(p.isIncome, isTrue);
      expect(p.amount, 20.0);
      expect(p.peer, 'VICTOR RAUL MAMANI QUEA');
      expect(p.provider, 'plin');
    });

    test('Interbank: «te ha plineado», también con el monto en otra línea', () {
      final a = reader.parse('Interbank Persona Ejemplo te ha plineado\nS/ 1.00', app: interbank)!;
      expect(a.isIncome, isTrue);
      expect(a.amount, 1.0);
      expect(a.peer, 'Persona Ejemplo');
      expect(a.provider, 'plin');
      final b = reader.parse('Interbank Celia Gutierrez Tafur te ha plineado S/\n0.50', app: interbank)!;
      expect(b.amount, 0.5);
    });

    test('Interbank: «Te plinearon» sin nombre y «Plineaste»', () {
      final a = reader.parse('Interbank Te plinearon S/ 1.00', app: interbank)!;
      expect(a.isIncome, isTrue);
      expect(a.peer, 'Desconocido');
      expect(a.provider, 'plin');
      final b = reader.parse('Interbank Plineaste S/ 1.00 a Ana R Torres P', app: interbank)!;
      expect(b.isIncome, isFalse);
      expect(b.peer, 'Ana R Torres P');
    });
  });

  group('Google Wallet real', () {
    const wallet = 'com.google.android.apps.walletnfcrel';

    test('el título es el comercio y el monto va como PEN', () {
      final p = reader.parse('OPENPAY*XIN FU        LIM PEN35.00 con Visa Clasica BCP Qore ••0771', app: wallet)!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 35.0);
      expect(p.peer, 'OPENPAY*XIN FU LIM');
      expect(p.provider, 'googlePay');
      expect(reader.parse('COLONIAL C31 CERCADO PEN1.50 con Visa Clasica BCP Qore ••0771', app: wallet)!.amount, 1.5);
    });

    test('«pen» dentro de una palabra no es un monto', () {
      expect(reader.parse('Yapeaste a OPEN35 S/ 2.00')!.amount, 2.0);
    });
  });

  group('consumos con tarjeta que avisa el banco', () {
    const interbank = 'pe.com.interbank.mobilebanking';

    test('Interbank: consumo con tarjeta de crédito, con «S/.»', () {
      final p = reader.parse(
          'Interbank Realizaste un consumo de S/.50.00 en COMPA#IA OPERADORA DE L con tu Tarjeta de Crédito.',
          app: interbank)!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 50.0);
      expect(p.peer, 'COMPA#IA OPERADORA DE L');
      expect(p.provider, 'tarjeta');
    });

    test('Interbank: consumo con tarjeta de débito', () {
      final p = reader.parse('Interbank Realizaste un consumo de S/.40.00 en VM*ELECTROVIBE con tu Tarjeta de Débito.',
          app: interbank)!;
      expect(p.peer, 'VM*ELECTROVIBE');
      expect(p.provider, 'tarjeta');
    });

    test('correo del BCP: el comercio va después de la tarjeta', () {
      final p = reader.parse('Realizaste un consumo de S/ 25.78 con tu Tarjeta de Débito BCP en WL *STEAM PURCHASE.')!;
      expect(p.isIncome, isFalse);
      expect(p.amount, 25.78);
      expect(p.peer, 'WL *STEAM PURCHASE');
      expect(p.provider, 'tarjeta');
    });

    test('un cargo en dólares no se anota como soles', () {
      expect(
          reader.parse(r'Interbank Se realizó un pago recurrente de $26.19 en HOSTINGER* HOSTINGER.C con tu Tarjeta de Débito.',
              app: interbank),
          isNull);
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

    test('de una pantalla solo cuenta la constancia, no el inicio con el saldo', () {
      final receipt = RegExp(rules['screenReceipt'] as String, caseSensitive: false, unicode: true);
      expect(receipt.hasMatch('¡Yapeaste! S/ 1 Michael 01 oct. 2026 09:48 a. m. DATOS DE LA TRANSACCIÓN Nro. de celular'), isTrue);
      expect(receipt.hasMatch('¡Yapeaste el servicio! S/ 134.85 BanBif DATOS DE LA TRANSACCIÓN Servicio'), isTrue);
      expect(receipt.hasMatch('Yape Ver saldo S/ 1,250.00 Ocultar saldo Yapear Servicios Movimientos Juan te yapeó S/ 15.00'),
          isFalse);
    });

    test('un texto sin número de operación no inventa uno', () {
      expect(op('Yape! MICHAEL te envió un pago por S/ 1'), isNull);
      expect(op('Código de cliente: 73654903'), isNull);
    });
  });
}
