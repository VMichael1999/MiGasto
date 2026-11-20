import 'entities/movimiento.dart';

/// Cifras del balance del mes en curso, calculadas solo con movimientos reales.
class BalanceSummary {
  const BalanceSummary({
    required this.prevBalance,
    required this.income,
    required this.spent,
  });

  /// Lo que dejó el mes anterior (ingresos − gastos); 0 si no hubo movimientos.
  final double prevBalance;

  /// Ingresos y gastos confirmados del mes en curso.
  final double income;
  final double spent;

  /// Saldo disponible: lo que arrastra el mes anterior más lo del mes.
  double get balance => prevBalance + income - spent;
}

BalanceSummary computeBalanceSummary(List<Movimiento> all, DateTime now) {
  bool inMonth(Movimiento m, DateTime month) =>
      m.isConfirmed && m.date.year == month.year && m.date.month == month.month;
  double sum(Iterable<Movimiento> l) => l.fold(0.0, (s, m) => s + m.amount);

  final thisMonth = all.where((m) => inMonth(m, now)).toList();
  final prev = DateTime(now.year, now.month - 1, 1);
  final prevMonth = all.where((m) => inMonth(m, prev)).toList();

  return BalanceSummary(
    prevBalance:
        sum(prevMonth.where((m) => m.esIngreso)) - sum(prevMonth.where((m) => m.esGasto)),
    income: sum(thisMonth.where((m) => m.esIngreso)),
    spent: sum(thisMonth.where((m) => m.esGasto)),
  );
}
