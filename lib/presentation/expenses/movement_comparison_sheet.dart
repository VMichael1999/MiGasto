import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/mg_sheet.dart';
import '../../core/widgets/progress_bar.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/movement_comparison.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../providers.dart';

/// Abre la comparación de un movimiento con sus parecidos anteriores.
Future<void> showMovementComparison(BuildContext context, Movimiento movimiento) =>
    MgSheet.show<void>(
      context: context,
      child: MovementComparisonSheet(movement: movimiento),
    );

/// Compara un movimiento con lo que ya registraste del mismo comercio (o, si es
/// la primera vez, de su categoría): la vez anterior y los últimos meses.
class MovementComparisonSheet extends ConsumerWidget {
  const MovementComparisonSheet({super.key, required this.movement});

  final Movimiento movement;

  bool _isCurrentMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  String _month(DateTime d) {
    final s = DateFormat('MMMM', 'es').format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(expensesStateProvider);
    final hidden = ref.watch(balanceHiddenProvider);
    // Si el movimiento cambió (p. ej. se editó) se usa la versión actual.
    final m = all.where((e) => e.id == movement.id).firstOrNull ?? movement;
    final cmp = compareMovement(m, all);
    final basis = cmp.byMerchant ? m.merchant : categoryLabel(m.category);

    String money(double v) => hidden ? 'S/ ••••' : formatSoles(v);
    // En un gasto, subir es malo; en un ingreso, bueno.
    Color tone(double delta) {
      if (delta == 0) return MgColors.ink2;
      final rose = delta > 0;
      return (rose == m.esIngreso) ? MgColors.up : MgColors.down;
    }

    final maxTotal = cmp.months.fold<double>(0, (s, e) => e.total > s ? e.total : s);

    // Con scroll: en horizontal (390 dp de alto) no cabe todo de una vez.
    return SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const Text(
          'Comparar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MgColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          cmp.byMerchant
              ? '$basis · mismo ${m.esIngreso ? 'origen' : 'comercio'}'
              : '$basis · categoría (es la primera vez de «${m.merchant}»)',
          style: const TextStyle(fontSize: 12.5, color: MgColors.ink2),
        ),
        const SizedBox(height: 16),

        // 1. Esta vez frente a la vez anterior.
        if (cmp.previous != null) ...[
          Row(
            children: [
              _tile('Ahora', money(m.amount), DateFormat("d 'de' MMM", 'es').format(m.date)),
              const SizedBox(width: 10),
              _tile('Vez anterior', money(cmp.previous!.amount),
                  DateFormat("d 'de' MMM", 'es').format(cmp.previous!.date)),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final delta = m.amount - cmp.previous!.amount;
            final pct = cmp.previous!.amount > 0 ? delta / cmp.previous!.amount * 100 : null;
            return Text(
              delta.abs() < 0.005
                  ? 'Igual que la vez anterior'
                  : '${delta > 0 ? '+' : '−'}${hidden ? 'S/ ••••' : formatSoles(delta.abs())}'
                      '${pct == null ? '' : ' (${pct.abs().toStringAsFixed(0)} % ${delta > 0 ? 'más' : 'menos'})'}'
                      ' respecto a la vez anterior',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: delta.abs() < 0.005 ? MgColors.ink2 : tone(delta),
              ),
            );
          }),
          const SizedBox(height: 18),
        ],

        // 2. Últimos meses.
        Text(
          'Últimos ${cmp.months.length} meses · $basis',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MgColors.ink2),
        ),
        const SizedBox(height: 10),
        for (final t in cmp.months) ...[
          Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  _month(t.month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: t == cmp.current ? FontWeight.w700 : FontWeight.w500,
                    color: t == cmp.current ? MgColors.ink : MgColors.ink2,
                  ),
                ),
              ),
              Expanded(
                child: ProgressBar(
                  percent: maxTotal > 0 ? t.total / maxTotal : 0,
                  height: 8,
                  color: t == cmp.current ? MgColors.acc2 : MgColors.ink3,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                child: Text(
                  t.total > 0 ? money(t.total) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: t == cmp.current ? FontWeight.w700 : FontWeight.w500,
                    color: t.total > 0 ? MgColors.ink : MgColors.ink3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 6),

        // 3. Conclusión con los datos.
        if (!cmp.hasHistory)
          Text(
            'Es la primera vez que registras ${m.esIngreso ? 'este ingreso' : 'esto'}. '
            'Cuando haya más movimientos verás aquí cómo cambia mes a mes.',
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: MgColors.ink2),
          )
        else ...[
          if (cmp.monthChangePercent != null)
            Builder(builder: (_) {
              final change = cmp.monthChangePercent!;
              final prev = cmp.previousMonth!;
              return Text(
                'En ${_month(cmp.current.month).toLowerCase()} llevas ${money(cmp.current.total)}'
                ' en $basis: ${change.abs() < 0.5 ? 'lo mismo que' : '${change.abs().toStringAsFixed(0)} % ${change > 0 ? 'más' : 'menos'} que en'}'
                ' ${_month(prev.month).toLowerCase()} (${money(prev.total)}).'
                '${_isCurrentMonth(cmp.current.month) ? ' Ojo: el mes aún no termina.' : ''}',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: change.abs() < 0.5 ? MgColors.ink2 : tone(change),
                ),
              );
            })
          else
            Text(
              'No hay $basis registrado el mes anterior.',
              style: const TextStyle(fontSize: 12.5, color: MgColors.ink2),
            ),
          if (cmp.averageOfPreviousMonths != null) ...[
            const SizedBox(height: 4),
            Text(
              'Promedio de los meses anteriores: ${money(cmp.averageOfPreviousMonths!)}.',
              style: const TextStyle(fontSize: 12, color: MgColors.ink2),
            ),
          ],
        ],
        const SizedBox(height: 8),
      ],
    ),
    );
  }

  Widget _tile(String label, String value, String date) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: MgColors.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: MgColors.ink2)),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(date, style: const TextStyle(fontSize: 10.5, color: MgColors.ink3)),
            ],
          ),
        ),
      );
}
