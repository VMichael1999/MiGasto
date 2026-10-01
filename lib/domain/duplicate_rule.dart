import 'entities/movimiento.dart';

/// Ventana en la que un pago con el mismo monto y fuente se considera el mismo
/// (p. ej. llega por la notificación y por la pantalla de confirmación).
const Duration duplicateWindow = Duration(minutes: 2);

/// `true` si ya existe un movimiento con el mismo monto y fuente dentro de la
/// ventana de [duplicateWindow] alrededor de [date].
bool isDuplicateMovement(
  Iterable<Movimiento> existing, {
  required double amount,
  required PaymentSource source,
  required DateTime date,
  TipoMovimiento? tipo,
}) {
  for (final m in existing) {
    if (m.source != source) continue;
    if ((m.amount - amount).abs() > 0.004) continue;
    if (tipo != null && m.tipo != tipo) continue;
    if (m.date.difference(date).abs() <= duplicateWindow) return true;
  }
  return false;
}
