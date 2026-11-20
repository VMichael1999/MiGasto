import 'entities/movimiento.dart';

/// Lo gastado (o ingresado) en un mes, para la comparación.
class MonthTotal {
  const MonthTotal({required this.month, required this.total, required this.count});

  /// Primer día del mes.
  final DateTime month;
  final double total;
  final int count;
}

/// Comparación de un movimiento con sus parecidos anteriores.
class MovementComparison {
  const MovementComparison({
    required this.byMerchant,
    required this.previous,
    required this.months,
  });

  /// `true` si se compara con el mismo comercio o persona; `false` si, por no
  /// haber antecedentes, se compara con la categoría.
  final bool byMerchant;

  /// La vez anterior que se registró lo mismo (solo si [byMerchant]).
  final Movimiento? previous;

  /// Totales de los últimos meses, del más antiguo al del movimiento.
  final List<MonthTotal> months;

  MonthTotal get current => months.last;

  /// El mes anterior al del movimiento, si hubo algo.
  MonthTotal? get previousMonth =>
      months.length >= 2 && months[months.length - 2].total > 0 ? months[months.length - 2] : null;

  /// Cambio del mes del movimiento frente al anterior, en %; `null` si no hay
  /// con qué comparar.
  double? get monthChangePercent {
    final p = previousMonth;
    if (p == null) return null;
    return (current.total - p.total) / p.total * 100;
  }

  /// Promedio de los meses anteriores que tuvieron movimiento.
  double? get averageOfPreviousMonths {
    final prior = months.take(months.length - 1).where((m) => m.total > 0).toList();
    if (prior.isEmpty) return null;
    return prior.fold<double>(0, (s, m) => s + m.total) / prior.length;
  }

  /// ¿Hay algo con qué comparar (una vez anterior o un mes anterior)?
  bool get hasHistory => previous != null || previousMonth != null;
}

String _norm(String s) => s.trim().toLowerCase();

/// Compara [m] con los movimientos confirmados de [all].
///
/// Si ya se había registrado lo mismo (mismo comercio o persona y mismo tipo),
/// se compara con eso; si no, con la categoría. Los totales cubren [monthsBack]
/// meses terminando en el mes del movimiento.
MovementComparison compareMovement(
  Movimiento m,
  List<Movimiento> all, {
  int monthsBack = 4,
}) {
  final sameKind = all.where((e) => e.isConfirmed && e.id != m.id && e.tipo == m.tipo);

  bool sameMerchant(Movimiento e) => _norm(e.merchant) == _norm(m.merchant);
  final earlier = sameKind.where((e) => sameMerchant(e) && e.date.isBefore(m.date)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final hasMerchantHistory = sameKind.any(sameMerchant);

  final byMerchant = hasMerchantHistory && _norm(m.merchant).isNotEmpty;
  bool matches(Movimiento e) => byMerchant ? sameMerchant(e) : e.category == m.category;

  final months = <MonthTotal>[];
  for (var back = monthsBack - 1; back >= 0; back--) {
    final month = DateTime(m.date.year, m.date.month - back, 1);
    final inMonth = [
      // El propio movimiento cuenta en su mes.
      if (m.isConfirmed || back == 0) m,
      ...sameKind.where(matches),
    ].where((e) => e.date.year == month.year && e.date.month == month.month).toList();
    months.add(MonthTotal(
      month: month,
      total: inMonth.fold(0.0, (s, e) => s + e.amount),
      count: inMonth.length,
    ));
  }

  return MovementComparison(
    byMerchant: byMerchant,
    previous: byMerchant && earlier.isNotEmpty ? earlier.first : null,
    months: months,
  );
}
