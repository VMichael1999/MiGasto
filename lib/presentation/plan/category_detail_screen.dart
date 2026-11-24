import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/adaptive.dart';
import '../../core/layout/landscape_pane.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bucket_bars.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/category_period.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../expenses/movement_comparison_sheet.dart';
import '../providers.dart';
import 'plan_providers.dart';
import '../../shared/widgets/merchant_icon.dart';

/// Detalle de una categoría: cuánto se gastó en un período (quincena, mes,
/// trimestre o semestre), qué parte es de todo lo gastado, su evolución y los
/// movimientos. Todo sale de los movimientos reales.
///
/// En horizontal va en dos zonas: a la izquierda la dona con el total y el
/// límite, a la derecha la evolución y la lista de movimientos.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  DetailPeriod _period = DetailPeriod.mensual;
  DateTime _anchor = DateTime.now();

  Categoria _parseCategory() {
    for (final c in Categoria.values) {
      if (c.name.toLowerCase() == widget.categoryId.toLowerCase()) return c;
    }
    return Categoria.compras;
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _rangeLabel(PeriodRange r) {
    final last = r.end.subtract(const Duration(days: 1));
    switch (_period) {
      case DetailPeriod.quincenal:
        return '${r.start.day}–${last.day} ${DateFormat('MMM yyyy', 'es').format(r.start)}';
      case DetailPeriod.mensual:
        return _cap(DateFormat("MMMM 'de' yyyy", 'es').format(r.start));
      case DetailPeriod.trimestral:
      case DetailPeriod.semestral:
        return '${_cap(DateFormat('MMM', 'es').format(r.start))} – '
            '${_cap(DateFormat('MMM yyyy', 'es').format(last))}';
    }
  }

  String _bucketLabel(BucketTotal b) => _period == DetailPeriod.trimestral || _period == DetailPeriod.semestral
      ? _cap(DateFormat('MMM', 'es').format(b.start))
      : '${b.start.day}/${b.start.month}';

  static const _periodNames = {
    DetailPeriod.quincenal: 'Quincenal',
    DetailPeriod.mensual: 'Mensual',
    DetailPeriod.trimestral: 'Trimestral',
    DetailPeriod.semestral: 'Semestral',
  };

  @override
  Widget build(BuildContext context) {
    final category = _parseCategory();
    final isHidden = ref.watch(balanceHiddenProvider);
    final expenses = ref.watch(expensesStateProvider);
    final limits = ref.watch(categoryLimitsProvider);

    final now = DateTime.now();
    final range = periodRange(_period, _anchor);
    final inRange = expenses.where((m) => m.isConfirmed && range.contains(m.date)).toList();

    final movementsThisMonth = inRange.where((m) => m.category == category).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final gastosCategoria = movementsThisMonth.where((m) => m.esGastoReal).toList();
    final totalSpent = gastosCategoria.fold(0.0, (sum, m) => sum + m.amount);
    final totalAll = inRange.where((m) => m.esGastoReal).fold(0.0, (sum, m) => sum + m.amount);
    final share = categoryShare(totalSpent, totalAll);
    final buckets = evolutionBuckets(gastosCategoria, range, _period);

    final categoryLimit = limits.where((l) => l.category == category).firstOrNull;
    final catColor = CategoryIcon.colorForCategory(category);
    final iconData = CategoryIcon.iconForCategory(category);
    final landscape = context.isLandscapePhone;
    final canGoNext = !range.end.isAfter(now);

    // ---- Piezas --------------------------------------------------------
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
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
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: MgColors.ink),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              categoryLabel(category),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: MgColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );

    final periodBar = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap: en una columna estrecha (horizontal) los cuatro caben en dos filas.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in DetailPeriod.values)
                ChoiceChip(
                  label: Text(_periodNames[p]!),
                  selected: _period == p,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: _period == p ? FontWeight.w600 : FontWeight.w500,
                    color: _period == p ? MgColors.acc2 : MgColors.ink2,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _period = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Período anterior',
                onPressed: () => setState(() => _anchor = shiftAnchor(_period, _anchor, -1)),
                icon: const Icon(Icons.chevron_left_rounded, color: MgColors.ink2),
              ),
              Expanded(
                child: Text(
                  _rangeLabel(range),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MgColors.ink),
                ),
              ),
              IconButton(
                tooltip: 'Período siguiente',
                // No se puede avanzar más allá del período actual.
                onPressed: canGoNext
                    ? () => setState(() => _anchor = shiftAnchor(_period, _anchor, 1))
                    : null,
                icon: Icon(Icons.chevron_right_rounded,
                    color: canGoNext ? MgColors.ink2 : MgColors.ink3.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );

    final shareText = share == null
        ? 'Aún no hay gastos en este período'
        : '${share.toStringAsFixed(0)} % de tus gastos del período';
    final countText =
        '${movementsThisMonth.length} movimiento${movementsThisMonth.length == 1 ? '' : 's'}';

    // Dona (horizontal) o ícono grande (vertical) con el total.
    final hero = Padding(
      padding: EdgeInsets.fromLTRB(18, landscape ? 10 : 22, 18, 0),
      child: Column(
        children: [
          if (landscape)
            DonutChart(
              size: 120,
              strokeWidth: 14,
              total: totalAll > 0 ? totalAll : 1,
              centerWidget: Icon(iconData, size: 30, color: catColor),
              segments: share == null
                  ? const [DonutSegment(label: 'Sin gastos', value: 1, color: MgColors.line)]
                  : [
                      DonutSegment(label: categoryLabel(category), value: totalSpent, color: catColor),
                      if (totalAll - totalSpent > 0)
                        DonutSegment(label: 'Resto', value: totalAll - totalSpent, color: MgColors.soft),
                    ],
            )
          else
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Icon(iconData, size: 28, color: catColor)),
            ),
          const SizedBox(height: 12),
          Text(
            isHidden ? '••••' : formatSoles(totalSpent),
            style: TextStyle(
              fontSize: landscape ? 26 : 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: MgColors.ink,
              fontFeatures: AppText.tabular,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            shareText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: MgColors.ink2),
          ),
          const SizedBox(height: 2),
          Text(
            '$countText · ${_rangeLabel(range)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: MgColors.ink3),
          ),
        ],
      ),
    );

    // El límite es mensual: solo tiene sentido en la vista mensual.
    final limitBlock = <Widget>[
      if (_period == DetailPeriod.mensual) ...[
        const SizedBox(height: 16),
        ...[
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


        ],
      ],
    ];

    final evolution = Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: MgCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Evolución',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MgColors.ink),
            ),
            const SizedBox(height: 10),
            BucketBars(
              items: [for (final b in buckets) BucketBarItem(label: _bucketLabel(b), value: b.total)],
              color: catColor,
              valueLabel: (v) => isHidden ? '••••' : formatSoles(v),
            ),
          ],
        ),
      ),
    );

    final movementsHeader = Padding(
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
            decoration: BoxDecoration(color: MgColors.soft, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${movementsThisMonth.length}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MgColors.ink2),
            ),
          ),
        ],
      ),
    );

    final movementsList = movementsThisMonth.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sin movimientos',
              message: 'No hay gastos registrados en esta categoría en este período.',
            ),
          )
        : _buildGroupedMovements(context, ref, movementsThisMonth);

    if (landscape) {
      return Scaffold(
        backgroundColor: MgColors.bg,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LandscapePane(
                padding: const EdgeInsets.only(bottom: 90),
                children: [header, periodBar, hero, ...limitBlock],
              ),
              LandscapePane(
                padding: const EdgeInsets.only(bottom: 90),
                children: [evolution, movementsHeader, movementsList],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              periodBar,
              hero,
              ...limitBlock,
              evolution,
              movementsHeader,
              movementsList,
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
                          MerchantIcon(merchant: m.merchant, category: m.category, size: 38, radius: 12),
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
