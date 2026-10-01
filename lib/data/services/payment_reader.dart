import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Un pago leído de una notificación o de una captura.
class ParsedPayment {
  const ParsedPayment({
    required this.amount,
    required this.peer,
    required this.provider,
    required this.isIncome,
  });

  final double amount;

  /// Comercio (gastos) o persona/empresa (ingresos).
  final String peer;

  /// `yape`, `plin` o `googlePay`.
  final String provider;
  final bool isIncome;

  String get type => isIncome ? 'ingreso' : 'gasto';

  @override
  String toString() => 'ParsedPayment($type, $amount, $peer, $provider)';
}

/// Lector de pagos. Las reglas viven en `assets/reader_rules.json`, el mismo
/// archivo que lee el código nativo de Android, para que ambos lados reconozcan
/// lo mismo.
class PaymentReader {
  PaymentReader._(this._rules)
      : _amount =
            RegExp(_rules['amount'] as String, caseSensitive: false, unicode: true),
        _income = _compileAll(_rules['income']),
        _expense = _compileAll(_rules['expense']);

  factory PaymentReader.fromJson(String json) =>
      PaymentReader._(jsonDecode(json) as Map<String, dynamic>);

  static Future<PaymentReader> fromAsset([
    String path = 'assets/reader_rules.json',
  ]) async =>
      PaymentReader.fromJson(await rootBundle.loadString(path));

  final Map<String, dynamic> _rules;
  final RegExp _amount;
  final List<RegExp> _income;
  final List<RegExp> _expense;

  static List<RegExp> _compileAll(dynamic list) => (list as List)
      .map((p) => RegExp(p as String, caseSensitive: false, unicode: true))
      .toList();

  /// `null` si el texto no es un pago reconocible (no se inventa un gasto).
  ParsedPayment? parse(String text) {
    final provider = _provider(text);
    if (provider == null) return null;

    final match = _amount.firstMatch(text);
    if (match == null) return null;
    final amount = _parseAmount(match.group(1)!);
    if (amount == null || amount <= 0) return null;

    final isIncome = _direction(text, provider);
    if (isIncome == null) return null;

    final peer = _peer(text, match, isIncome: isIncome);
    return ParsedPayment(
      amount: amount,
      peer: peer.isEmpty ? (_rules['unknownPeer'] as String) : peer,
      provider: provider,
      isIncome: isIncome,
    );
  }

  String? _provider(String text) {
    final lower = text.toLowerCase();
    for (final p in _rules['providers'] as List) {
      final map = p as Map<String, dynamic>;
      for (final k in (map['keywords'] as List).cast<String>()) {
        final found = map['wordBoundary'] == true
            ? RegExp('(?<![\\p{L}\\p{N}])${RegExp.escape(k)}(?![\\p{L}\\p{N}])',
                    unicode: true)
                .hasMatch(lower)
            : lower.contains(k);
        if (found) return map['id'] as String;
      }
    }
    return null;
  }

  /// `true` ingreso, `false` gasto, `null` si no se puede saber.
  bool? _direction(String text, String provider) {
    // Primero los ingresos: "te yapeó" contiene la raíz de "yapeaste".
    if (_income.any((r) => r.hasMatch(text))) return true;
    if (_expense.any((r) => r.hasMatch(text))) return false;
    final defaults = _rules['defaultTypeByProvider'] as Map<String, dynamic>;
    final byProvider = defaults[provider];
    if (byProvider == 'gasto') return false;
    if (byProvider == 'ingreso') return true;
    return null;
  }

  /// `1,200.50` -> 1200.5; `12,50` -> 12.5; `25.5` -> 25.5.
  static double? _parseAmount(String raw) {
    var s = raw.trim();
    if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(s)) {
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  String _peer(String text, RegExpMatch amount, {required bool isIncome}) {
    final preps = (_rules['peerPrepositions'] as List).cast<String>().join('|');
    final after = text.substring(amount.end).trim();
    final before = text.substring(0, amount.start).trim();

    String fromAfter() {
      final m = RegExp('^($preps)\\b(.*)', caseSensitive: false, dotAll: true)
          .firstMatch(after);
      return m == null ? '' : _clean(m.group(2)!);
    }

    // En ingresos el nombre suele ir antes ("Juan te yapeó S/ 15"); en gastos,
    // después ("Yapeaste S/ 25 a Tambo"). Se prueba el otro lado si queda vacío.
    final first = isIncome ? _clean(before) : fromAfter();
    if (first.isNotEmpty) return first;
    final second = isIncome ? fromAfter() : _clean(before);
    if (second.isNotEmpty || isIncome) return second;
    return _fromAfterWithoutPreposition(after);
  }

  /// Constancia de Yape al enviar: el nombre va justo después del monto, sin "a" ni
  /// "de" ("¡Yapeaste! S/ 1 Juan Pérez 01 oct. 2026 09:48 a. m. DATOS DE LA ..."). Se
  /// toma hasta la primera cifra (la fecha) y se descarta si queda demasiado largo.
  String _fromAfterWithoutPreposition(String after) {
    final digit = RegExp(r'\d').firstMatch(after);
    final name = _clean(digit == null ? after : after.substring(0, digit.start));
    return name.length >= 2 && name.length <= 60 ? name : '';
  }

  String _clean(String input) {
    var t = input;
    for (final stop in (_rules['peerStopWords'] as List).cast<String>()) {
      final i = t.toLowerCase().indexOf(stop);
      if (i > 0) t = t.substring(0, i);
    }
    final phrases = (_rules['cleanPhrases'] as List).cast<String>();
    // Las frases más largas primero para no dejar restos.
    final sorted = [...phrases]..sort((a, b) => b.length.compareTo(a.length));
    for (final phrase in sorted) {
      t = t.replaceAll(
        RegExp('(^|[^\\p{L}])${RegExp.escape(phrase)}(?![\\p{L}])',
            caseSensitive: false, unicode: true),
        ' ',
      );
    }
    final preps = (_rules['peerPrepositions'] as List).cast<String>().join('|');
    t = t.replaceAll(RegExp('^\\s*($preps)\\b', caseSensitive: false), '');
    t = t.replaceAll(RegExp('\\b($preps)\\s*\$', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t.replaceAll(RegExp(r'^[\s:,\-¡!.*_]+|[\s:,\-¡!.*_]+$'), '');
  }
}
