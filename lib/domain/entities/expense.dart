enum ExpenseCategory {
  alimentacion,     // Alimentación
  transporte,       // Transporte
  compras,          // Compras
  servicios,        // Servicios (Luz, agua, internet)
  entretenimiento,  // Entretenimiento (Netflix, Cine)
  otros,            // Otros
}

enum PaymentSource {
  yape,
  plin,
  googlePay,
  manual,
}

class Expense {
  final String id;
  final double amount;
  final String merchant;
  final ExpenseCategory category;
  final PaymentSource source;
  final DateTime date;
  final String notes;
  final bool isConfirmed;

  Expense({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.source,
    required this.date,
    this.notes = '',
    this.isConfirmed = false,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? merchant,
    ExpenseCategory? category,
    PaymentSource? source,
    DateTime? date,
    String? notes,
    bool? isConfirmed,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      source: source ?? this.source,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Expense(id: $id, amount: $amount, merchant: $merchant)';
}
