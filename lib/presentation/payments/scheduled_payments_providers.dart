import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/debug_mock_data.dart';
import '../../domain/scheduled_payment.dart';
import '../providers.dart';

const keyScheduledPayments = 'migasto_scheduled_payments';

/// Pagos y cobros programados, guardados en el dispositivo.
class ScheduledPaymentsNotifier extends StateNotifier<List<ScheduledPayment>> {
  ScheduledPaymentsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  static List<ScheduledPayment> _load(SharedPreferences prefs) {
    final raw = prefs.getString(keyScheduledPayments);
    // Solo en debug y mientras el usuario no haya guardado nada propio.
    if (raw == null) {
      return debugMockEnabled(prefs) ? debugMockScheduledPayments(DateTime.now()) : const [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          ?ScheduledPayment.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _save() {
    _prefs.setString(
      keyScheduledPayments,
      jsonEncode([for (final p in state) p.toJson()]),
    );
  }

  /// Crea uno nuevo (id vacío) o actualiza el que tenga ese id.
  void upsert(ScheduledPayment p) {
    final id = p.id.isEmpty ? _uuid.v4() : p.id;
    final item = ScheduledPayment(
      id: id,
      name: p.name,
      amount: p.amount,
      tipo: p.tipo,
      category: p.category,
      dueDate: dateOnly(p.dueDate),
      monthly: p.monthly,
    );
    final i = state.indexWhere((e) => e.id == id);
    state = i >= 0 ? ([...state]..[i] = item) : [...state, item];
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  /// Tras pagarlo: si se repite cada mes pasa al mes siguiente (y se mantiene
  /// en el futuro aunque estuviera muy atrasado); si no, se quita.
  void settle(String id, DateTime now) {
    final p = state.where((e) => e.id == id).firstOrNull;
    if (p == null) return;
    if (!p.monthly) return remove(id);
    var next = p.nextMonth();
    while (!dateOnly(next.dueDate).isAfter(dateOnly(now))) {
      next = next.nextMonth();
    }
    upsert(next);
  }
}

final scheduledPaymentsProvider =
    StateNotifierProvider<ScheduledPaymentsNotifier, List<ScheduledPayment>>((ref) {
  return ScheduledPaymentsNotifier(ref.read(sharedPreferencesProvider));
});

/// Marca un pago programado como pagado (o cobrado): registra el movimiento
/// real, confirmado, y programa el siguiente si se repite.
Future<void> settleScheduledPayment(WidgetRef ref, ScheduledPayment p) async {
  await ref.read(expensesStateProvider.notifier).addManualMovimiento(
        tipo: p.tipo,
        amount: p.amount,
        merchant: p.name,
        category: p.category,
      );
  ref.read(scheduledPaymentsProvider.notifier).settle(p.id, DateTime.now());
}
