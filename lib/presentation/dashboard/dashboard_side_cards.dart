import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/mg_card.dart';
import '../../core/widgets/progress_bar.dart';
import '../../domain/balance_projection.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../plan/plan_providers.dart';

const _cardMargin = EdgeInsets.fromLTRB(0, 0, 0, 10);

Widget _cardTitle(String text, {Widget? trailing}) => Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MgColors.ink,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );

/// «Presupuestos»: avance de los límites por categoría que el usuario definió.
class LimitsOverviewCard extends StatelessWidget {
  const LimitsOverviewCard({
    super.key,
    required this.limits,
    required this.monthExpenses,
    required this.hidden,
  });

  final List<CategoryLimitItem> limits;
  final List<Movimiento> monthExpenses;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final shown = limits.take(4).toList();
    return MgCard(
      margin: _cardMargin,
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle('Presupuestos',
              trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: MgColors.ink3)),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const Text(
              'Aún no tienes límites. Créalos en Plan.',
              style: TextStyle(fontSize: 12, color: MgColors.ink2),
            )
          else
            for (final l in shown) ...[
              _LimitRow(limit: l, monthExpenses: monthExpenses, hidden: hidden),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.limit, required this.monthExpenses, required this.hidden});

  final CategoryLimitItem limit;
  final List<Movimiento> monthExpenses;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final spent = monthExpenses
        .where((m) => m.category == limit.category)
        .fold(0.0, (s, m) => s + m.amount);
    final pct = limit.limit > 0 ? spent / limit.limit : 0.0;
    final color = pct >= 1
        ? MgColors.down
        : (pct >= 0.8 ? MgColors.warn : CategoryIcon.colorForCategory(limit.category));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                categoryLabel(limit.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MgColors.ink),
              ),
            ),
            Text(
              hidden ? '••••' : '${formatSoles(spent)} de ${formatSoles(limit.limit)}',
              style: const TextStyle(fontSize: 11, color: MgColors.ink2),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ProgressBar(percent: pct, height: 5, color: color),
      ],
    );
  }
}

/// «Gastos por categoría» del mes, con los mismos colores que Stats.
class CategoryDonutCard extends StatelessWidget {
  const CategoryDonutCard({super.key, required this.monthExpenses, required this.hidden});

  final List<Movimiento> monthExpenses;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final byCategory = <Categoria, double>{};
    for (final m in monthExpenses) {
      byCategory[m.category] = (byCategory[m.category] ?? 0) + m.amount;
    }
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return MgCard(
      margin: _cardMargin,
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/reports'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle('Gastos por categoría',
              trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: MgColors.ink3)),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'Aún no hay gastos este mes.',
              style: TextStyle(fontSize: 12, color: MgColors.ink2),
            )
          else ...[
            Center(
              child: DonutChart(
                size: 110,
                strokeWidth: 12,
                total: total,
                centerWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hidden ? 'S/ ••••' : formatSoles(total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MgColors.ink,
                      ),
                    ),
                    const Text(
                      'gastado',
                      style: TextStyle(fontSize: 10.5, color: MgColors.ink2),
                    ),
                  ],
                ),
                segments: [
                  for (final e in entries)
                    DonutSegment(
                      label: categoryLabel(e.key),
                      value: e.value,
                      color: CategoryIcon.colorForCategory(e.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final e in entries.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CategoryIcon.colorForCategory(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        categoryLabel(e.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: MgColors.ink2),
                      ),
                    ),
                    Text(
                      '${(e.value / total * 100).round()}%',
                      style: const TextStyle(fontSize: 11.5, color: MgColors.ink),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// «Saldo a 30 días»: estimación con el ritmo real de los últimos 30 días.
/// Sin movimientos suficientes no muestra ninguna cifra.
class BalanceForecastCard extends StatelessWidget {
  const BalanceForecastCard({super.key, required this.projection, required this.hidden});

  final BalanceProjection? projection;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final p = projection;
    final positive = p == null || p.dailyNet >= 0;
    return MgCard(
      margin: _cardMargin,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle('Saldo a 30 días',
              trailing: const Text('Estimación',
                  style: TextStyle(fontSize: 10.5, color: MgColors.ink3))),
          const SizedBox(height: 8),
          if (p == null)
            Text(
              'Registra al menos $projectionMinMovements movimientos para estimarlo.',
              style: const TextStyle(fontSize: 12, color: MgColors.ink2),
            )
          else ...[
            Text(
              hidden ? 'S/ ••••' : (p.projected < 0 ? '−${formatSoles(p.projected.abs())}' : formatSoles(p.projected)),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.projected < 0 ? MgColors.down : MgColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              hidden
                  ? 'Según tu ritmo de los últimos 30 días'
                  : '${positive ? '+' : '−'}${formatSoles(p.dailyNet.abs())} por día, según tu ritmo de los últimos 30 días',
              style: const TextStyle(fontSize: 11, height: 1.3, color: MgColors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}
