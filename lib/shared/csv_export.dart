import '../domain/categoria_propia.dart';
import '../domain/entities/movimiento.dart';
import 'category_display.dart';

String _quote(String value) => '"${value.replaceAll('"', '""')}"';

/// Entre comillas solo si hace falta (los nombres propios pueden traer comas).
String _quoteIfNeeded(String value) =>
    value.contains(RegExp(r'[",\n\r]')) ? _quote(value) : value;

/// CSV de movimientos. No incluye la ubicación: solo viaja lo que el usuario
/// ve en la lista.
String movimientosToCsv(
  Iterable<Movimiento> movimientos, {
  List<CategoriaPropia> categoriasPropias = const [],
}) {
  final buffer = StringBuffer()
    ..writeln('ID,Tipo,Monto,Contraparte,Categoria,Fuente,Canal,Estado,Fecha,Notas');
  for (final m in movimientos) {
    buffer.writeln([
      m.id,
      m.tipo.name,
      m.amount.toStringAsFixed(2),
      _quote(m.merchant),
      _quoteIfNeeded(categoryDisplay(m.category, m.categoriaPropia, categoriasPropias).label),
      m.source.name,
      m.canal.name,
      m.estado.name,
      m.date.toIso8601String(),
      _quote(m.notes),
    ].join(','));
  }
  return buffer.toString();
}
