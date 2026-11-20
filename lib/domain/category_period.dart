import 'entities/movimiento.dart';

/// Período que se mira en el detalle de una categoría.
enum DetailPeriod { quincenal, mensual, trimestral, semestral }

/// Rango de fechas: [start] incluido y [end] excluido.
class PeriodRange {
  const PeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

DateTime _firstOfMonth(int year, int month) => DateTime(year, month, 1);

/// El período de tipo [p] que contiene a [anchor]:
/// - quincenal: del 1 al 15, o del 16 al fin de mes;
/// - mensual: el mes;
/// - trimestral: el trimestre del año (ene–mar, abr–jun, jul–sep, oct–dic);
/// - semestral: el semestre (ene–jun, jul–dic).
PeriodRange periodRange(DetailPeriod p, DateTime anchor) {
  final y = anchor.year;
  final m = anchor.month;
  switch (p) {
    case DetailPeriod.quincenal:
      return anchor.day <= 15
          ? PeriodRange(DateTime(y, m, 1), DateTime(y, m, 16))
          : PeriodRange(DateTime(y, m, 16), _firstOfMonth(y, m + 1));
    case DetailPeriod.mensual:
      return PeriodRange(_firstOfMonth(y, m), _firstOfMonth(y, m + 1));
    case DetailPeriod.trimestral:
      final q = (m - 1) ~/ 3;
      return PeriodRange(_firstOfMonth(y, q * 3 + 1), _firstOfMonth(y, q * 3 + 4));
    case DetailPeriod.semestral:
      final h = (m - 1) ~/ 6;
      return PeriodRange(_firstOfMonth(y, h * 6 + 1), _firstOfMonth(y, h * 6 + 7));
  }
}

/// Un punto del ancla en el período anterior (-1) o siguiente (+1).
DateTime shiftAnchor(DetailPeriod p, DateTime anchor, int direction) {
  final r = periodRange(p, anchor);
  if (direction >= 0) return r.end; // el primer día del siguiente período
  return r.start.subtract(const Duration(days: 1)); // el último día del anterior
}

/// Total de un tramo de la evolución.
class BucketTotal {
  const BucketTotal({required this.start, required this.end, required this.total});

  final DateTime start;
  final DateTime end;
  final double total;
}

/// Reparte [movements] en tramos dentro de [range]: de 3 días en una quincena,
/// de 7 días en un mes y de un mes en un trimestre o un semestre.
List<BucketTotal> evolutionBuckets(
  List<Movimiento> movements,
  PeriodRange range,
  DetailPeriod p,
) {
  final out = <BucketTotal>[];
  var start = range.start;
  while (start.isBefore(range.end)) {
    late final DateTime next;
    switch (p) {
      case DetailPeriod.quincenal:
        next = DateTime(start.year, start.month, start.day + 3);
      case DetailPeriod.mensual:
        next = DateTime(start.year, start.month, start.day + 7);
      case DetailPeriod.trimestral:
      case DetailPeriod.semestral:
        next = DateTime(start.year, start.month + 1, 1);
    }
    final end = next.isAfter(range.end) ? range.end : next;
    final total = movements
        .where((m) => !m.date.isBefore(start) && m.date.isBefore(end))
        .fold(0.0, (s, m) => s + m.amount);
    out.add(BucketTotal(start: start, end: end, total: total));
    start = end;
  }
  return out;
}

/// Cuánto de lo gastado en el período corresponde a la categoría, en %.
/// `null` si no se gastó nada en el período.
double? categoryShare(double categoryTotal, double allTotal) =>
    allTotal > 0 ? categoryTotal / allTotal * 100 : null;
