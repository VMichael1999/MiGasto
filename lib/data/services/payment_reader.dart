import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Un pago leído de una notificación o de una captura.
class ParsedPayment {
  const ParsedPayment({
    required this.amount,
    required this.peer,
    required this.provider,
    required this.isIncome,
    this.currency = 'PEN',
  });

  final double amount;

  /// Comercio (gastos) o persona/empresa (ingresos).
  final String peer;

  /// `yape`, `plin`, `googlePay` o `tarjeta` (consumo que avisa un banco).
  final String provider;
  final bool isIncome;

  /// `PEN` (soles) o `USD` (dólares). [amount] está en esta moneda.
  final String currency;

  String get type => isIncome ? 'ingreso' : 'gasto';

  @override
  String toString() => 'ParsedPayment($type, $amount $currency, $peer, $provider)';
}

/// Lector de pagos. Las reglas viven en `assets/reader_rules.json`, el mismo
/// archivo que lee el código nativo de Android, para que ambos lados reconozcan
/// lo mismo.
class PaymentReader {
  PaymentReader._(this._rules)
      : _amount =
            RegExp(_rules['amount'] as String, caseSensitive: false, unicode: true),
        _usdAmount = _rules['usdAmount'] == null
            ? null
            : RegExp(_rules['usdAmount'] as String, caseSensitive: false, unicode: true),
        _income = _compileAll(_rules['income']),
        _expense = _compileAll(_rules['expense']),
        _ignore = _compileAll(_rules['ignore'] ?? const []),
        _ownTransfer = _compileAll(_rules['ownTransfer'] ?? const []);

  factory PaymentReader.fromJson(String json) =>
      PaymentReader._(jsonDecode(json) as Map<String, dynamic>);

  static Future<PaymentReader> fromAsset([
    String path = 'assets/reader_rules.json',
  ]) async =>
      PaymentReader.fromJson(await rootBundle.loadString(path));

  final Map<String, dynamic> _rules;
  final RegExp _amount;

  /// Monto en dólares; solo se usa si el texto no trae uno en soles.
  final RegExp? _usdAmount;
  final List<RegExp> _income;
  final List<RegExp> _expense;

  /// Avisos con monto que no son un pago hecho (compra rechazada, código para
  /// confirmar una compra, recordatorio de un pago por vencer).
  final List<RegExp> _ignore;
  final List<RegExp> _ownTransfer;

  /// Si el texto dice que el dinero fue a otra cuenta del mismo usuario («Yapeaste S/ 100 a
  /// tu cuenta BCP»). Esas transferencias no son gastos ni ingresos de verdad.
  bool isOwnTransfer(String text) => _ownTransfer.any((r) => r.hasMatch(text));

  static List<RegExp> _compileAll(dynamic list) => (list as List)
      .map((p) => RegExp(p as String, caseSensitive: false, unicode: true))
      .toList();

  /// `null` si el texto no es un pago reconocible (no se inventa un gasto).
  ///
  /// [app] es el paquete de Android que publicó la notificación: da la fuente
  /// cuando el texto no la nombra (un yape con código de seguridad no dice
  /// «Yape» y Google Wallet nunca lo dice).
  ParsedPayment? parse(String text, {String? app}) {
    if (_ignore.any((r) => r.hasMatch(text))) return null;
    final provider = _provider(text) ?? _providerByApp(app);
    if (provider == null) return null;

    var currency = 'PEN';
    var match = _amount.firstMatch(text);
    if (match == null) {
      match = _usdAmount?.firstMatch(text);
      currency = 'USD';
    }
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
      currency: currency,
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

  String? _providerByApp(String? app) =>
      app == null ? null : (_rules['providerByApp'] as Map<String, dynamic>?)?[app] as String?;

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
    final before = _withoutTitlePrefix(text.substring(0, amount.start).trim());

    String fromAfter() {
      final m = RegExp('^($preps)\\b(.*)', caseSensitive: false, dotAll: true)
          .firstMatch(after);
      if (m == null) return '';
      // Lo que sigue a «con» es la tarjeta, no el comercio: «PEN35.00 con Visa Clasica …»
      // (Google Wallet). Si después viene «en», ahí está el comercio: «S/ 25.78 con tu
      // Tarjeta de Débito BCP en WL *STEAM PURCHASE.» (correo del BCP).
      if (m.group(1)!.toLowerCase() == 'con') {
        final place = RegExp(r'\sen\s+(.+)$', caseSensitive: false, dotAll: true).firstMatch(m.group(2)!);
        return place == null ? '' : _clean(place.group(1)!);
      }
      return _clean(m.group(2)!);
    }

    // En ingresos el nombre suele ir antes ("Juan te yapeó S/ 15"); en gastos,
    // después ("Yapeaste S/ 25 a Tambo"). Se prueba el otro lado si queda vacío.
    final first = isIncome ? _clean(before) : fromAfter();
    if (first.isNotEmpty) return first;
    if (isIncome) {
      final named = _nameBeforeIncomeVerb(after);
      if (named.isNotEmpty) return named;
    }
    final second = isIncome ? fromAfter() : _clean(before);
    if (second.isNotEmpty || isIncome) return second;
    return _fromAfterWithoutPreposition(after);
  }

  /// Quita el título que es solo el nombre del banco («Interbank Ana te ha plineado»).
  String _withoutTitlePrefix(String before) {
    final names = ((_rules['titlePrefixes'] as List?) ?? const []).cast<String>();
    if (names.isEmpty) return before;
    return before
        .replaceFirst(RegExp('^(?:${names.map(RegExp.escape).join('|')})(?![\\p{L}\\p{N}])',
            caseSensitive: false, unicode: true), '')
        .trim();
  }

  /// Ingreso con el monto en el título y el nombre después: «Recibiste S/ 1.5 🙌 ANA PÉREZ
  /// te envió dinero.» (Lemon). Se toma lo que hay entre el monto y el verbo («te envió»).
  String _nameBeforeIncomeVerb(String after) {
    final starts = [
      for (final r in _income)
        if (r.firstMatch(after) case final m?) m.start,
    ];
    if (starts.isEmpty) return '';
    final cut = starts.reduce((a, b) => a < b ? a : b);
    final name = _clean(after.substring(0, cut));
    return name.length >= 2 && name.length <= 60 ? name : '';
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
    // Emojis de los títulos («¡Recibiste un Plin! 💸»).
    t = t.replaceAll(RegExp(r'\p{So}', unicode: true), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t.replaceAll(RegExp(r'^[\s:,\-¡!.*_]+|[\s:,\-¡!.*_]+$'), '');
  }
}
