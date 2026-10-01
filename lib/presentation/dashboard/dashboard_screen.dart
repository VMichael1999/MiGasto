import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/big_amount.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/movement_row.dart';
import '../expenses/expense_detail_dialog.dart';
import '../providers.dart';

enum _BudgetState { ok, warning, over }

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesStateProvider);
    final budget = ref.watch(budgetProvider);

    final now = DateTime.now();
    bool isThisMonth(Movimiento m) => m.date.year == now.year && m.date.month == now.month;

    // Solo lo confirmado suma; lo pendiente se muestra aparte.
    final confirmedMonth = expenses.where((m) => m.isConfirmed && isThisMonth(m)).toList();
    final spent = confirmedMonth.where((m) => m.esGasto).fold(0.0, (sum, m) => sum + m.amount);
    final income = confirmedMonth.where((m) => m.esIngreso).fold(0.0, (sum, m) => sum + m.amount);
    final balance = income - spent;

    final pending = expenses.where((m) => m.estado == EstadoMovimiento.pendiente).toList();
    final today = expenses
        .where((m) =>
            m.date.year == now.year && m.date.month == now.month && m.date.day == now.day)
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(now: now),
              const SizedBox(height: 14),
              _Balance(balance: balance),
              const SizedBox(height: 14),
              _IncomeExpenseTiles(income: income, spent: spent),
              const SizedBox(height: 14),
              if (pending.isNotEmpty) ...[
                _PendingBanner(pending: pending),
              ],
              if (budget > 0) ...[
                const SizedBox(height: 14),
                _BudgetProgress(spent: spent, budget: budget, now: now),
              ],
              const SizedBox(height: 14),
              _TodaySection(movements: today),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final month = toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(now));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(month, style: theme.textTheme.headlineMedium),
            const SizedBox(width: 4),
            AppIcon(
              AppIcons.expand,
              size: AppIconSize.small,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        Tooltip(
          message: 'Buscar movimientos',
          child: Semantics(
            button: true,
            label: 'Buscar movimientos',
            excludeSemantics: true,
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: () => context.go('/expenses'),
                child: SizedBox(
                  width: AppSizes.iconButton,
                  height: AppSizes.iconButton,
                  child: Center(
                    child: AppIcon(AppIcons.search, color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final negative = balance < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Te quedan de este mes',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        BigAmount(
          balance.abs(),
          prefix: negative ? '− S/' : 'S/',
          color: negative ? context.appColors.budgetOver : null,
        ),
      ],
    );
  }
}

class _IncomeExpenseTiles extends StatelessWidget {
  const _IncomeExpenseTiles({required this.income, required this.spent});

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tile(
            icon: AppIcons.arrowUp,
            label: 'Ingresos',
            value: income,
            iconColor: context.appColors.income,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Tile(
            icon: AppIcons.arrowDown,
            label: 'Gastos',
            value: spent,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final AppIcons icon;
  final String label;
  final double value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: '$label, ${formatSoles(value).replaceAll('S/', 'soles')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(icon, size: 14, color: iconColor ?? scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(label, style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatSoles(value),
              style: AppText.amount(theme.textTheme.titleMedium!.copyWith(
                fontSize: 17,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de lo que espera confirmación del usuario. No suma al saldo.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.pending});

  final List<Movimiento> pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final count = pending.length;
    final allIncome = pending.every((m) => m.esIngreso);
    final noun = allIncome
        ? (count == 1 ? 'ingreso' : 'ingresos')
        : (count == 1 ? 'movimiento' : 'movimientos');
    final incomeTotal = pending.where((m) => m.esIngreso).fold(0.0, (s, m) => s + m.amount);
    final bodyStyle = theme.textTheme.bodyMedium!.copyWith(fontSize: 13);

    return Semantics(
      button: true,
      label: '$count $noun por confirmar',
      excludeSemantics: true,
      child: Material(
        color: colors.pendingReviewSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/expenses'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AppIcon(AppIcons.info,
                      size: AppIconSize.small, color: colors.pendingReview),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(
                            text: '$count $noun',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' por confirmar'),
                        ],
                      ),
                    ),
                  ),
                  if (incomeTotal > 0)
                    Text(
                      '+ ${formatSoles(incomeTotal)}',
                      style: AppText.amount(bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.pendingReview,
                      )),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.spent,
    required this.budget,
    required this.now,
  });

  final double spent;
  final double budget;
  final DateTime now;

  _BudgetState get _state {
    final ratio = spent / budget;
    if (ratio > 1.0) return _BudgetState.over;
    if (ratio >= 0.75) return _BudgetState.warning;
    return _BudgetState.ok;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final ratio = spent / budget;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthFraction = (now.day / daysInMonth).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    late final Color color;
    late final AppIcons icon;
    late final String status;
    switch (_state) {
      case _BudgetState.ok:
        color = colors.budgetOk;
        icon = AppIcons.checkCircle;
        status = 'Gastos: vas bien';
      case _BudgetState.warning:
        color = colors.budgetWarning;
        icon = AppIcons.alert;
        status = 'Gastos: cerca del límite';
      case _BudgetState.over:
        color = colors.budgetOver;
        icon = AppIcons.alert;
        status = 'Gastos: te pasaste';
    }

    final statusStyle = theme.textTheme.bodyMedium!.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppIcon(icon, size: AppIconSize.small, color: color),
                const SizedBox(width: 6),
                Text(status, style: statusStyle),
              ],
            ),
            Text(
              '$percent % de S/ ${NumberFormat('#,##0', 'en').format(budget)}',
              style: AppText.amount(theme.textTheme.bodySmall!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              '$percent % del presupuesto de gastos usado, ${(monthFraction * 100).round()} % del mes transcurrido',
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: AppSizes.track,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(AppSizes.track),
                      ),
                    ),
                    Container(
                      width: width * ratio.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppSizes.track),
                      ),
                    ),
                    Positioned(
                      left: (width * monthFraction - 1).clamp(0.0, width - 2),
                      top: -4,
                      bottom: -4,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TodaySection extends ConsumerWidget {
  const _TodaySection({required this.movements});

  final List<Movimiento> movements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hoy', style: theme.textTheme.titleMedium),
            TextButton(
              onPressed: () => context.go('/expenses'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Ver todos',
                style: theme.textTheme.labelLarge!.copyWith(
                  fontSize: 13,
                  color: colors.brandInk,
                ),
              ),
            ),
          ],
        ),
        if (movements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Hoy aún no registras movimientos.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        for (var i = 0; i < movements.length; i++) ...[
          if (i > 0) Divider(color: theme.colorScheme.outline, height: 1),
          MovementRow(
            icon: categoryIcon(movements[i].category),
            title: movements[i].merchant,
            amount: movements[i].amount,
            sourceName: movements[i].source.name,
            sourceLabel: sourceLabel(movements[i].source),
            time: timeFormat.format(movements[i].date),
            isIncome: movements[i].esIngreso,
            isPending: movements[i].estado == EstadoMovimiento.pendiente,
            onTap: () => showExpenseDetailSheet(context, ref, movements[i]),
          ),
        ],
      ],
    );
  }
}
