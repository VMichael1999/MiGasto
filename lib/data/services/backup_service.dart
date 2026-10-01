import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../domain/entities/movimiento.dart';

/// Lo que viaja dentro de un respaldo.
class BackupContents {
  const BackupContents({
    required this.movimientos,
    required this.presupuesto,
    required this.aprendidas,
    required this.creado,
    this.alias = const {},
  });

  final List<Movimiento> movimientos;
  final double presupuesto;

  /// Comercio en minúsculas -> nombre de la categoría que el usuario eligió.
  final Map<String, String> aprendidas;

  /// Nombres que el usuario le puso a personas y comercios (clave normalizada -> nombre).
  final Map<String, String> alias;
  final DateTime creado;
}

/// El respaldo no se pudo crear o leer. [message] se puede mostrar al usuario.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Respaldo cifrado de los movimientos en un archivo.
///
/// La contraseña la elige el usuario y no se guarda en ningún lado. La clave se
/// deriva con PBKDF2-HMAC-SHA256 y el contenido se cifra con AES-256-GCM, que
/// además detecta si el archivo fue alterado o la contraseña no coincide.
///
/// Formato del archivo (todo en bytes):
/// `"MGB1"` (4) · iteraciones (4, big endian) · sal (16) · nonce (12) · texto cifrado · etiqueta (16)
/// Los primeros 24 bytes (cabecera) también quedan autenticados.
class BackupService {
  const BackupService({this.iterations = defaultIterations});

  static const int defaultIterations = 210000;
  static const int minPassphraseLength = 8;
  static const int _formatVersion = 1;
  static const List<int> _magic = [0x4D, 0x47, 0x42, 0x31]; // "MGB1"
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _headerLength = 4 + 4 + _saltLength;
  static const int _macLength = 16;

  /// Extensión del archivo de respaldo.
  static const String extension = 'mgb';

  final int iterations;

  // ------------------------------------------------------------ crear

  /// Cifra [contents] con [passphrase]. Corre en otro hilo: derivar la clave tarda.
  Future<Uint8List> encrypt(BackupContents contents, String passphrase) async {
    if (passphrase.length < minPassphraseLength) {
      throw const BackupException(
          'La contraseña debe tener al menos $minPassphraseLength caracteres.');
    }
    final plain = utf8.encode(jsonEncode(_toJson(contents)));
    final random = Random.secure();
    final salt = _randomBytes(random, _saltLength);
    final nonce = _randomBytes(random, _nonceLength);
    final iterations = this.iterations;

    return Isolate.run(() async {
      final header = BytesBuilder()
        ..add(_magic)
        ..add(_u32(iterations))
        ..add(salt);
      final key = await _deriveKey(passphrase, salt, iterations);
      final box = await AesGcm.with256bits().encrypt(
        plain,
        secretKey: key,
        nonce: nonce,
        aad: header.toBytes(),
      );
      return (BytesBuilder()
            ..add(header.toBytes())
            ..add(nonce)
            ..add(box.cipherText)
            ..add(box.mac.bytes))
          .toBytes();
    });
  }

  // ------------------------------------------------------------ leer

  /// Descifra un respaldo. Lanza [BackupException] si no es un respaldo de MiGasto,
  /// si la contraseña no coincide o si el archivo está dañado.
  Future<BackupContents> decrypt(Uint8List data, String passphrase) async {
    if (data.length < _headerLength + _nonceLength + _macLength ||
        !_startsWithMagic(data)) {
      throw const BackupException('Este archivo no es un respaldo de MiGasto.');
    }
    final view = ByteData.sublistView(data);
    final iterations = view.getUint32(4, Endian.big);
    // Un valor absurdo en la cabecera podría bloquear el teléfono.
    if (iterations < 10000 || iterations > 5000000) {
      throw const BackupException('El archivo de respaldo está dañado.');
    }

    final salt = Uint8List.sublistView(data, 8, _headerLength);
    final nonce = Uint8List.sublistView(data, _headerLength, _headerLength + _nonceLength);
    final cipher = Uint8List.sublistView(
        data, _headerLength + _nonceLength, data.length - _macLength);
    final mac = Uint8List.sublistView(data, data.length - _macLength);
    final header = Uint8List.sublistView(data, 0, _headerLength);

    final Uint8List plain;
    try {
      plain = await Isolate.run(() async {
        final key = await _deriveKey(passphrase, salt, iterations);
        final clear = await AesGcm.with256bits().decrypt(
          SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
          secretKey: key,
          aad: header,
        );
        return Uint8List.fromList(clear);
      });
    } on SecretBoxAuthenticationError {
      throw const BackupException(
          'La contraseña no coincide o el archivo está dañado.');
    } catch (_) {
      throw const BackupException(
          'La contraseña no coincide o el archivo está dañado.');
    }
    return _fromJson(plain);
  }

