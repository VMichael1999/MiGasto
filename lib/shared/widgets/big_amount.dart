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
    this.hidden = false,
    this.countUpFromZero = false,
  });

  final double value;
  final double size;

  /// `S/` o `+ S/` en ingresos.
  final String prefix;
  final Color? color;

  /// Muestra `••••` en lugar del monto.
  final bool hidden;

  /// Al construirse, el número sube desde 0 hasta [value] (al volver a mostrar el saldo).
  final bool countUpFromZero;

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

    Widget build(String shown, String spoken) => Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$prefix ', style: small),
              TextSpan(text: shown, style: main),
            ],
          ),
          semanticsLabel: spoken,
        );

    if (hidden) return build(hiddenAmount, 'monto oculto');
    final spoken = '$prefix ${formatAmount(value)}'.replaceAll('S/', 'soles');
    if (!countUpFromZero) return build(formatAmount(value), spoken);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => build(formatAmount(v), spoken),
    );
  }
}
