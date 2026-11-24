import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Descarga el precio del dólar en soles.
typedef RateFetcher = Future<double?> Function();

/// Tipo de cambio del día (soles por dólar) para los cargos en dólares.
///
/// Solo se descarga ese número: no se envía ningún dato del usuario. Se guarda una vez al día;
/// sin internet se usa el último conocido y, si nunca se pudo descargar, `null`.
class ExchangeRateService {
  ExchangeRateService(this._prefs, {RateFetcher? fetcher, DateTime Function()? clock})
      : _fetch = fetcher ?? fetchUsdToPen,
        _clock = clock ?? DateTime.now;

  static const keyRate = 'migasto_usd_pen_rate';
  static const keyDate = 'migasto_usd_pen_rate_date';

  final SharedPreferences _prefs;
  final RateFetcher _fetch;
  final DateTime Function() _clock;

  /// Soles por dólar, o `null` si nunca se pudo conseguir.
  Future<double?> usdToPen() async {
    final today = _day(_clock());
    final saved = _prefs.getDouble(keyRate);
    if (saved != null && _prefs.getString(keyDate) == today) return saved;
    double? fresh;
    try {
      fresh = await _fetch().timeout(const Duration(seconds: 8));
    } catch (_) {
      fresh = null;
    }
    // Un valor absurdo (una respuesta rota) no se usa.
    if (fresh != null && fresh > 1 && fresh < 20) {
      await _prefs.setDouble(keyRate, fresh);
      await _prefs.setString(keyDate, today);
      return fresh;
    }
    return saved;
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fuentes públicas y gratuitas del tipo de cambio (sin cuenta ni clave). Se prueba la
  /// segunda si la primera falla.
  static const sources = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json',
    'https://latest.currency-api.pages.dev/v1/currencies/usd.json',
  ];

  static Future<double?> fetchUsdToPen() async {
    for (final url in sources) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != 200) continue;
        final body = await response.transform(utf8.decoder).join();
        final rate = parseRate(body);
        if (rate != null) return rate;
      } catch (_) {
        // Sin conexión o fuente caída: se prueba la siguiente.
      } finally {
        client.close(force: true);
      }
    }
    return null;
  }

  /// `{"date": "...", "usd": {"pen": 3.76, ...}}` -> 3.76.
  static double? parseRate(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final pen = (json['usd'] as Map<String, dynamic>?)?['pen'];
      return pen is num ? pen.toDouble() : null;
    } catch (_) {
      return null;
    }
  }
}
