import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/movimiento.dart';

/// Clasifica por palabras clave (no es IA). Las reglas están en
/// `assets/category_rules.json`, el mismo archivo que lee la ventana flotante
/// de Android. Se busca la palabra o frase completa: "Luz María" no es
/// "Servicios" ni "Metropolitano" es "Compras".
class NlpClassifierService {
  static List<_Group>? _gasto;
  static List<_Group>? _ingreso;
  static Categoria _gastoDefault = Categoria.otros;
  static Categoria _ingresoDefault = Categoria.transferenciaRecibida;

  static bool get isConfigured => _gasto != null;

  static Future<void> loadFromAsset([
    String path = 'assets/category_rules.json',
  ]) async =>
      configure(await rootBundle.loadString(path));

  static void configure(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    _gasto = _groups(map['gasto']);
    _ingreso = _groups(map['ingreso']);
    _gastoDefault = _byName(map['gastoDefault'] as String, Categoria.otros);
    _ingresoDefault =
        _byName(map['ingresoDefault'] as String, Categoria.transferenciaRecibida);
  }

  static Categoria _byName(String name, Categoria fallback) {
    for (final c in Categoria.values) {
      if (c.name == name) return c;
    }
    return fallback;
  }

  static List<_Group> _groups(dynamic list) => (list as List).map((g) {
        final m = g as Map<String, dynamic>;
        final words = (m['keywords'] as List).cast<String>().map((k) => RegExp(
              '(?<![\\p{L}\\p{N}])${RegExp.escape(k)}(?![\\p{L}\\p{N}])',
              caseSensitive: false,
              unicode: true,
            ));
        return _Group(_byName(m['category'] as String, Categoria.otros), words.toList());
      }).toList();

  static Categoria? _match(List<_Group> groups, String text) {
    for (final g in groups) {
      if (g.patterns.any((p) => p.hasMatch(text))) return g.category;
    }
    return null;
  }

  static void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
          'NlpClassifierService no está configurado: llama a loadFromAsset() al iniciar.');
    }
  }

  /// Categoría de un gasto.
  static Categoria classify(String text, String peerName) {
    _ensureConfigured();
    return _match(_gasto!, '$text $peerName') ?? _gastoDefault;
  }

  /// Categoría de un ingreso.
  static Categoria classifyIncome(String text, String peerName) {
    _ensureConfigured();
    return _match(_ingreso!, '$text $peerName') ?? _ingresoDefault;
  }
}

class _Group {
  _Group(this.category, this.patterns);
  final Categoria category;
  final List<RegExp> patterns;
}
