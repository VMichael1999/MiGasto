import 'dart:convert';

import 'package:intl/intl.dart';

import '../core/widgets/category_icon.dart';
import 'format.dart';
import 'labels.dart';
import '../domain/balance_summary.dart';
import '../domain/entities/movimiento.dart';

/// Lo que muestran los widgets de la pantalla de inicio (iPhone y Android).
///
/// Flutter lo arma con las mismas cuentas que Inicio y lo deja en el teléfono como JSON; los
/// widgets nativos solo lo pintan. Los montos van ya formateados («S/ 1,250.00») para que se
/// vean igual en las dos plataformas.
class WidgetSnapshot {
  /// Cuántos movimientos se guardan (el widget grande muestra hasta 6).
  static const maxRecent = 6;

  /// Versión del formato: si cambia, los widgets saben que deben esperar a la app.
  static const version = 2;

  /// Signo de los montos que restan («−S/ 12.90»): el menos tipográfico, no el guion.
  static const minus = '−';

  static Map<String, dynamic> build(List<Movimiento> all, DateTime now) {
    final summary = computeBalanceSummary(all, now);
    final available = summary.prevBalance + summary.income;
    final percent = available > 0
        ? ((summary.balance / available) * 100).clamp(0, 100).round()
        : (summary.spent == 0 ? 100 : 0);
    final recent = [...all]..sort((a, b) => b.date.compareTo(a.date));
    final shown = recent.take(maxRecent).toList();
    // El saldo en partes, para dibujar «S/» y los decimales más chicos que la cifra.
    final amount = formatAmount(summary.balance.abs());
    final dot = amount.lastIndexOf('.');
    return {
      'v': version,
      'updatedAt': now.millisecondsSinceEpoch,
      'monthKey': DateFormat('yyyy-MM').format(now),
      'month': toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(now)),
      'monthShort': DateFormat('MMM', 'es').format(now).replaceAll('.', '').toUpperCase(),
      'balance': summary.balance < 0 ? '$minus${formatSoles(-summary.balance)}' : formatSoles(summary.balance),
      'balanceSign': summary.balance < 0 ? minus : '',
      'balanceInt': amount.substring(0, dot),
      'balanceDec': amount.substring(dot),
      'negative': summary.balance < 0,
      'income': formatSoles(summary.income),
      'spent': formatSoles(summary.spent),
      'todaySpent': formatSoles(_sum(all.where((m) => m.isConfirmed && m.esGastoReal && _sameDay(m.date, now)))),
      'percent': percent,
      'pending': all.where((m) => m.estado == EstadoMovimiento.pendiente).length,
      'recent': [for (final m in shown) _movement(m)],
      // Total de cada día que aparece en la lista (lo confirmado que cuenta, de todo ese día).
      'days': {
        for (final key in shown.map((m) => _dayKey(m.date)).toSet())
          key: _signedTotal(all.where((m) => _dayKey(m.date) == key && m.isConfirmed)),
      },
    };
  }

  static String encode(List<Movimiento> all, DateTime now) => jsonEncode(build(all, now));

  static Map<String, dynamic> _movement(Movimiento m) {
    final kind = m.entreMisCuentas ? 'propia' : (m.esIngreso ? 'ingreso' : 'gasto');
    final sign = switch (kind) { 'ingreso' => '+', 'gasto' => minus, _ => '' };
    return {
      'id': m.id,
      'title': m.merchant.trim().isEmpty ? categoryLabel(m.category) : m.merchant.trim(),
      'subtitle': movementSubtitle(m, categoryLabel(m.category)),
      'amount': '$sign${formatSoles(m.amount)}',
      'kind': kind,
      // Ícono de la categoría (los widgets lo traducen al de cada plataforma).
      'icon': m.entreMisCuentas ? 'propia' : m.category.name,
      'color': _hex(CategoryIcon.colorForCategory(m.category).toARGB32()),
      'pending': m.estado == EstadoMovimiento.pendiente,
      'day': _dayKey(m.date),
      'date': m.date.millisecondsSinceEpoch,
    };
  }

  static double _sum(Iterable<Movimiento> l) => l.fold(0.0, (s, m) => s + m.amount);

  /// `+S/ 3,441.90` o `−S/ 38.40`: lo que entró menos lo que salió.
  static String _signedTotal(Iterable<Movimiento> l) {
    final net = _sum(l.where((m) => m.esIngresoReal)) - _sum(l.where((m) => m.esGastoReal));
    if (net == 0) return formatSoles(0);
    return net > 0 ? '+${formatSoles(net)}' : '$minus${formatSoles(-net)}';
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
