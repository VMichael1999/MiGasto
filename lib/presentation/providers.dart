import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/datasource/local_database.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../domain/entities/movimiento.dart';
import '../domain/repositories/expense_repository.dart';
import '../data/services/backup_service.dart';
import '../data/services/nlp_classifier_service.dart';
import '../data/services/location_service.dart';
import '../domain/duplicate_rule.dart';

// 1. SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences inside main() and override this provider');
});

// 2. LocalDatabase Provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return DatabaseManager(prefs);
});

// 3. ExpenseRepository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.read(localDatabaseProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  return ExpenseRepositoryImpl(db, prefs);
});

// 4. Pending Movimiento State Provider
final pendingExpenseProvider = StateProvider<Movimiento?>((ref) => null);

// 5. Budget State Provider
final budgetProvider = StateProvider<double>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getBudget();
});

// 6. Active Providers Configuration Provider
final providersEnabledProvider = StateNotifierProvider<ProvidersEnabledNotifier, Map<String, bool>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return ProvidersEnabledNotifier(repo);
});

class ProvidersEnabledNotifier extends StateNotifier<Map<String, bool>> {
  final ExpenseRepository _repo;

  ProvidersEnabledNotifier(this._repo) : super(_repo.getProviders());

  void toggleProvider(String key) {
    final updated = Map<String, bool>.from(state);
    if (updated.containsKey(key)) {
      updated[key] = !updated[key]!;
      _repo.saveProviders(updated);
      state = updated;
    }
  }
}

/// "Guardar ingresos automáticamente" (Ajustes). Apagado por defecto: el código
/// nativo lee la misma clave (`flutter.migasto_auto_save_income`).
const keyAutoSaveIncome = 'migasto_auto_save_income';

final autoSaveIncomeProvider = StateNotifierProvider<AutoSaveIncomeNotifier, bool>((ref) {
  return AutoSaveIncomeNotifier(ref.read(sharedPreferencesProvider));
});

class AutoSaveIncomeNotifier extends StateNotifier<bool> {
  AutoSaveIncomeNotifier(this._prefs) : super(_prefs.getBool(keyAutoSaveIncome) ?? false);
  final SharedPreferences _prefs;

  void toggle() => set(!state);

  void set(bool value) {
    _prefs.setBool(keyAutoSaveIncome, value);
    state = value;
  }
}

/// Fecha del último respaldo creado (o `null` si nunca se hizo uno).
const keyLastBackup = 'migasto_last_backup';

final lastBackupProvider = StateProvider<DateTime?>((ref) {
  final raw = ref.read(sharedPreferencesProvider).getString(keyLastBackup);
  return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
});

// 7. Expenses State Notifier Provider
final expensesStateProvider = StateNotifierProvider<ExpensesNotifier, List<Movimiento>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return ExpensesNotifier(repo, ref);
});

