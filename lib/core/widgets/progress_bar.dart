import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

enum ProgressState { ok, warning, over }

/// Barra de progreso de 6 px (o 4 px en modo slim) con animación suave
/// y color adaptado al estado (verde, ámbar, rojo).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.percent,
    this.height = AppSizes.track,
    this.color,
    this.backgroundColor = MgColors.soft,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  /// Valor entre 0.0 y 1.0 (o superior si se sobrepasa el límite)
  final double percent;
  final double height;
  final Color? color;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  Color get _statusColor {
    if (color != null) return color!;
    if (percent > 1.0) return MgColors.down;
    if (percent >= 0.75) return MgColors.warn;
    return MgColors.up;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clamped,
              height: height,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Componente LimitHint: «Te quedarán S/ X después de este gasto»
/// o advertencia en rojo «Te pasas S/ X del límite de [categoría]».
class LimitHint extends StatelessWidget {
  const LimitHint({
    super.key,
    required this.remainingAfterExpense,
    required this.limit,
    required this.categoryName,
    this.spentBeforeExpense = 0,
    this.expenseAmount = 0,
  });

  final double remainingAfterExpense;
  final double limit;
  final String categoryName;
  final double spentBeforeExpense;
  final double expenseAmount;

  @override
  Widget build(BuildContext context) {
    final totalAfter = spentBeforeExpense + expenseAmount;
    final isExceeded = remainingAfterExpense < 0;
    final exceededAmount = remainingAfterExpense.abs();
    final percent = limit > 0 ? (totalAfter / limit) : 0.0;

    final String text;
    final Color textColor;
    if (limit <= 0) {
      text = 'Sin límite asignado';
      textColor = MgColors.ink2;
    } else if (isExceeded) {
      text = 'Te pasas S/ ${NumberFormat('#,##0.00', 'es_PE').format(exceededAmount)} del límite de $categoryName.';
      textColor = MgColors.down;
    } else {
      text = 'Te quedarán S/ ${NumberFormat('#,##0.00', 'es_PE').format(remainingAfterExpense)} después de este gasto.';
      textColor = MgColors.ink2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isExceeded ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        if (limit > 0) ...[
          const SizedBox(height: 7),
          ProgressBar(
            percent: percent,
            height: 4,
            color: isExceeded ? MgColors.down : (percent >= 0.75 ? MgColors.warn : MgColors.up),
          ),
        ],
      ],
    );
  }
}
