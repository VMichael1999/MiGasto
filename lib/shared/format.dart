import 'package:intl/intl.dart';

import '../domain/entities/movimiento.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en');

/// `3465` -> `3,465.00` (sin símbolo de moneda).
String formatAmount(double value) => _amountFormat.format(value);

/// `25.5` -> `S/ 25.50`.
String formatSoles(double value) => 'S/ ${formatAmount(value)}';

/// Lo que se ve en lugar de un monto cuando el usuario oculta el saldo.
const String hiddenAmount = '••••';

/// `S/ 25.50`, o `S/ ••••` si los montos están ocultos.
String solesOrHidden(double value, bool hidden) =>
    hidden ? 'S/ $hiddenAmount' : formatSoles(value);

/// `US$ 20.00` para dólares; otra moneda, con su código.
String formatMoneda(String moneda, double value) =>
    '${moneda == 'USD' ? r'US$' : moneda} ${formatAmount(value)}';

/// Lo que va bajo el nombre en las listas: la categoría (o «Entre mis cuentas») y, si el
/// cargo fue en dólares, el monto original («Entretenimiento · US$ 20.00»).
String movementSubtitle(Movimiento m, String categoria, {bool hidden = false}) {
  final first = m.entreMisCuentas ? 'Entre mis cuentas' : categoria;
  if (!m.esEnOtraMoneda) return first;
  final original = hidden ? '${m.moneda == 'USD' ? r'US$' : m.moneda} $hiddenAmount' : formatMoneda(m.moneda!, m.montoOriginal!);
  return '$first · $original';
}
