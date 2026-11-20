import 'entities/movimiento.dart';

/// Un pago o un cobro que el usuario espera en una fecha: el alquiler, una
/// suscripción, el sueldo… Puede repetirse cada mes.
class ScheduledPayment {
  const ScheduledPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.tipo,
    required this.category,
    required this.dueDate,
    this.monthly = false,
  });

  final String id;
  final String name;
  final double amount;
  final TipoMovimiento tipo;
  final Categoria category;

  /// Fecha de vencimiento (solo cuenta el día).
  final DateTime dueDate;
  final bool monthly;

  bool get esIngreso => tipo == TipoMovimiento.ingreso;

  /// Vencido: la fecha ya pasó y sigue sin marcarse como pagado.
  bool isOverdue(DateTime now) => dateOnly(dueDate).isBefore(dateOnly(now));

  ScheduledPayment copyWith({
    String? name,
    double? amount,
    TipoMovimiento? tipo,
    Categoria? category,
    DateTime? dueDate,
    bool? monthly,
  }) =>
      ScheduledPayment(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        tipo: tipo ?? this.tipo,
        category: category ?? this.category,
        dueDate: dueDate ?? this.dueDate,
        monthly: monthly ?? this.monthly,
      );

  /// El mismo pago un mes después (el día se ajusta si el mes es más corto).
  ScheduledPayment nextMonth() => copyWith(dueDate: addMonths(dueDate, 1));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'tipo': tipo.name,
        'category': category.name,
        'dueDate': dateOnly(dueDate).toIso8601String(),
        'monthly': monthly,
      };

  static ScheduledPayment? fromJson(Map<String, dynamic> j) {
    try {
      return ScheduledPayment(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        tipo: TipoMovimiento.values.byName(j['tipo'] as String),
        category: Categoria.values.byName(j['category'] as String),
        dueDate: DateTime.parse(j['dueDate'] as String),
        monthly: j['monthly'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Suma [months] meses; si el día no existe en el mes destino (31 → febrero),
/// usa el último día de ese mes.
DateTime addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

/// Los que vencen dentro de [horizonDays] días, más los ya vencidos que siguen
/// pendientes, del más urgente al más lejano.
List<ScheduledPayment> upcomingPayments(
  List<ScheduledPayment> all,
  DateTime now, {
  int horizonDays = 30,
}) {
  final limit = dateOnly(now).add(Duration(days: horizonDays));
  final out = all.where((p) => !dateOnly(p.dueDate).isAfter(limit)).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return out;
}
