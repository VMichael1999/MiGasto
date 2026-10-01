import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/data/services/backup_service.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  // 10 000 vueltas: lo mínimo que acepta el lector; el valor real se mide aparte.
  const service = BackupService(iterations: 10000);

  BackupContents sample() => BackupContents(
        creado: DateTime.utc(2026, 10, 1, 12),
        presupuesto: 1500,
        aprendidas: {'tambo': 'alimentacion'},
        movimientos: [
          Movimiento(
            id: 'a1',
            amount: 25.5,
            merchant: 'Tambo Surco',
            category: Categoria.alimentacion,
            source: PaymentSource.yape,
            date: DateTime.utc(2026, 10, 1, 9, 30),
            notes: 'almuerzo',
            canal: CanalMovimiento.notificacion,
            estado: EstadoMovimiento.confirmado,
            latitud: -12.0464,
            longitud: -77.0428,
            precision: 12.5,
            lugar: 'Av. Javier Prado Este 425',
            textoOriginal: 'Yapeaste S/ 25.50 a Tambo Surco',
          ),
          Movimiento(
            id: 'b2',
            amount: 3,
            merchant: 'ÑAÑO PÉREZ ñ ü 日本',
            category: Categoria.transferenciaRecibida,
            source: PaymentSource.yape,
            date: DateTime.utc(2026, 10, 1, 10),
            tipo: TipoMovimiento.ingreso,
            canal: CanalMovimiento.notificacion,
          ),
        ],
      );

  test('cifra y descifra sin perder ningún dato', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    final back = await service.decrypt(data, 'mi contraseña segura');

    expect(back.presupuesto, 1500);
    expect(back.aprendidas, {'tambo': 'alimentacion'});
    expect(back.creado, DateTime.utc(2026, 10, 1, 12));
    expect(back.movimientos, hasLength(2));

    final a = back.movimientos.first;
    expect(a.id, 'a1');
    expect(a.amount, 25.5);
    expect(a.merchant, 'Tambo Surco');
    expect(a.category, Categoria.alimentacion);
    expect(a.source, PaymentSource.yape);
    expect(a.date, DateTime.utc(2026, 10, 1, 9, 30));
    expect(a.notes, 'almuerzo');
    expect(a.estado, EstadoMovimiento.confirmado);
    expect(a.latitud, -12.0464);
    expect(a.longitud, -77.0428);
    expect(a.precision, 12.5);
    expect(a.lugar, 'Av. Javier Prado Este 425');
    expect(a.textoOriginal, 'Yapeaste S/ 25.50 a Tambo Surco');

    final b = back.movimientos.last;
    expect(b.merchant, 'ÑAÑO PÉREZ ñ ü 日本');
    expect(b.tipo, TipoMovimiento.ingreso);
    expect(b.latitud, isNull);
  });

  test('el archivo no deja ver nada en claro', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    final text = latin1.decode(data);
    expect(text.contains('Tambo'), isFalse);
    expect(text.contains('Yape'), isFalse);
    expect(text.contains('Javier Prado'), isFalse);
    expect(String.fromCharCodes(data.sublist(0, 4)), 'MGB1');
  });

  test('dos respaldos iguales dan archivos distintos (sal y nonce al azar)', () async {
    final a = await service.encrypt(sample(), 'mi contraseña segura');
    final b = await service.encrypt(sample(), 'mi contraseña segura');
    expect(a, isNot(equals(b)));
  });

  test('una contraseña incorrecta no abre el respaldo', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    expect(
      () => service.decrypt(data, 'otra contraseña'),
      throwsA(isA<BackupException>()
          .having((e) => e.message, 'mensaje', contains('contraseña'))),
    );
  });

  test('si alguien altera el contenido, se detecta', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    final tampered = Uint8List.fromList(data)..[data.length ~/ 2] ^= 0x01;
    expect(() => service.decrypt(tampered, 'mi contraseña segura'),
        throwsA(isA<BackupException>()));
  });

  test('si alguien altera la cabecera (sal), se detecta', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    final tampered = Uint8List.fromList(data)..[10] ^= 0x01;
    expect(() => service.decrypt(tampered, 'mi contraseña segura'),
        throwsA(isA<BackupException>()));
  });

  test('un archivo que no es de MiGasto se rechaza con un mensaje claro', () async {
    final notBackup = Uint8List.fromList(utf8.encode('esto es un texto cualquiera ' * 5));
    expect(
      () => service.decrypt(notBackup, 'mi contraseña segura'),
      throwsA(isA<BackupException>()
          .having((e) => e.message, 'mensaje', contains('no es un respaldo'))),
    );
    expect(() => service.decrypt(Uint8List(3), 'x'), throwsA(isA<BackupException>()));
  });

  test('una cabecera con un número de vueltas absurdo no cuelga el teléfono', () async {
    final data = await service.encrypt(sample(), 'mi contraseña segura');
    final hostile = Uint8List.fromList(data);
    ByteData.sublistView(hostile).setUint32(4, 4000000000, Endian.big);
    expect(() => service.decrypt(hostile, 'mi contraseña segura'),
        throwsA(isA<BackupException>()));
  });

  test('la contraseña corta se rechaza al crear', () async {
    expect(() => service.encrypt(sample(), 'corta'), throwsA(isA<BackupException>()));
  });

  test('con las vueltas reales tarda un tiempo razonable', () async {
    const real = BackupService();
    final sw = Stopwatch()..start();
    final data = await real.encrypt(sample(), 'mi contraseña segura');
    final encrypted = sw.elapsedMilliseconds;
    await real.decrypt(data, 'mi contraseña segura');
    // ignore: avoid_print
    print('cifrar: $encrypted ms, total con descifrar: ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, lessThan(60000));
  });

  group('restaurar en la app', () {
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container.read(localDatabaseProvider).init();
      container.read(expensesStateProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() => container.dispose());

    test('agrega lo que falta, no duplica y recupera presupuesto y categorías', () async {
      final notifier = container.read(expensesStateProvider.notifier);
      await notifier.addManualMovimiento(
        tipo: TipoMovimiento.gasto,
        amount: 10,
        merchant: 'Ya estaba',
        category: Categoria.otros,
      );
      final yaEstaba = container.read(expensesStateProvider).single;

      final contents = BackupContents(
        creado: DateTime.utc(2026, 10, 1),
        presupuesto: 900,
        aprendidas: {'tambo': 'alimentacion', 'raro': 'noExiste'},
        movimientos: [yaEstaba, ...sample().movimientos],
      );
      expect(notifier.cuantosSonNuevos(contents), 2);

      final agregados = await notifier.restaurarRespaldo(contents);
      expect(agregados, 2);
      expect(container.read(expensesStateProvider), hasLength(3));
      expect(container.read(budgetProvider), 900);

      // Restaurar dos veces el mismo respaldo no duplica nada.
      expect(await notifier.restaurarRespaldo(contents), 0);
      expect(container.read(expensesStateProvider), hasLength(3));

      // El respaldo que se crea desde la app trae todo.
      final back = notifier.contenidoDeRespaldo();
      expect(back.movimientos, hasLength(3));
      expect(back.presupuesto, 900);
      expect(back.aprendidas['tambo'], 'alimentacion');
    });
  });
}
