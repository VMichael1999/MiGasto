import '../domain/entities/movimiento.dart';
import 'labels.dart';

/// Un comercio (o, en ingresos, una persona) que ya se usó, para sugerirlo al registrar.
class MerchantSuggestion {
  const MerchantSuggestion(this.name, this.category, this.source);

  /// Como se escribió la última vez.
  final String name;

  /// La categoría y la fuente de la última vez: dan su ícono si no tiene logo.
  final Categoria category;
  final PaymentSource source;
}

/// Comercios ya usados del mismo tipo (gastos o ingresos), los más frecuentes primero y, a
/// igual cantidad, los más recientes. Con [query], solo los que la contienen (sin importar
/// mayúsculas ni tildes); el que ya está escrito tal cual no se sugiere.
///
/// No se sugieren los nombres que la app pone sola: el de la categoría (un registro sin
/// comercio) ni «Desconocido».
List<MerchantSuggestion> merchantSuggestions(
  List<Movimiento> all, {
  required TipoMovimiento tipo,
  String query = '',
  int limit = 6,
}) {
  final automatic = {
    for (final c in Categoria.values) _fold(categoryLabel(c)),
    _fold('Desconocido'),
  };
  final q = _fold(query);
  final counts = <String, int>{};
  final latest = <String, Movimiento>{};
  for (final m in all) {
    if (m.tipo != tipo) continue;
    final key = _fold(m.merchant);
    if (key.isEmpty || automatic.contains(key)) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    final seen = latest[key];
    if (seen == null || m.date.isAfter(seen.date)) latest[key] = m;
  }
  final keys = counts.keys.where((k) => k.contains(q) && k != q).toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : latest[b]!.date.compareTo(latest[a]!.date);
    });
  return [
    for (final k in keys.take(limit))
      MerchantSuggestion(latest[k]!.merchant.trim(), latest[k]!.category, latest[k]!.source),
  ];
}

/// Minúsculas, sin tildes y sin espacios de más: «  Café   Tambo » y «cafe tambo» son lo mismo.
String _fold(String s) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  final lower = s.toLowerCase().split('').map((c) => tildes[c] ?? c).join();
  return lower.trim().replaceAll(RegExp(r'\s+'), ' ');
}
