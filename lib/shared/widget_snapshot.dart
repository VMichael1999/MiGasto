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
  static const version = 1;

  static Map<String, dynamic> build(List<Movimiento> all, DateTime now) {
    final summary = computeBalanceSummary(all, now);
    final available = summary.prevBalance + summary.income;
    final percent = available > 0
        ? ((summary.balance / available) * 100).clamp(0, 100).round()
        : (summary.spent == 0 ? 100 : 0);
    final recent = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return {
      'v': version,
      'updatedAt': now.millisecondsSinceEpoch,
      'monthKey': DateFormat('yyyy-MM').format(now),
      'month': toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(now)),
      'balance': _signed(summary.balance),
      'negative': summary.balance < 0,
      'income': formatSoles(summary.income),
      'spent': formatSoles(summary.spent),
      'percent': percent,
      'pending': all.where((m) => m.estado == EstadoMovimiento.pendiente).length,
      'recent': [for (final m in recent.take(maxRecent)) _movement(m)],
    };
  }

  static String encode(List<Movimiento> all, DateTime now) => jsonEncode(build(all, now));

  static Map<String, dynamic> _movement(Movimiento m) {
    final kind = m.entreMisCuentas ? 'propia' : (m.esIngreso ? 'ingreso' : 'gasto');
    final sign = switch (kind) { 'ingreso' => '+', 'gasto' => '-', _ => '' };
    return {
      'id': m.id,
      'title': m.merchant.trim().isEmpty ? categoryLabel(m.category) : m.merchant.trim(),
      'subtitle': movementSubtitle(m, categoryLabel(m.category)),
      'amount': '$sign${formatSoles(m.amount)}',
      'kind': kind,
      'color': _hex(CategoryIcon.colorForCategory(m.category).toARGB32()),
      'pending': m.estado == EstadoMovimiento.pendiente,
      'date': m.date.millisecondsSinceEpoch,
    };
  }

  /// `-S/ 120.00` si el saldo es negativo (formatSoles no lleva signo).
  static String _signed(double value) => value < 0 ? '-${formatSoles(-value)}' : formatSoles(value);

  static String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
