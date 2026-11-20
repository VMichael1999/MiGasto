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

/// Saldo al cierre de cada uno de los últimos [days] días; el último valor es
/// el de hoy ([currentBalance]). Se reconstruye hacia atrás restando lo que
/// entró y salió cada día, así que la curva termina exactamente en el saldo
/// actual.
List<double> balanceHistory({
  required List<Movimiento> movements,
  required double currentBalance,
  required DateTime now,
  int days = 30,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final netByDay = <DateTime, double>{};
  for (final m in movements) {
    if (!m.isConfirmed || m.date.isAfter(now)) continue;
    final day = DateTime(m.date.year, m.date.month, m.date.day);
    final net = m.esIngreso ? m.amount : (m.esGasto ? -m.amount : 0.0);
    netByDay[day] = (netByDay[day] ?? 0) + net;
  }
  final out = List<double>.filled(days, currentBalance);
  for (var i = days - 2; i >= 0; i--) {
    final dayAfter = today.subtract(Duration(days: days - 2 - i));
    out[i] = out[i + 1] - (netByDay[dayAfter] ?? 0);
  }
  return out;
}

/// Puntos de la línea estimada: parte del saldo de hoy y suma el ritmo diario.
List<double> projectedSeries(double currentBalance, BalanceProjection p) => [
      for (var i = 0; i <= p.horizonDays; i++) currentBalance + p.dailyNet * i,
    ];
