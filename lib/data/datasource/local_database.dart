import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/movimiento.dart';
import 'app_database.dart';

abstract class LocalDatabase {
  Future<void> init();
  Future<List<Movimiento>> getExpenses();
  Future<void> saveExpense(Movimiento expense);
  Future<void> deleteExpense(String id);
}

/// Guarda los movimientos en una base de datos SQLite **cifrada**.
///
/// La clave se genera en el teléfono la primera vez y vive en el almacén seguro
/// del sistema (Keychain en iPhone, Keystore en Android); no sale del teléfono.
/// Si la base no se puede abrir (por ejemplo en pruebas sin plugins), los datos
/// van a un respaldo en SharedPreferences para no perder movimientos.
class DatabaseManager implements LocalDatabase {
  DatabaseManager(
    this._prefs, {
    QueryExecutor? executor,
    FlutterSecureStorage? secureStorage,
  })  : _injected = executor,
        _secure = secureStorage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final SharedPreferences _prefs;
  final QueryExecutor? _injected;
  final FlutterSecureStorage _secure;

  AppDatabase? _db;
  bool _useFallback = false;

  static const String _keyFallbackExpenses = 'migasto_fallback_expenses';
  static const String _keyDbKey = 'migasto_db_key';
  static const String _fileName = 'migasto.db';

  @override
  Future<void> init() async {
    if (_db != null) return;
    try {
      final db = AppDatabase(_injected ?? await _openEncrypted());
      await db.verify();
      _db = db;
      await _importLegacyFallback();
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      _useFallback = true;
    }
  }

  /// Cierra la base (para pruebas).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ------------------------------------------------------------ apertura

  Future<QueryExecutor> _openEncrypted() async {
    final key = await _loadOrCreateKey();
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return openEncryptedFile(File(p.join(dir.path, _fileName)), key);
  }

  /// Abre (o crea) un archivo SQLite cifrado con [key].
  static QueryExecutor openEncryptedFile(File file, String key) {
    return NativeDatabase(
      file,
      setup: (raw) {
        // Debe ser lo primero que se ejecuta en la conexión.
        raw.execute("PRAGMA key = '$key';");
      },
    );
  }