  // ------------------------------------------------------------ interno

  static Future<SecretKey> _deriveKey(
      String passphrase, List<int> salt, int iterations) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static bool _startsWithMagic(Uint8List data) {
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) return false;
    }
    return true;
  }

  static Uint8List _randomBytes(Random random, int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));

  static Uint8List _u32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();

  static Map<String, dynamic> _toJson(BackupContents c) => {
        'formato': _formatVersion,
        'app': 'MiGasto',
        'creado': c.creado.toIso8601String(),
        'presupuesto': c.presupuesto,
        'aprendidas': c.aprendidas,
        'alias': c.alias,
        'movimientos': c.movimientos.map(_movimientoToJson).toList(),
      };

  static BackupContents _fromJson(Uint8List plain) {
    try {
      final map = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final version = map['formato'];
      if (map['app'] != 'MiGasto' || version is! int) {
        throw const BackupException('Este archivo no es un respaldo de MiGasto.');
      }
      if (version > _formatVersion) {
        throw const BackupException(
            'Este respaldo es de una versión más nueva de MiGasto. Actualiza la app.');
      }
      return BackupContents(
        creado: DateTime.parse(map['creado'] as String),
        presupuesto: (map['presupuesto'] as num).toDouble(),
        aprendidas: (map['aprendidas'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        // Los respaldos hechos antes de los alias no traen este campo.
        alias: ((map['alias'] as Map<String, dynamic>?) ?? const {})
            .map((k, v) => MapEntry(k, v as String)),
        movimientos: (map['movimientos'] as List)
            .map((m) => _movimientoFromJson(m as Map<String, dynamic>))
            .toList(),
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('El archivo de respaldo está dañado.');
    }
  }

  static Map<String, dynamic> _movimientoToJson(Movimiento m) => {
        'id': m.id,
        'monto': m.amount,
        'contraparte': m.merchant,
        'categoria': m.category.name,
        'fuente': m.source.name,
        'fecha': m.date.toIso8601String(),
        'notas': m.notes,
        'tipo': m.tipo.name,
        'canal': m.canal.name,
        'estado': m.estado.name,
        'tarjeta': m.tarjeta,
        'latitud': m.latitud,
        'longitud': m.longitud,
        'precision': m.precision,
        'lugar': m.lugar,
        'textoOriginal': m.textoOriginal,
      };

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static Movimiento _movimientoFromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as String,
        amount: (j['monto'] as num).toDouble(),
        merchant: j['contraparte'] as String,
        category: _byName(Categoria.values, j['categoria'], Categoria.otros),
        source: _byName(PaymentSource.values, j['fuente'], PaymentSource.otro),
        date: DateTime.parse(j['fecha'] as String),
        notes: (j['notas'] as String?) ?? '',
        tipo: _byName(TipoMovimiento.values, j['tipo'], TipoMovimiento.gasto),
        canal: _byName(CanalMovimiento.values, j['canal'], CanalMovimiento.manual),
        estado: _byName(EstadoMovimiento.values, j['estado'], EstadoMovimiento.pendiente),
        tarjeta: j['tarjeta'] as String?,
        latitud: (j['latitud'] as num?)?.toDouble(),
        longitud: (j['longitud'] as num?)?.toDouble(),
        precision: (j['precision'] as num?)?.toDouble(),
        lugar: j['lugar'] as String?,
        textoOriginal: (j['textoOriginal'] as String?) ?? '',
      );
}
