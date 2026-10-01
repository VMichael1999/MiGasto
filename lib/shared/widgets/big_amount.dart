import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../format.dart';

/// Monto con `S/` más chico y cifras tabulares, como en la propuesta:
/// saldo del Resumen (42/21), ventana flotante (38/19), detalle (40/20).
class BigAmount extends StatelessWidget {
  const BigAmount(
    this.value, {
    super.key,
    this.size = 42,
    this.prefix = 'S/',
    this.color,
  });

  final double value;
  final double size;

  /// `S/` o `+ S/` en ingresos.
  final String prefix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.displayLarge!;
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final main = AppText.amount(base.copyWith(
      fontSize: size,
      height: 1.02,
      letterSpacing: -size * 0.03,
      fontWeight: FontWeight.w700,
      color: ink,
    ));
    final small = main.copyWith(
      fontSize: size / 2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$prefix ', style: small),
          TextSpan(text: formatAmount(value), style: main),
        ],
      ),
      semanticsLabel: '$prefix ${formatAmount(value)}'.replaceAll('S/', 'soles'),
    );
  }
}
