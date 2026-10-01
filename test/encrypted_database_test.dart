import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/app_database.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _m(String id, {String merchant = 'Tambo Miraflores', double amount = 25.5}) =>
    Movimiento(
      id: id,
      amount: amount,
      merchant: merchant,
      category: Categoria.compras,
      source: PaymentSource.tarjeta,
      date: DateTime(2026, 9, 27, 12, 41),
      tipo: TipoMovimiento.gasto,
      canal: CanalMovimiento.wallet,
      estado: EstadoMovimiento.confirmado,
      tarjeta: 'Visa BBVA ···4821',
      latitud: -12.09,
      longitud: -77.03,
      precision: 15,
      lugar: 'Av. Arequipa 3120, San Isidro',
      textoOriginal: 'Apple Pay: S/ 25.50 en Tambo Miraflores',
    );

void main() {
  group('Base de datos cifrada', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('migasto_db_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('el archivo no contiene los datos en claro y solo abre con la clave', () async {
      final file = File('${dir.path}/migasto.db');
      const key = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

      var db = AppDatabase(DatabaseManager.openEncryptedFile(file, key));
      await db.verify();
      await db.upsert(MovimientosCompanion.insert(
        uuid: 'u1',
        amount: 25.5,
        merchant: 'Tambo Miraflores',
        categoryName: 'compras',
        sourceName: 'tarjeta',
        date: DateTime(2026, 9, 27),
      ));
      await db.close();

      // Cifrado: el comercio no aparece en el archivo.
      final bytes = file.readAsBytesSync();
      expect(utf8.decode(bytes, allowMalformed: true), isNot(contains('Tambo Miraflores')));
      expect(utf8.decode(bytes, allowMalformed: true), isNot(contains('SQLite format 3')));

      // Con la clave correcta se lee.
      db = AppDatabase(DatabaseManager.openEncryptedFile(file, key));
      await db.verify();
      expect((await db.allMovimientos()).single.merchant, 'Tambo Miraflores');
      await db.close();

      // Con otra clave no abre.
      db = AppDatabase(DatabaseManager.openEncryptedFile(file, 'otra-clave'));
      await expectLater(db.verify(), throwsA(anything));
      await db.close();
    });
  });

  group('DatabaseManager sobre Drift', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('guarda, lee, actualiza y elimina movimientos con todos sus campos', () async {
      final manager = DatabaseManager(prefs, executor: NativeDatabase.memory());
      await manager.init();

      await manager.saveExpense(_m('a'));
      await manager.saveExpense(_m('b', merchant: 'Oxxo', amount: 8.9));

      var list = await manager.getExpenses();
      expect(list, hasLength(2));
      final a = list.firstWhere((m) => m.id == 'a');
      expect(a.canal, CanalMovimiento.wallet);
      expect(a.tarjeta, 'Visa BBVA ···4821');
      expect(a.latitud, -12.09);
      expect(a.precision, 15);
      expect(a.lugar, 'Av. Arequipa 3120, San Isidro');
      expect(a.textoOriginal, contains('Apple Pay'));
      expect(a.isConfirmed, isTrue);

      // Actualizar con el mismo id no duplica.
      await manager.saveExpense(a.copyWith(amount: 30));
      list = await manager.getExpenses();
      expect(list, hasLength(2));
      expect(list.firstWhere((m) => m.id == 'a').amount, 30);

      await manager.deleteExpense('b');
      expect(await manager.getExpenses(), hasLength(1));
      await manager.close();
    });

    test('pasa a la base los movimientos que habían quedado en el respaldo', () async {
      SharedPreferences.setMockInitialValues({
        'migasto_fallback_expenses': jsonEncode([
          {
            'id': 'old1',
            'amount': 12.0,
            'merchant': 'Bodega',
            'category': 'compras',
            'source': 'yape',
            'date': '2026-09-20T10:00:00.000',
            'notes': 'Yapeaste S/ 12.00 a Bodega',
            'isConfirmed': true,
          },
        ]),
      });
      prefs = await SharedPreferences.getInstance();

      final manager = DatabaseManager(prefs, executor: NativeDatabase.memory());
      await manager.init();

      final list = await manager.getExpenses();
      expect(list.single.id, 'old1');
      expect(list.single.estado, EstadoMovimiento.confirmado);
      expect(prefs.getString('migasto_fallback_expenses'), isNull);
      await manager.close();
    });
  });
}
