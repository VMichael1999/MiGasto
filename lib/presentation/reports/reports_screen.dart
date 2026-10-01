import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/big_amount.dart';
import '../providers.dart';

enum _Mode { month, year, range }

const _shortMonths = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic',
];

class _Bucket {
  _Bucket(this.month);
  final DateTime month;
  double income = 0;
  double expense = 0;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _Mode _mode = _Mode.month;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late int _year = DateTime.now().year;
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // -------------------------------------------------------------- períodos

  /// Inicio (incluido) y fin (excluido) del período elegido.
  (DateTime, DateTime) get _period {
    switch (_mode) {
      case _Mode.month:
        return (_month, DateTime(_month.year, _month.month + 1));
      case _Mode.year:
        return (DateTime(_year), DateTime(_year + 1));
      case _Mode.range:
        final s = DateTime(_range.start.year, _range.start.month, _range.start.day);
        final e = DateTime(_range.end.year, _range.end.month, _range.end.day + 1);
        return (s, e);
    }
  }

  /// Período anterior de la misma duración (para comparar).
  (DateTime, DateTime) get _previous {
    final (s, e) = _period;
    switch (_mode) {
      case _Mode.month:
        return (DateTime(s.year, s.month - 1), s);
      case _Mode.year:
        return (DateTime(s.year - 1), s);
      case _Mode.range:
        final d = e.difference(s);
        return (s.subtract(d), s);
    }
  }

  List<Movimiento> _within(List<Movimiento> all, (DateTime, DateTime) p) => all
      .where((m) => m.isConfirmed && !m.date.isBefore(p.$1) && m.date.isBefore(p.$2))
      .toList();

  double _sum(Iterable<Movimiento> list, TipoMovimiento tipo) =>
      list.where((m) => m.tipo == tipo).fold(0.0, (s, m) => s + m.amount);

  String _monthName(DateTime d) => DateFormat('MMMM', 'es').format(d);

  String get _periodLabel {
    switch (_mode) {
      case _Mode.month:
        return toBeginningOfSentenceCase(
            '${_monthName(_month)} ${_month.year}');
      case _Mode.year:
        return '$_year';
      case _Mode.range:
        final f = DateFormat('d MMM', 'es');
        return '${f.format(_range.start)} – ${f.format(_range.end)}';
    }
  }

