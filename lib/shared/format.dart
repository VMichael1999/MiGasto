import 'package:intl/intl.dart';

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
