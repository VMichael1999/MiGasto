import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Formatea un monto según la especificación visual de MiGasto:
/// `S/` más pequeño y a la izquierda, cifras tabulares con espaciado ajustado,
/// color según signo (verde ingresos, rojo gastos), y oculta con puntos (`••••`)
/// cuando el modo privado está activo.
class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.currencySize,
    this.isIncome = false,
    this.isExpense = false,
    this.showSign = true,
    this.showCurrency = true,
    this.color,
    this.hidden = false,
  });

  final double amount;
  final TextStyle? style;
  final double? currencySize;
  final bool isIncome;
  final bool isExpense;
  final bool showSign;
  final bool showCurrency;
  final Color? color;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppText.money(size: 16, weight: FontWeight.w700);
    final fontSize = baseStyle.fontSize ?? 16;
    final currSize = currencySize ?? (fontSize * 0.68).clamp(11.0, 22.0);

    Color textColor;
    if (color != null) {
      textColor = color!;
    } else if (isIncome) {
      textColor = MgColors.up;
    } else if (isExpense) {
      textColor = MgColors.down;
    } else {
      textColor = baseStyle.color ?? MgColors.ink;
    }

    if (hidden) {
      return Text(
        showCurrency ? 'S/ ••••' : '••••',
        style: baseStyle.copyWith(
          color: textColor,
          letterSpacing: 2.0,
          fontFeatures: AppText.tabular,
        ),
      );
    }

    final sign = showSign
        ? (isIncome ? '+ ' : (amount < 0 ? '− ' : (isExpense ? '− ' : '')))
        : '';
    final absAmount = amount.abs();
    final formatted = NumberFormat('#,##0.00', 'es_PE').format(absAmount);

    return Text.rich(
      TextSpan(
        style: baseStyle.copyWith(
          color: textColor,
          fontFeatures: AppText.tabular,
        ),
        children: [
          if (sign.isNotEmpty)
            TextSpan(
              text: sign,
              style: TextStyle(
                fontSize: currSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (showCurrency)
            TextSpan(
              text: 'S/ ',
              style: TextStyle(
                fontSize: currSize,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
          TextSpan(text: formatted),
        ],
      ),
      semanticsLabel: '$sign$formatted soles',
    );
  }
}
