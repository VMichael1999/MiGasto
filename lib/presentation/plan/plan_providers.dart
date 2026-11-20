import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/movimiento.dart';
import '../../data/debug_mock_data.dart';
import '../providers.dart';

/// Modelo de límite por categoría para la capa de presentación (Sección 4.7 del prompt y prototipo HTML).
class CategoryLimitItem {
  final Categoria category;
  final double limit;

  const CategoryLimitItem({
    required this.category,
    required this.limit,
  });

  CategoryLimitItem copyWith({
    Categoria? category,
    double? limit,
  }) {
    return CategoryLimitItem(
      category: category ?? this.category,
      limit: limit ?? this.limit,
    );
  }
}

/// Planes de ejemplo para ver la pantalla Plan con datos (solo debug, en memoria).
const debugMockLimits = [
  CategoryLimitItem(category: Categoria.alimentacion, limit: 1200),
  CategoryLimitItem(category: Categoria.compras, limit: 900),
  CategoryLimitItem(category: Categoria.transporte, limit: 400),
  CategoryLimitItem(category: Categoria.servicios, limit: 3000),
  CategoryLimitItem(category: Categoria.entretenimiento, limit: 250),
  CategoryLimitItem(category: Categoria.otros, limit: 2000),
];

const debugMockSavingsGoal = SavingsGoal(
  title: 'Viaje a Cusco',
  current: 3200,
  target: 6000,
);

const _keyCategoryLimits = 'migasto_category_limits';
const _keySavingsGoal = 'migasto_savings_goal';

/// Límites por categoría que el usuario fijó. Empiezan vacíos y se guardan en
/// el dispositivo.
class CategoryLimitsNotifier extends StateNotifier<List<CategoryLimitItem>> {
  CategoryLimitsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<CategoryLimitItem> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_keyCategoryLimits);
    // Solo en debug y mientras el usuario no haya guardado nada propio.
    if (raw == null) return debugMockEnabled(prefs) ? debugMockLimits : const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (Categoria.values.any((c) => c.name == e['category']))
            CategoryLimitItem(
              category: Categoria.values.byName(e['category'] as String),
              limit: (e['limit'] as num).toDouble(),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _save() {
    _prefs.setString(
      _keyCategoryLimits,
      jsonEncode([
        for (final l in state) {'category': l.category.name, 'limit': l.limit},
      ]),
    );
  }

  void setLimit(Categoria category, double limit) {
    final index = state.indexWhere((l) => l.category == category);
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(limit: limit);
      state = updated;
    } else {
      state = [...state, CategoryLimitItem(category: category, limit: limit)];
    }
    _save();
  }

  void removeLimit(Categoria category) {
    state = state.where((l) => l.category != category).toList();
    _save();
  }
}

final categoryLimitsProvider =
    StateNotifierProvider<CategoryLimitsNotifier, List<CategoryLimitItem>>((ref) {
  return CategoryLimitsNotifier(ref.read(sharedPreferencesProvider));
});

/// Meta de ahorro definida por el usuario.
class SavingsGoal {
  final String title;
  final double current;
  final double target;

  const SavingsGoal({
    required this.title,
    required this.current,
    required this.target,
  });
}

/// `null` mientras el usuario no haya definido una meta.
class SavingsGoalNotifier extends StateNotifier<SavingsGoal?> {
  SavingsGoalNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static SavingsGoal? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_keySavingsGoal);
    // Solo en debug y mientras el usuario no haya guardado nada propio.
    if (raw == null) return debugMockEnabled(prefs) ? debugMockSavingsGoal : null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SavingsGoal(
        title: m['title'] as String,
        current: (m['current'] as num).toDouble(),
        target: (m['target'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  void set(SavingsGoal goal) {
    state = goal;
    _prefs.setString(
      _keySavingsGoal,
      jsonEncode({'title': goal.title, 'current': goal.current, 'target': goal.target}),
    );
  }

  void clear() {
    state = null;
    _prefs.remove(_keySavingsGoal);
  }
}

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalNotifier, SavingsGoal?>((ref) {
  return SavingsGoalNotifier(ref.read(sharedPreferencesProvider));
});
