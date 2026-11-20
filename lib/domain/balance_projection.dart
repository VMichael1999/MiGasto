import 'entities/movimiento.dart';

/// Estimación del saldo dentro de [horizonDays] días.
class BalanceProjection {
  const BalanceProjection({
    required this.projected,
    required this.dailyNet,
    required this.horizonDays,
  });

  /// Saldo estimado al final del horizonte.
  final double projected;

  /// Lo que, en promedio, entra (o sale, si es negativo) cada día.
  final double dailyNet;
  final int horizonDays;
}

/// Mínimo de movimientos confirmados para que la estimación tenga sentido.
const int projectionMinMovements = 3;

/// Estima el saldo a [horizonDays] días a partir del ritmo real de los últimos
/// 30 días. Devuelve `null` si hay pocos movimientos: así no se muestra una
/// cifra inventada.
///
/// El promedio diario es (ingresos − gastos) de la ventana dividido entre los
/// días transcurridos desde el primer movimiento (mínimo 7, para que un solo
/// día muy movido no dispare la estimación).
BalanceProjection? projectBalance({
  required List<Movimiento> movements,
  required double currentBalance,
  required DateTime now,
  int horizonDays = 30,
  int windowDays = 30,
}) {
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: windowDays - 1));
  final window = movements
      .where((m) => m.isConfirmed && !m.date.isBefore(start) && !m.date.isAfter(now))
      .toList();
  if (window.length < projectionMinMovements) return null;

  final net = window.fold<double>(
    0.0,
    (sum, m) => sum + (m.esIngreso ? m.amount : (m.esGasto ? -m.amount : 0.0)),
  );
  final first = window.map((m) => m.date).reduce((a, b) => a.isBefore(b) ? a : b);
  final elapsed = DateTime(now.year, now.month, now.day)
          .difference(DateTime(first.year, first.month, first.day))
          .inDays +
      1;
  final days = elapsed < 7 ? 7 : elapsed;
  final dailyNet = net / days;
  return BalanceProjection(
    projected: currentBalance + dailyNet * horizonDays,
    dailyNet: dailyNet,
    horizonDays: horizonDays,
  );
}
