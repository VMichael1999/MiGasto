import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Valores del `.env` de la raíz (no se sube al repositorio; la plantilla es `.env.example`).
///
/// - Claves nativas (Google Maps, esquema de Google Sign-In en iPhone): las leen
///   Android (build.gradle.kts) e iOS (xcconfig) directamente del `.env`.
/// - Claves de Dart (Gemini, Firebase, clientes de Google): se leen aquí al arrancar.
class Env {
  const Env._();

  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get hasMapsKey => googleMapsApiKey.isNotEmpty;

  static Map<String, String> _values = const {};

  /// Lee el `.env` empaquetado como recurso. Si falta, todo queda vacío y la app
  /// sigue funcionando sin las funciones que dependen de claves.
  static Future<void> load() async {
    try {
      _values = parse(await rootBundle.loadString('.env'));
    } catch (_) {
      _values = const {};
    }
  }

  /// Solo para pruebas: reemplaza los valores cargados.
  @visibleForTesting
  static void setForTest(Map<String, String> values) => _values = values;

  /// Valor de [key], o cadena vacía si no está configurado.
  static String value(String key) => _values[key] ?? '';

  /// Convierte el contenido de un `.env` (CLAVE=valor; los comentarios empiezan con // porque Xcode también lee este archivo).
  static Map<String, String> parse(String content) {
    final map = <String, String>{};
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) continue;
      final i = line.indexOf('=');
      if (i <= 0) continue;
      var v = line.substring(i + 1).trim();
      if (v.length >= 2 && ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
        v = v.substring(1, v.length - 1);
      }
      map[line.substring(0, i).trim()] = v;
    }
    return map;
  }
}
