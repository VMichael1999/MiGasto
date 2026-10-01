import '../domain/entities/movimiento.dart';
import 'labels.dart';

String _quote(String value) => '"${value.replaceAll('"', '""')}"';

/// CSV de movimientos. No incluye la ubicación: solo viaja lo que el usuario
/// ve en la lista.
String movimientosToCsv(Iterable<Movimiento> movimientos) {
  final buffer = StringBuffer()
    ..writeln('ID,Tipo,Monto,Contraparte,Categoria,Fuente,Canal,Estado,Fecha,Notas');
  for (final m in movimientos) {
    buffer.writeln([
      m.id,
      m.tipo.name,
      m.amount.toStringAsFixed(2),
      _quote(m.merchant),
      categoryLabel(m.category),
      m.source.name,
      m.canal.name,
      m.estado.name,
      m.date.toIso8601String(),
      _quote(m.notes),
    ].join(','));
  }
  return buffer.toString();
}
