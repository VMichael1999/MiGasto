import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/app_database.dart';

/// Una base creada por la versión anterior de la app (esquema 1) se actualiza sin perder nada.
void main() {
  test('el esquema 1 pasa al 2: los movimientos siguen y las columnas nuevas tienen valor', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE movimientos (
          uuid TEXT NOT NULL PRIMARY KEY,
          amount REAL NOT NULL,
          merchant TEXT NOT NULL,
          category_name TEXT NOT NULL,
          source_name TEXT NOT NULL,
          date INTEGER NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          tipo_name TEXT NOT NULL DEFAULT 'gasto',
          estado_name TEXT NOT NULL DEFAULT 'pendiente',
          canal_name TEXT NOT NULL DEFAULT 'manual',
          tarjeta TEXT NULL,
          latitud REAL NULL,
          longitud REAL NULL,
          precision REAL NULL,
          lugar TEXT NULL,
          texto_original TEXT NOT NULL DEFAULT ''
        );
      ''');
      raw.execute("INSERT INTO movimientos (uuid, amount, merchant, category_name, source_name, date) "
          "VALUES ('m-1', 25.5, 'Tambo', 'compras', 'yape', 1795500000)");
      raw.execute('PRAGMA user_version = 1');
    });
    final db = AppDatabase(executor);
    addTearDown(db.close);

    final rows = await db.allMovimientos();
    expect(rows, hasLength(1));
    expect(rows.single.merchant, 'Tambo');
    expect(rows.single.entreMisCuentas, isFalse);
    expect(rows.single.moneda, isNull);

    await db.upsert(MovimientosCompanion.insert(
      uuid: 'm-2',
      amount: 75.2,
      merchant: 'NETFLIX',
      categoryName: 'entretenimiento',
      sourceName: 'tarjeta',
      date: DateTime(2026, 11, 24),
      entreMisCuentas: const Value(true),
      moneda: const Value('USD'),
      montoOriginal: const Value(20),
      tipoCambio: const Value(3.76),
    ));
    final nuevo = (await db.allMovimientos()).firstWhere((r) => r.uuid == 'm-2');
    expect(nuevo.entreMisCuentas, isTrue);
    expect(nuevo.moneda, 'USD');
    expect(nuevo.montoOriginal, 20);
    expect(nuevo.tipoCambio, 3.76);
  });
}
