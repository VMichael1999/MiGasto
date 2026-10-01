import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Movimientos (gastos e ingresos). Las columnas conservan los nombres del
/// modelo anterior para poder leer datos viejos sin conversiones.
@DataClassName('MovimientoRow')
class Movimientos extends Table {
  TextColumn get uuid => text()();
  RealColumn get amount => real()();
  TextColumn get merchant => text()();
  TextColumn get categoryName => text()();
  TextColumn get sourceName => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get tipoName => text().withDefault(const Constant('gasto'))();
  TextColumn get estadoName => text().withDefault(const Constant('pendiente'))();
  TextColumn get canalName => text().withDefault(const Constant('manual'))();
  TextColumn get tarjeta => text().nullable()();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();
  RealColumn get precision => real().nullable()();
  TextColumn get lugar => text().nullable()();
  TextColumn get textoOriginal => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {uuid};
}

@DriftDatabase(tables: [Movimientos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<MovimientoRow>> allMovimientos() => select(movimientos).get();

  Future<void> upsert(MovimientosCompanion row) =>
      into(movimientos).insertOnConflictUpdate(row);

  Future<void> deleteByUuid(String uuid) =>
      (delete(movimientos)..where((t) => t.uuid.equals(uuid))).go();

  /// Fuerza una lectura: con una clave incorrecta falla aquí y no más adelante.
  Future<void> verify() => customSelect('select count(*) from sqlite_master').get();
}
