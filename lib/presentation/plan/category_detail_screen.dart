import '../expenses/movement_comparison_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../providers.dart';
import 'plan_providers.dart';

/// Pantalla de detalle de categoría (#s-catdet / R.catdet en migasto-prototipo.html)
/// - Cabecera (.nav): Botón atrás, nombre de categoría, botón editar (.rnd).
/// - Hero (.cd-hero): Squircle 58×58, monto gastado del mes en 34px bold, contador de movimientos.
/// - Tarjeta de límite: Límite del mes con ProgressBar, gastado / límite, «Te quedan» (o botón «Ponerle un límite»).
/// - Lista de movimientos del mes agrupada por día con SwipeToDelete, CategoryIcon y MoneyText.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  Categoria _parseCategory() {
    for (final c in Categoria.values) {
      if (c.name.toLowerCase() == categoryId.toLowerCase()) return c;
    }
    return Categoria.compras;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = _parseCategory();
    final isHidden = ref.watch(balanceHiddenProvider);
    final expenses = ref.watch(expensesStateProvider);
    final limits = ref.watch(categoryLimitsProvider);

    final now = DateTime.now();
    final movementsThisMonth = expenses
        .where((m) =>
            m.isConfirmed &&
            m.category == category &&
            m.date.year == now.year &&
            m.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = movementsThisMonth
        .where((m) => m.esGasto)
        .fold(0.0, (sum, m) => sum + m.amount);

    final categoryLimit = limits.where((l) => l.category == category).firstOrNull;

    final catColor = CategoryIcon.colorForCategory(category);
    final iconData = CategoryIcon.iconForCategory(category);

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera (.nav)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: MgColors.soft,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: MgColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      categoryLabel(category),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: MgColors.ink,
                      ),
                    ),
                    Material(
                      color: MgColors.soft,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => MgToast.show(
                          context,
                          message: 'Editarías la categoría.',
                        ),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: MgColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Hero (.cd-hero)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: Column(
                  children: [
                    // Squircle 58×58
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 28,
                          color: catColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Monto grande del mes
                    Text(
                      isHidden ? '••••' : formatSoles(totalSpent),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: MgColors.ink,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${movementsThisMonth.length} movimiento${movementsThisMonth.length == 1 ? '' : 's'} en ${DateFormat('MMMM', 'es').format(now)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Tarjeta de límite (.card)
              if (categoryLimit != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: MgColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MgColors.line),
                    ),
                    child: Builder(
                      builder: (context) {
                        final limitVal = categoryLimit.limit;
                        final pct = (totalSpent / limitVal).clamp(0.0, 1.0);
                        final pctInt = (pct * 100).round();
                        final isHigh = pct >= 0.8;
                        final remains = limitVal - totalSpent;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.shield_outlined,
                                      size: 15,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Expanded(
                                  child: Text(
                                    'Límite del mes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: MgColors.ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$pctInt%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isHigh ? MgColors.warn : MgColors.up,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ProgressBar(
                              percent: pct,
                              height: 6,
                              color: isHigh ? MgColors.warn : catColor,
                            ),
                            const SizedBox(height: 9),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  isHidden ? '••••' : formatSoles(totalSpent),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: MgColors.ink,
                                    letterSpacing: -0.5,
                                    fontFeatures: AppText.tabular,
                                  ),
                                ),
                                Text(
                                  ' / ${formatSoles(limitVal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: MgColors.ink2,
                                    fontFeatures: AppText.tabular,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (remains >= 0)
                              Text(
                                'Te quedan ${formatSoles(remains)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: MgColors.ink3,
                                ),
                              )
                            else
                              Text(
                                'Te pasas ${formatSoles(remains.abs())}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: MgColors.down,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                // Botón «Ponerle un límite»
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/limit/new?cat=${category.name}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MgColors.line,
                            width: 1.4,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 17, color: MgColors.ink2),
                            SizedBox(width: 8),
                            Text(
                              'Ponerle un límite',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: MgColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // 4. Sección Movimientos
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                child: Row(
                  children: [
                    const Text(
                      'Movimientos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MgColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: MgColors.soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${movementsThisMonth.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MgColors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (movementsThisMonth.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    message: 'No hay gastos registrados en esta categoría este mes.',
                  ),
                )
              else
                _buildGroupedMovements(context, ref, movementsThisMonth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedMovements(
    BuildContext context,
    WidgetRef ref,
    List<Movimiento> movements,
  ) {
    final Map<String, List<Movimiento>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final m in movements) {
      final date = DateTime(m.date.year, m.date.month, m.date.day);
      String dayKey;
      if (date == today) {
        dayKey = 'Hoy';
      } else if (date == yesterday) {
        dayKey = 'Ayer';
      } else {
        dayKey = DateFormat("EEEE, d 'de' MMMM", 'es').format(date);
        dayKey = dayKey[0].toUpperCase() + dayKey.substring(1);
      }
      grouped.putIfAbsent(dayKey, () => []).add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: MgColors.ink2,
              ),
            ),
          ),
          for (final m in entry.value)
            SwipeToDelete(
              itemKey: ValueKey(m.id),
              confirmTitle: '¿Eliminar ${m.merchant}?',
              confirmMessage: 'Vas a eliminar este gasto de ${formatSoles(m.amount)}.',
              onDelete: () async {
                final notifier = ref.read(expensesStateProvider.notifier);
                await notifier.deleteExpense(m.id);
                if (context.mounted) {
                  MgToast.show(
                    context,
                    message: '${m.merchant} eliminado',
                    actionLabel: 'Deshacer',
                    onAction: () async {
                      await notifier.restoreExpense(m);
                    },
                  );
                }
              },
              child: LongPressMenu(
                onAction: (action) async {
                  switch (action) {
                    case MgMenuAction.edit:
                      context.push('/movement/${m.id}');
                      break;
                    case MgMenuAction.compare:
                      showMovementComparison(context, m);
                      break;
                    case MgMenuAction.delete:
                      final ok = await ConfirmSheet.show(
                        context,
                        title: '¿Eliminar ${m.merchant}?',
                        message: 'Vas a eliminar este gasto de ${formatSoles(m.amount)}.',
                        confirmLabel: 'Eliminar',
                        isDestructive: true,
                      );
                      if (ok && context.mounted) {
                        final notifier = ref.read(expensesStateProvider.notifier);
                        await notifier.deleteExpense(m.id);
                        if (context.mounted) {
                          MgToast.show(
                            context,
                            message: '${m.merchant} eliminado',
                            actionLabel: 'Deshacer',
                            onAction: () => notifier.restoreExpense(m),
                          );
                        }
                      }
                      break;
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/movement/${m.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Row(
                        children: [
                          CategoryIcon(category: m.category, size: 38, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        m.merchant,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: MgColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (m.notes.toLowerCase().contains('recurrente') ||
                                        m.category == Categoria.entretenimiento) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: MgColors.acc,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.notes.isNotEmpty ? m.notes : categoryLabel(m.category),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: MgColors.ink2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          MoneyText(
                            amount: m.amount,
                            isExpense: m.esGasto,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