class ExpensesNotifier extends StateNotifier<List<Movimiento>>
    with WidgetsBindingObserver {
  final ExpenseRepository _repo;
  final Ref _ref;
  static const _channel = MethodChannel('com.example.mi_gasto/accessibility');
  final _uuid = const Uuid();

  ExpensesNotifier(this._repo, this._ref) : super([]) {
    _boot();
    _initChannel();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Sin binding (algunas pruebas): no hay ciclo de vida que escuchar.
    }
  }

  Future<void> _boot() async {
    await _loadExpenses();
    await drainNativeQueue();
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) drainNativeQueue();
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  /// Guarda los pagos que el código nativo detectó (incluso con la app cerrada).
  Future<void> drainNativeQueue() async {
    String? raw;
    try {
      raw = await _channel.invokeMethod<String>('takeNativeQueue');
    } catch (_) {
      return; // plataforma sin código nativo de detección
    }
    if (raw == null || raw.isEmpty) return;

    List<dynamic> items;
    try {
      items = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    for (final item in items) {
      if (!mounted) return;
      await _ingestNative(item as Map<String, dynamic>);
    }
  }

  Future<void> _ingestNative(Map<String, dynamic> item) async {
    final amount = (item['amount'] as num).toDouble();
    final peer = (item['peer'] as String?) ?? 'Desconocido';
    final providerStr = (item['provider'] as String?) ?? 'otro';
    final rawText = (item['rawText'] as String?) ?? '';
    final tipo = item['type'] == 'ingreso' ? TipoMovimiento.ingreso : TipoMovimiento.gasto;
    final confirmed = item['confirmed'] == true;
    final at = DateTime.fromMillisecondsSinceEpoch(
        (item['at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch);
    final source = PaymentSource.values.firstWhere(
      (s) => s.name == providerStr,
      orElse: () => PaymentSource.otro,
    );

    // Un pago confirmado que llegó por dos vías cuenta una sola vez.
    if (isDuplicateMovement(state, amount: amount, source: source, date: at, tipo: tipo)) {
      return;
    }

    final canal = switch (item['channel']) {
      'wallet' => CanalMovimiento.wallet,
      'captura' => CanalMovimiento.captura,
      _ => CanalMovimiento.notificacion,
    };
    final card = (item['card'] as String?)?.trim();
    // La categoría elegida en la captura se respeta si corresponde al tipo.
    final chosen = Categoria.values.where((c) => c.name == item['category']).firstOrNull;
    final category = (chosen != null && chosen.esDeIngreso == (tipo == TipoMovimiento.ingreso))
        ? chosen
        : await _categoryFor(tipo, rawText, peer);
    final movimiento = Movimiento(
      id: _uuid.v4(),
      amount: amount,
      merchant: peer,
      category: category,
      source: source,
      date: at,
      tipo: tipo,
      canal: canal,
      estado: confirmed ? EstadoMovimiento.confirmado : EstadoMovimiento.pendiente,
      tarjeta: (card == null || card.isEmpty) ? null : card,
      latitud: (item['latitude'] as num?)?.toDouble(),
      longitud: (item['longitude'] as num?)?.toDouble(),
      precision: (item['accuracy'] as num?)?.toDouble(),
      lugar: item['place'] as String?,
      textoOriginal: rawText,
    );
    await _repo.saveExpense(movimiento);
    if (!mounted) return;
    state = [movimiento, ...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<Categoria> _categoryFor(TipoMovimiento tipo, String rawText, String peer) async {
    if (tipo == TipoMovimiento.ingreso) {
      return NlpClassifierService.classifyIncome(rawText, peer);
    }
    // 1. Categoría aprendida de los cambios del usuario para este comercio
    final learned = await _repo.getCategoryOverride(peer);
    if (learned != null && !learned.esDeIngreso) return learned;
    // 2. Reglas por palabras clave
    return NlpClassifierService.classify(rawText, peer);
  }

  Future<void> _loadExpenses() async {
    final list = await _repo.getExpenses();

    list.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) {
      state = list;
    }
  }

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTransactionDetected') {
        final map = call.arguments as Map;
        final amount = (map['amount'] as num).toDouble();
        final peerName = map['peerName'] as String;
        final providerStr = map['provider'] as String;
        final rawText = map['rawText'] as String;
        final tipoStr = (map['type'] as String?) ?? 'gasto';

        // Check if provider is enabled
        final activeProviders = _ref.read(providersEnabledProvider);
        if (activeProviders[providerStr] == true) {
          triggerIncomingPayment(
            amount: amount,
            merchant: peerName,
            providerStr: providerStr,
            rawText: rawText,
            tipoStr: tipoStr,
          );
        }
      } else if (call.method == 'onTransactionSaved') {
        drainNativeQueue();
      }
    });
  }

  /// Un pago detectado. Los gastos quedan como aviso para confirmar (se guardan
  /// solos tras la cuenta regresiva). Los ingresos se guardan como pendientes y
  /// esperan la confirmación del usuario.
  Future<void> triggerIncomingPayment({
    required double amount,
    required String merchant,
    required String providerStr,
    required String rawText,
    String tipoStr = 'gasto',
    CanalMovimiento canal = CanalMovimiento.notificacion,
  }) async {
    final source = PaymentSource.values.firstWhere(
      (s) => s.name == providerStr,
      orElse: () => PaymentSource.otro,
    );
    final tipo = tipoStr == 'ingreso' ? TipoMovimiento.ingreso : TipoMovimiento.gasto;
    final now = DateTime.now();

    // Regla de duplicados: mismo monto y fuente dentro de 2 minutos.
    final pendingNow = _ref.read(pendingExpenseProvider);
    if (isDuplicateMovement(
      [...state, ?pendingNow],
      amount: amount,
      source: source,
      date: now,
      tipo: tipo,
    )) {
      return;
    }

    final predicted = await _categoryFor(tipo, rawText, merchant);

    final movimiento = Movimiento(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: predicted,
      source: source,
      date: now,
      tipo: tipo,
      canal: canal,
      estado: EstadoMovimiento.pendiente,
      textoOriginal: rawText,
    );

    if (tipo == TipoMovimiento.ingreso) {
      if (_ref.read(autoSaveIncomeProvider)) {
        // El usuario pidió guardar los ingresos solos.
        final saved = movimiento.copyWith(estado: EstadoMovimiento.confirmado);
        await _repo.saveExpense(saved);
        state = [saved, ...state]..sort((a, b) => b.date.compareTo(a.date));
        return;
      }
      // Por defecto un ingreso no se guarda solo como confirmado, pero sí queda
      // en la lista "Por confirmar" aunque se ignore el aviso.
      await _repo.saveExpense(movimiento);
      state = [movimiento, ...state]..sort((a, b) => b.date.compareTo(a.date));
    }
    _ref.read(pendingExpenseProvider.notifier).state = movimiento;
  }

  Future<void> confirmPendingExpense(Categoria finalCategory, String notes) async {
    final pending = _ref.read(pendingExpenseProvider);
    if (pending == null) return;

    final confirmed = pending.copyWith(
      category: finalCategory,
      notes: notes,
      estado: EstadoMovimiento.confirmado,
    );

    // Save learning preference
    await _repo.saveCategoryOverride(pending.merchant, finalCategory);

    // Save to database
    await _repo.saveExpense(confirmed);

    // Update local state (reemplaza el pendiente si ya estaba guardado)
    state = [confirmed, ...state.where((e) => e.id != confirmed.id)]
      ..sort((a, b) => b.date.compareTo(a.date));

    // Clear pending alerts
    _ref.read(pendingExpenseProvider.notifier).state = null;
  }

  /// Cambia el pago detectado que se está mostrando (monto, comercio, categoría, nota).
  void updatePending(Movimiento updated) {
    _ref.read(pendingExpenseProvider.notifier).state = updated;
  }

  /// Cierra el aviso sin guardar. Un ingreso ya guardado como pendiente se queda
  /// en "Por confirmar".
  void discardPendingExpense() {
    _ref.read(pendingExpenseProvider.notifier).state = null;
  }

  Future<void> addManualExpense(double amount, String merchant, Categoria category) {
    return addManualMovimiento(
      tipo: TipoMovimiento.gasto,
      amount: amount,
      merchant: merchant,
      category: category,
    );
  }

  Future<void> addManualMovimiento({
    required TipoMovimiento tipo,
    required double amount,
    required String merchant,
    required Categoria category,
    PaymentSource source = PaymentSource.manual,
  }) async {
    final movimiento = Movimiento(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: category,
      source: source,
      date: DateTime.now(),
      tipo: tipo,
      canal: CanalMovimiento.manual,
      estado: EstadoMovimiento.confirmado,
      notes: 'Registro manual',
    );
    await _repo.saveExpense(movimiento);
    state = [movimiento, ...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Confirma un ingreso que estaba en "Por confirmar".
  Future<void> confirmMovimiento(String id, {Categoria? category}) async {
    final current = state.where((e) => e.id == id).firstOrNull;
    if (current == null) return;
    await updateExpense(current.copyWith(
      category: category ?? current.category,
      estado: EstadoMovimiento.confirmado,
    ));
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    state = state.where((e) => e.id != id).toList();
  }

  // ------------------------------------------------------------ respaldo

  /// Todo lo que va en un respaldo: movimientos, presupuesto y categorías aprendidas.
  BackupContents contenidoDeRespaldo() => BackupContents(
        movimientos: List.of(state),
        presupuesto: _repo.getBudget(),
        aprendidas: _repo.getAllCategoryOverrides(),
        creado: DateTime.now().toUtc(),
      );

  /// Cuántos movimientos de [contents] no están todavía en la app.
  int cuantosSonNuevos(BackupContents contents) {
    final existentes = state.map((m) => m.id).toSet();
    return contents.movimientos.where((m) => !existentes.contains(m.id)).length;
  }

  /// Restaura un respaldo sin borrar nada de lo que ya hay: agrega los movimientos
  /// que faltan (los que ya están, por id, se dejan como están), recupera las
  /// categorías aprendidas y el presupuesto. Devuelve cuántos movimientos agregó.
  Future<int> restaurarRespaldo(BackupContents contents) async {
    final existentes = state.map((m) => m.id).toSet();
    final nuevos = contents.movimientos.where((m) => !existentes.contains(m.id)).toList();
    for (final m in nuevos) {
      await _repo.saveExpense(m);
    }
    contents.aprendidas.forEach((merchant, name) {
      final category = Categoria.values.where((c) => c.name == name).firstOrNull;
      if (category != null) _repo.saveCategoryOverride(merchant, category);
    });
    await _repo.saveBudget(contents.presupuesto);
    _ref.read(budgetProvider.notifier).state = contents.presupuesto;
    if (mounted && nuevos.isNotEmpty) {
      state = [...nuevos, ...state]..sort((a, b) => b.date.compareTo(a.date));
    }
    return nuevos.length;
  }

  /// Vuelve a guardar un movimiento eliminado, con su mismo id (para "Deshacer").
  Future<void> restoreExpense(Movimiento expense) async {
    if (state.any((e) => e.id == expense.id)) return;
    await _repo.saveExpense(expense);
    state = [expense, ...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Guarda dónde se hizo el pago.
  Future<void> setLocation(String id, CapturedLocation location) async {
    final current = state.where((e) => e.id == id).firstOrNull;
    if (current == null) return;
    await updateExpense(current.copyWith(
      latitud: location.latitude,
      longitud: location.longitude,
      precision: location.accuracy,
      lugar: location.place,
    ));
  }

  /// Quita la ubicación de un solo movimiento.
  Future<void> removeLocation(String id) async {
    final current = state.where((e) => e.id == id).firstOrNull;
    if (current == null) return;
    await updateExpense(current.copyWith(quitarUbicacion: true));
  }

  /// Borra todas las ubicaciones; los movimientos se mantienen.
  Future<void> clearAllLocations() async {
    for (final m in state.where((e) => e.tieneUbicacion || e.lugar != null)) {
      await _repo.updateExpense(m.copyWith(quitarUbicacion: true));
    }
    state = [for (final m in state) m.copyWith(quitarUbicacion: true)];
  }

  /// Cambia la categoría de un movimiento. Con [remember], la app la recuerda
  /// para ese comercio y la aplica a los pagos anteriores de los gastos.
  Future<void> changeCategory(String id, Categoria category, {bool remember = false}) async {
    final current = state.where((e) => e.id == id).firstOrNull;
    if (current == null) return;
    await updateExpense(current.copyWith(category: category));
    if (!remember || current.esIngreso) return;

    await _repo.saveCategoryOverride(current.merchant, category);
    final key = current.merchant.toLowerCase().trim();
    for (final m in state.where((e) =>
        e.esGasto && e.id != id && e.merchant.toLowerCase().trim() == key && e.category != category)) {
      await updateExpense(m.copyWith(category: category));
    }
  }

  Future<void> updateExpense(Movimiento updated) async {
    await _repo.updateExpense(updated);
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  Future<void> updateBudget(double newBudget) async {
    await _repo.saveBudget(newBudget);
    _ref.read(budgetProvider.notifier).state = newBudget;
  }
}

// Ubicación del pago (solo cuando el usuario la pide)
final locationServiceProvider = Provider<LocationService>((ref) => DeviceLocationService());

// Checking Native Platform permissions helpers
final permissionsCheckerProvider = Provider((ref) {
  const channel = MethodChannel('com.example.mi_gasto/accessibility');

  return PermissionsChecker(channel);
});

class PermissionsChecker {
  final MethodChannel _channel;

  PermissionsChecker(this._channel);

  Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      // Ignore
    }
  }

  /// Acceso a notificaciones: la vía principal para leer los pagos.
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isNotificationListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {
      // Ignore
    }
  }

  Future<bool> isOverlayGranted() async {
    try {
      final bool? result = await _channel.invokeMethod('isOverlayPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {
      // Ignore
    }
  }

  /// Pide permiso para avisar "S/ 25.50 en Tambo" después de un pago (iPhone).
  Future<bool> requestNotificationPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestNotificationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Solo en desarrollo (iPhone): deja un pago en la cola nativa, como lo haría Atajos.
  Future<bool> debugEnqueue(Map<String, Object?> item) async {
    try {
      return await _channel.invokeMethod<bool>('debugEnqueue', item) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la app Atajos (iPhone).
  Future<void> openShortcuts() async {
    try {
      await _channel.invokeMethod('openShortcuts');
    } catch (_) {
      // Ignore
    }
  }

  Future<void> simulateNotification(String text) async {
    try {
      await _channel.invokeMethod('simulateNotification', {'text': text});
    } catch (_) {
      // Ignore
    }
  }
}

// 8. Profile Name State Provider
final profileNameProvider = StateNotifierProvider<ProfileStringNotifier, String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ProfileStringNotifier(prefs, 'profile_name', '');
});

// 9. Profile Email State Provider
final profileEmailProvider = StateNotifierProvider<ProfileStringNotifier, String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ProfileStringNotifier(prefs, 'profile_email', '');
});

class ProfileStringNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  final String _key;

  ProfileStringNotifier(this._prefs, this._key, String defaultValue)
      : super(_prefs.getString(_key) ?? defaultValue);

  Future<void> updateValue(String newValue) async {
    await _prefs.setString(_key, newValue);
    state = newValue;
  }
}

// 10. Passcode Security State Provider
final passcodeEnabledProvider = StateNotifierProvider<PasscodeNotifier, bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return PasscodeNotifier(prefs);
});

class PasscodeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'migasto_passcode_enabled';

  PasscodeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle() => setEnabled(!state);

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_key, value);
    state = value;
  }
}
