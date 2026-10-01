import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../presentation/providers.dart';
import '../format.dart';
import 'app_icons.dart';

/// Fila de movimiento: ícono, nombre, punto de color de la fuente, hora y monto
/// alineado a la derecha. Los ingresos van en azul con signo `+`; los pendientes
/// llevan la etiqueta "Por confirmar".
class MovementRow extends ConsumerWidget {
  const MovementRow({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.sourceName,
    required this.sourceLabel,
    required this.time,
    this.isIncome = false,
    this.isPending = false,
    this.onTap,
  });

  final AppIcons icon;
  final String title;
  final double amount;
  final String sourceName;
  final String sourceLabel;
  final String time;
  final bool isIncome;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(balanceHiddenProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final text = theme.textTheme;

    final shownSoles = solesOrHidden(amount, hidden);
    final amountText = isIncome ? '+ $shownSoles' : shownSoles;
    final amountColor = isIncome ? colors.income : scheme.onSurface;

    final semantics = [
      isIncome ? 'Ingreso' : 'Gasto',
      title,
      hidden ? 'monto oculto' : formatSoles(amount).replaceAll('S/', 'soles'),
      sourceLabel,
      time,
      if (isPending) 'por confirmar',
    ].join(', ');

    return Semantics(
      button: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppSizes.categoryIcon,
                  height: AppSizes.categoryIcon,
                  decoration: BoxDecoration(
                    color: isIncome ? colors.incomeSoft : scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.icon),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    icon,
                    size: AppIconSize.small,
                    color: isIncome ? colors.income : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.sourceColor(sourceName),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$sourceLabel · $time',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.amount(text.bodySmall!.copyWith(
                                fontSize: 12,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      textAlign: TextAlign.right,
                      style: AppText.amount(text.titleMedium!.copyWith(
                        color: amountColor,
                      )),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.pendingReviewSoft,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          'Por confirmar',
                          style: text.labelSmall!.copyWith(
                            color: colors.pendingReview,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