  Future<String> _loadOrCreateKey() async {
    final existing = await _secure.read(key: _keyDbKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secure.write(key: _keyDbKey, value: key);
    return key;
  }

  /// Pasa a la base los movimientos que hubieran quedado en el respaldo.
  Future<void> _importLegacyFallback() async {
    final legacy = _loadFallbackExpenses();
    if (legacy.isEmpty) return;
    for (final m in legacy) {
      await _db!.upsert(_toCompanion(m));
    }
    await _prefs.remove(_keyFallbackExpenses);
  }

  // ------------------------------------------------------------ lectura y escritura

  @override
  Future<List<Movimiento>> getExpenses() async {
    final db = _db;
    if (_useFallback || db == null) return _loadFallbackExpenses();
    try {
      final rows = await db.allMovimientos();
      return rows.map(_fromRow).toList();
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      return _loadFallbackExpenses();
    }
  }

  @override
  Future<void> saveExpense(Movimiento expense) async {
    final db = _db;
    if (_useFallback || db == null) {
      await _saveFallbackExpense(expense);
      return;
    }
    try {
      await db.upsert(_toCompanion(expense));
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      await _saveFallbackExpense(expense);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = _db;
    if (_useFallback || db == null) {
      await _deleteFallbackExpense(id);
      return;
    }
    try {
      await db.deleteByUuid(id);
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      await _deleteFallbackExpense(id);
    }
  }

  // ---- Enum parsing con valores por defecto para registros anteriores ----

  static T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null || name.isEmpty) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// Un registro anterior no tiene `estado`: se deduce de `isConfirmed`.
  static EstadoMovimiento _estado(String? name, bool legacyConfirmed) {
    if (name != null && name.isNotEmpty) {
      return _enumByName(EstadoMovimiento.values, name, EstadoMovimiento.pendiente);
    }
    return legacyConfirmed ? EstadoMovimiento.confirmado : EstadoMovimiento.pendiente;
  }

  /// Un registro anterior no tiene `canal`: manual si fue manual, si no notificación.
  static CanalMovimiento _canal(String? name, PaymentSource source) {
    if (name != null && name.isNotEmpty) {
      return _enumByName(CanalMovimiento.values, name, CanalMovimiento.manual);
    }
    return source == PaymentSource.manual
        ? CanalMovimiento.manual
        : CanalMovimiento.notificacion;
  }

  // ---- Fallback storage helpers (SharedPreferences JSON list) ----

  List<Movimiento> _loadFallbackExpenses() {
    final raw = _prefs.getString(_keyFallbackExpenses);
    if (raw == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        final source = _enumByName(
            PaymentSource.values, map['source'] as String?, PaymentSource.manual);
        final notes = (map['notes'] as String?) ?? '';
        return Movimiento(
          id: map['id'],
          amount: (map['amount'] as num).toDouble(),
          merchant: map['merchant'],
          category: leerCategoriaAlmacenada(map['category'] as String?, Categoria.otros).categoria,
          categoriaPropia: leerCategoriaAlmacenada(map['category'] as String?, Categoria.otros).propia,
          source: source,
          date: DateTime.parse(map['date']),
          notes: notes,
          tipo: _enumByName(
              TipoMovimiento.values, map['tipo'] as String?, TipoMovimiento.gasto),
          canal: _canal(map['canal'] as String?, source),
          estado: _estado(map['estado'] as String?, map['isConfirmed'] ?? false),
          tarjeta: map['tarjeta'] as String?,
          latitud: (map['latitud'] as num?)?.toDouble(),
          longitud: (map['longitud'] as num?)?.toDouble(),
          precision: (map['precision'] as num?)?.toDouble(),
          lugar: map['lugar'] as String?,
          textoOriginal: (map['textoOriginal'] as String?) ??
              (source == PaymentSource.manual ? '' : notes),
        );
      }).toList();
    } catch (e) {
      debugPrint('MiGasto DB Error: $e');
      return [];
    }
  }

  Future<void> _saveFallbackExpense(Movimiento expense) async {
    final list = _loadFallbackExpenses();
    final index = list.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      list[index] = expense;
    } else {
      list.add(expense);
    }
    await _saveAllFallback(list);
  }

  Future<void> _deleteFallbackExpense(String id) async {
    final list = _loadFallbackExpenses();
    list.removeWhere((e) => e.id == id);
    await _saveAllFallback(list);
  }

  Future<void> _saveAllFallback(List<Movimiento> list) async {
    final jsonList = list.map((e) => {
      'id': e.id,
      'amount': e.amount,
      'merchant': e.merchant,
      'category': categoriaAlmacenada(e.category, e.categoriaPropia),
      'source': e.source.name,
      'date': e.date.toIso8601String(),
      'notes': e.notes,
      'isConfirmed': e.isConfirmed,
      'tipo': e.tipo.name,
      'canal': e.canal.name,
      'estado': e.estado.name,
      'tarjeta': e.tarjeta,
      'latitud': e.latitud,
      'longitud': e.longitud,
      'precision': e.precision,
      'lugar': e.lugar,
      'textoOriginal': e.textoOriginal,
    }).toList();
    await _prefs.setString(_keyFallbackExpenses, jsonEncode(jsonList));
  }

  // ---- Mapeo ----

  MovimientosCompanion _toCompanion(Movimiento e) => MovimientosCompanion(
        uuid: Value(e.id),
        amount: Value(e.amount),
        merchant: Value(e.merchant),
        categoryName: Value(categoriaAlmacenada(e.category, e.categoriaPropia)),
        sourceName: Value(e.source.name),
        date: Value(e.date),
        notes: Value(e.notes),
        tipoName: Value(e.tipo.name),
        estadoName: Value(e.estado.name),
        canalName: Value(e.canal.name),
        tarjeta: Value(e.tarjeta),
        latitud: Value(e.latitud),
        longitud: Value(e.longitud),
        precision: Value(e.precision),
        lugar: Value(e.lugar),
        textoOriginal: Value(e.textoOriginal),
      );

  Movimiento _fromRow(MovimientoRow r) {
    final source = _enumByName(PaymentSource.values, r.sourceName, PaymentSource.manual);
    return Movimiento(
      id: r.uuid,
      amount: r.amount,
      merchant: r.merchant,
      category: leerCategoriaAlmacenada(r.categoryName, Categoria.otros).categoria,
      categoriaPropia: leerCategoriaAlmacenada(r.categoryName, Categoria.otros).propia,
      source: source,
      date: r.date,
      notes: r.notes,
      tipo: _enumByName(TipoMovimiento.values, r.tipoName, TipoMovimiento.gasto),
      canal: _canal(r.canalName, source),
      estado: _estado(r.estadoName, false),
      tarjeta: r.tarjeta,
      latitud: r.latitud,
      longitud: r.longitud,
      precision: r.precision,
      lugar: r.lugar,
      textoOriginal: r.textoOriginal,
    );
  }
}