  void _shift(int delta) {
    setState(() {
      if (_mode == _Mode.month) {
        _month = DateTime(_month.year, _month.month + delta);
      } else if (_mode == _Mode.year) {
        _year += delta;
      }
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _range = picked);
  }

  List<_Bucket> _buckets(List<Movimiento> all) {
    final (s, e) = _period;
    late List<DateTime> months;
    switch (_mode) {
      case _Mode.month:
        // Los 4 últimos meses terminando en el elegido.
        months = [for (var i = 3; i >= 0; i--) DateTime(_month.year, _month.month - i)];
      case _Mode.year:
        months = [for (var m = 1; m <= 12; m++) DateTime(_year, m)];
      case _Mode.range:
        months = [];
        var c = DateTime(s.year, s.month);
        while (c.isBefore(e) && months.length < 12) {
          months.add(c);
          c = DateTime(c.year, c.month + 1);
        }
    }
    final buckets = [for (final m in months) _Bucket(m)];
    for (final m in all.where((m) => m.isConfirmed)) {
      for (final b in buckets) {
        if (m.date.year == b.month.year && m.date.month == b.month.month) {
          if (m.esIngreso) {
            b.income += m.amount;
          } else {
            b.expense += m.amount;
          }
        }
      }
    }
    return buckets;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(expensesStateProvider);
    final theme = Theme.of(context);

    final current = _within(all, _period);
    final previous = _within(all, _previous);
    final income = _sum(current, TipoMovimiento.ingreso);
    final expense = _sum(current, TipoMovimiento.gasto);
    final balance = income - expense;
    final prevBalance =
        _sum(previous, TipoMovimiento.ingreso) - _sum(previous, TipoMovimiento.gasto);
    final hasPrevious = previous.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reportes', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 14),
              _modeSelector(context),
              const SizedBox(height: 10),
              _periodBar(context),
              const SizedBox(height: 14),
              _balanceBlock(context, balance, prevBalance, hasPrevious),
              const SizedBox(height: 14),
              _legend(context),
              const SizedBox(height: 8),
              _chart(context, _buckets(all)),
              const SizedBox(height: 14),
              _categoryTable(
                context,
                title: 'Ingresos de ${_titleSuffix()}',
                emptyText: 'Sin ingresos en este período.',
                movimientos: current.where((m) => m.esIngreso),
              ),
              const SizedBox(height: 14),
              _categoryTable(
                context,
                title: 'Gastos de ${_titleSuffix()}',
                emptyText: 'Sin gastos en este período.',
                movimientos: current.where((m) => m.esGasto),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleSuffix() {
    switch (_mode) {
      case _Mode.month:
        return _monthName(_month);
      case _Mode.year:
        return '$_year';
      case _Mode.range:
        return 'este rango';
    }
  }

  Widget _modeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget seg(String label, _Mode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _mode = mode),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch - 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.outline : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          seg('Mes', _Mode.month),
          seg('Año', _Mode.year),
          seg('Rango', _Mode.range),
        ],
      ),
    );
  }

  Widget _periodBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canNext = _mode == _Mode.month
        ? DateTime(_month.year, _month.month + 1).isBefore(DateTime.now())
        : _mode == _Mode.year && _year < DateTime.now().year;

    Widget arrow(String label, IconData? _, bool enabled, int delta, bool flip) {
      return Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Tooltip(
          message: label,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.field),
              onTap: enabled ? () => _shift(delta) : null,
              child: SizedBox(
                width: AppSizes.minTouch,
                height: AppSizes.minTouch,
                child: Center(
                  child: Transform.flip(
                    flipX: flip,
                    child: AppIcon(AppIcons.chevron, color: scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_mode == _Mode.range) {
      return Semantics(
        button: true,
        label: 'Elegir rango de fechas. $_periodLabel',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.field),
          onTap: _pickRange,
          child: Container(
            height: AppSizes.minTouch,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_periodLabel, style: theme.textTheme.bodyLarge)),
                Text('Cambiar',
                    style: theme.textTheme.labelLarge!
                        .copyWith(color: scheme.onSurfaceVariant, fontSize: 13)),
                AppIcon(AppIcons.chevron,
                    size: AppIconSize.small, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        arrow('Período anterior', null, true, -1, true),
        Text(_periodLabel, style: theme.textTheme.titleMedium),
        arrow('Período siguiente', null, canNext, 1, false),
      ],
    );
  }

  Widget _balanceBlock(
    BuildContext context,
    double balance,
    double prevBalance,
    bool hasPrevious,
  ) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final now = DateTime.now();
    final isCurrentMonth =
        _mode == _Mode.month && _month.year == now.year && _month.month == now.month;
    final isPast = !isCurrentMonth && _mode != _Mode.range;

    final lead = switch (_mode) {
      _Mode.month => 'En ${_monthName(_month)} te ${isPast ? 'quedaron' : 'quedan'}',
      _Mode.year => 'En $_year te ${_year < now.year ? 'quedaron' : 'quedan'}',
      _Mode.range => 'En este rango te quedaron',
    };

    final diff = balance - prevBalance;
    String? comparison;
    if (hasPrevious) {
      final prevName = switch (_mode) {
        _Mode.month => _monthName(_previous.$1),
        _Mode.year => '${_year - 1}',
        _Mode.range => 'el período anterior',
      };
      comparison = diff.abs() < 0.005
          ? 'Igual que en $prevName'
          : '${formatSoles(diff.abs())} ${diff > 0 ? 'más' : 'menos'} que en $prevName';
    }

    final negative = balance < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lead,
            style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        BigAmount(
          balance.abs(),
          size: 36,
          prefix: negative ? '− S/' : 'S/',
          color: negative ? colors.budgetOver : null,
        ),
        if (comparison != null) ...[
          const SizedBox(height: 4),
          Text(comparison, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _legend(BuildContext context) {
    final colors = context.appColors;
    final style = Theme.of(context).textTheme.bodySmall;
    Widget item(Color c, String label) => Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(label, style: style),
          ],
        );
    return Row(
      children: [
        item(colors.income, 'Ingresos'),
        const SizedBox(width: 16),
        item(colors.expenseBar, 'Gastos'),
      ],
    );
  }

  Widget _chart(BuildContext context, List<_Bucket> buckets) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final scheme = theme.colorScheme;

    final maxValue = buckets.fold<double>(
        0, (m, b) => math.max(m, math.max(b.income, b.expense)));
    final top = math.max(1000.0, (maxValue / 1000).ceil() * 1000.0);
    final last = buckets.length - 1;

    final summary = buckets
        .map((b) =>
            '${_shortMonths[b.month.month - 1]}: ${formatAmount(b.income)} de ingresos y ${formatAmount(b.expense)} de gastos')
        .join('. ');

    return Semantics(
      label: 'Ingresos y gastos por mes. $summary soles.',
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: top,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: scheme.outline, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: top / 4,
                  getTitlesWidget: (v, _) => Text(
                    NumberFormat('#,##0', 'en').format(v),
                    style: theme.textTheme.labelSmall!.copyWith(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                    final isLast = i == last;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _shortMonths[buckets[i].month.month - 1],
                        style: theme.textTheme.labelMedium!.copyWith(
                          fontSize: 11,
                          fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                          color: isLast ? scheme.onSurface : scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: scheme.outline,
                fitInsideHorizontally: true,
                getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                  formatSoles(rod.toY),
                  theme.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: rodIndex == 0 ? colors.income : scheme.onSurface,
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 2,
                  barRods: [
                    BarChartRodData(
                      toY: buckets[i].income,
                      width: buckets.length > 6 ? 7 : 14,
                      color: colors.income,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: buckets[i].expense,
                      width: buckets.length > 6 ? 7 : 14,
                      color: colors.expenseBar,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTable(
    BuildContext context, {
    required String title,
    required String emptyText,
    required Iterable<Movimiento> movimientos,
  }) {
    final theme = Theme.of(context);
    final byCategory = <Categoria, double>{};
    for (final m in movimientos) {
      byCategory[m.category] = (byCategory[m.category] ?? 0) + m.amount;
    }
    final rows = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: theme.textTheme.bodySmall),
          ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(color: theme.colorScheme.outline, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rows[i].key == Categoria.transferenciaRecibida
                        ? 'Transferencias recibidas'
                        : categoryLabel(rows[i].key),
                    style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13.5),
                  ),
                ),
                Text(
                  formatSoles(rows[i].value),
                  style: AppText.amount(theme.textTheme.bodyMedium!
                      .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
