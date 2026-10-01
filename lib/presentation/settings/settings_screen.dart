import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/payment_reader.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/csv_export.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_icons.dart';
import '../expenses/alias_dialog.dart';
import '../lock/lock_gate.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationsOn = false;
  bool _screenOn = false;
  bool _batteryOn = false;
  bool _alertsOn = false;
  bool _overlayOn = false;
  final _simController = TextEditingController();

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _simController.dispose();
    super.dispose();
  }

  // Al volver de los ajustes del sistema se vuelve a leer el estado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    if (!_isAndroid) return;
    final permissions = ref.read(permissionsCheckerProvider);
    final notifications = await permissions.isNotificationListenerEnabled();
    final screen = await permissions.isAccessibilityEnabled();
    final battery = await permissions.isBatteryUnrestricted();
    final alerts = await permissions.isPostNotificationsGranted();
    final overlay = await permissions.isOverlayGranted();
    if (!mounted) return;
    setState(() {
      _alertsOn = alerts;
      _batteryOn = battery;
      _notificationsOn = notifications;
      _screenOn = screen;
      _overlayOn = overlay;
    });
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = ref.watch(providersEnabledProvider);
    final budget = ref.watch(budgetProvider);
    final lockOn = ref.watch(passcodeEnabledProvider);
    final permissions = ref.read(permissionsCheckerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 18),
          children: [
            Text('Ajustes', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            if (_isAndroid) ...[
              _label(context, 'Registro automático'),
              _box(context, [
                _SettingRow(
                  icon: AppIcons.bell,
                  title: 'Lectura de pagos',
                  subtitle: 'Lee las notificaciones de Yape, Plin y Google Wallet',
                  trailing: _status(context, _notificationsOn),
                  onTap: () async {
                    await permissions.openNotificationListenerSettings();
                  },
                ),
                _SettingRow(
                  icon: AppIcons.arrowUp,
                  title: 'Pagos que envías',
                  subtitle: 'Lee la constancia de Yape al pagar o enviar',
                  trailing: _status(context, _screenOn),
                  onTap: () async {
                    await permissions.openAccessibilitySettings();
                  },
                ),
                _SettingRow(
                  icon: AppIcons.bell,
                  title: 'Avisos de pagos',
                  subtitle: 'Una notificación cuando detecta un pago con la pantalla bloqueada',
                  trailing: _status(context, _alertsOn),
                  onTap: () async {
                    await permissions.requestPostNotifications();
                  },
                ),
                _SettingRow(
                  icon: AppIcons.lock,
                  title: 'Monto en pantalla bloqueada',
                  subtitle: ref.watch(showAmountLockedProvider)
                      ? 'Se ve el monto y el nombre sin desbloquear'
                      : 'Oculto: solo dice "Pago detectado"',
                  switchValue: ref.watch(showAmountLockedProvider),
                  onSwitch: (_) => ref.read(showAmountLockedProvider.notifier).toggle(),
                ),
                _SettingRow(
                  icon: AppIcons.bolt,
                  title: 'Batería sin restricciones',
                  subtitle: 'Evita que el teléfono duerma la lectura y se pierdan pagos',
                  trailing: _status(context, _batteryOn),
                  onTap: () async {
                    await permissions.openBatterySettings();
                  },
                ),
                _SettingRow(
                  icon: AppIcons.card,
                  title: 'Ventana flotante',
                  subtitle: 'Muestra cada pago para que lo confirmes',
                  trailing: _status(context, _overlayOn),
                  onTap: () async {
                    await permissions.requestOverlayPermission();
                  },
                ),
                const _AutoIncomeSwitch(),
                _SourceSwitch(label: 'Yape', sourceKey: 'yape', enabled: providers['yape'] ?? false),
                _SourceSwitch(label: 'Plin', sourceKey: 'plin', enabled: providers['plin'] ?? false),
                _SourceSwitch(
                  label: 'Google Wallet',
                  sourceKey: 'googlePay',
                  enabled: providers['googlePay'] ?? false,
                ),
              ]),
            ] else ...[
              _label(context, 'Registro automático'),
              _box(context, [
                _SettingRow(
                  icon: AppIcons.nfc,
                  title: 'Apple Pay en el POS',
                  subtitle: _lastWalletText(),
                  trailing: _status(context, _hasWalletPayment(), onText: 'Activo', offText: 'Configurar'),
                  onTap: () => context.push('/setup/apple-pay'),
                ),
                _SettingRow(
                  icon: AppIcons.img,
                  title: 'Capturas de Yape y Plin',
                  subtitle: 'Comparte la captura de la constancia a MiGasto',
                ),
              ]),
            ],
            if (ref.watch(expensesStateProvider).any((m) => m.tieneUbicacion || m.lugar != null)) ...[
              _label(context, 'Ubicación'),
              _box(context, [
                _SettingRow(
                  icon: AppIcons.pin,
                  title: 'Dónde pagaste',
                  subtitle: 'Tus pagos con ubicación, por zona',
                  onTap: () => context.push('/where'),
                ),
                _SettingRow(
                  icon: AppIcons.trash,
                  title: 'Borrar todas las ubicaciones',
                  subtitle: 'Los movimientos se mantienen',
                  onTap: () => _clearLocations(context),
                ),
              ]),
            ],
            _label(context, 'Tus datos'),
            _box(context, [
              _SettingRow(
                icon: AppIcons.wallet,
                title: 'Presupuesto de gastos',
                trailingText: formatSoles(budget),
                onTap: () => _editBudget(context, budget),
              ),
              _SettingRow(
                icon: AppIcons.tag,
                title: 'Aprendidas de tus cambios',
                subtitle: 'Categorías que la app ya recuerda por comercio',
                onTap: () => _showLearned(context),
              ),
              _SettingRow(
                icon: AppIcons.tag,
                title: 'Nombres guardados',
                subtitle: 'Cómo ves a cada persona o comercio',
                onTap: () => _showAliases(context),
              ),
              _SettingRow(
                icon: AppIcons.file,
                title: 'Exportar a CSV',
                subtitle: 'Copia tus movimientos, sin ubicaciones',
                onTap: () => _exportCsv(context),
              ),
              _SettingRow(
                icon: AppIcons.lock,
                title: 'Respaldo cifrado',
                subtitle: _backupSubtitle(ref.watch(lastBackupProvider)),
                onTap: () => _crearRespaldo(context),
              ),
              _SettingRow(
                icon: AppIcons.file,
                title: 'Restaurar un respaldo',
                subtitle: 'Desde un archivo .mgb, con tu contraseña',
                onTap: () => _restaurarRespaldo(context),
              ),
              _SettingRow(
                icon: AppIcons.lock,
                title: 'Bloqueo con huella o PIN',
                subtitle: 'Usa el desbloqueo de tu teléfono',
                switchValue: lockOn,
                onSwitch: (v) => _toggleLock(context, v),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(
                'Tus datos se guardan solo en este teléfono.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (kDebugMode) ...[
              _label(context, 'Solo desarrollo'),
              _simulator(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _box(BuildContext context, List<Widget> rows) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.box),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: theme.colorScheme.outline, height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }

  /// Estado con ícono y texto, nunca solo color.
  bool _hasWalletPayment() =>
      ref.watch(expensesStateProvider).any((m) => m.canal == CanalMovimiento.wallet);

  String _lastWalletText() {
    final last = ref
        .watch(expensesStateProvider)
        .where((m) => m.canal == CanalMovimiento.wallet)
        .firstOrNull;
    if (last == null) return 'Todavía no registramos ningún pago';
    return 'Último pago registrado: ${DateFormat("d MMM, HH:mm", 'es').format(last.date)}';
  }

  Widget _status(BuildContext context, bool on,
      {String onText = 'Activa', String offText = 'Activar'}) {
    final colors = context.appColors;
    final color = on ? colors.budgetOk : colors.budgetWarning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(on ? AppIcons.checkCircle : AppIcons.alert, size: AppIconSize.small, color: color),
        const SizedBox(width: 5),
        Text(
          on ? onText : offText,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- acciones

  Future<void> _editBudget(BuildContext context, double current) async {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(expensesStateProvider.notifier);
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Presupuesto de gastos'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'S/ ', hintText: '1200'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null && parsed > 0) Navigator.pop(context, parsed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await notifier.updateBudget(value);
    messenger.showSnackBar(const SnackBar(content: Text('Presupuesto actualizado')));
  }

  void _showAliases(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final theme = Theme.of(context);
          final entries = ref.watch(aliasesProvider).entries.toList()
            ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Nombres guardados', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Para ponerle nombre a alguien, abre un movimiento suyo y toca "De" o "Para".',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Aún no has guardado ninguno.', style: theme.textTheme.bodyMedium),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in entries)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                minTileHeight: AppSizes.minTouch,
                                title: Text(e.value),
                                subtitle: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => showAliasDialog(context, ref, e.key),
                                trailing: IconButton(
                                  tooltip: 'Quitar nombre de ${e.value}',
                                  icon: AppIcon(AppIcons.trash,
                                      size: AppIconSize.small,
                                      color: theme.colorScheme.onSurfaceVariant),
                                  onPressed: () => ref.read(aliasesProvider.notifier).remove(e.key),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLearned(BuildContext context) {
    final repo = ref.read(expenseRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setSheet) {
            final overrides = repo.getAllCategoryOverrides().entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Aprendidas de tus cambios', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Cuando cambias la categoría de un pago, la app lo recuerda para ese comercio.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      if (overrides.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('Todavía no cambiaste ninguna categoría.',
                              style: theme.textTheme.bodyMedium),
                        )
                      else
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final e in overrides)
                                ListTile(
                                  minTileHeight: AppSizes.minTouch,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(e.key),
                                  subtitle: Text(_categoryName(e.value)),
                                  trailing: IconButton(
                                    tooltip: 'Olvidar ${e.key}',
                                    onPressed: () async {
                                      await repo.deleteCategoryOverride(e.key);
                                      setSheet(() {});
                                    },
                                    icon: AppIcon(
                                      AppIcons.trash,
                                      color: context.appColors.budgetOver,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (overrides.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            await repo.clearAllCategoryOverrides();
                            setSheet(() {});
                          },
                          child: const Text('Olvidar todas'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _categoryName(String name) {
    const names = {
      'alimentacion': 'Alimentación',
      'transporte': 'Transporte',
      'compras': 'Compras',
      'servicios': 'Servicios',
      'entretenimiento': 'Entretenimiento',
      'otros': 'Otros',
    };
    return names[name] ?? name;
  }

  Future<void> _clearLocations(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(expensesStateProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todas las ubicaciones'),
        content: const Text('Se borra dónde hiciste cada pago. Tus gastos e ingresos se mantienen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.appColors.budgetOver),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await notifier.clearAllLocations();
    messenger.showSnackBar(const SnackBar(content: Text('Ubicaciones borradas')));
  }

  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final csv = movimientosToCsv(ref.read(expensesStateProvider));
    await Clipboard.setData(ClipboardData(text: csv));
    messenger.showSnackBar(const SnackBar(content: Text('Movimientos copiados al portapapeles')));
  }

  // ------------------------------------------------------------ respaldo

  String _backupSubtitle(DateTime? last) {
    if (last == null) return 'Aún no has hecho uno. Si pierdes el teléfono, pierdes tus datos.';
    return 'Último: ${DateFormat('d MMM y, HH:mm', 'es').format(last)}';
  }

  /// Muestra una espera mientras corre [task] (derivar la clave puede tardar unos segundos).
  Future<T> _conEspera<T>(BuildContext context, String mensaje, Future<T> Function() task) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 20),
              Expanded(child: Text(mensaje)),
            ],
          ),
        ),
      ),
    );
    try {
      return await task();
    } finally {
      navigator.pop();
    }
  }

  Future<void> _crearRespaldo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(expensesStateProvider.notifier);
    final lastBackup = ref.read(lastBackupProvider.notifier);
    final prefs = ref.read(sharedPreferencesProvider);

    final passphrase = await showDialog<String>(
      context: context,
      builder: (_) => const _PassphraseDialog(creating: true),
    );
    if (passphrase == null || !context.mounted) return;

    try {
      final bytes = await _conEspera(
        context,
        'Cifrando tu respaldo…',
        () => const BackupService().encrypt(notifier.contenidoDeRespaldo(), passphrase),
      );
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/MiGasto-respaldo-$stamp.${BackupService.extension}');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'Respaldo de MiGasto',
        text: 'Respaldo cifrado de MiGasto. Solo se abre con tu contraseña.',
      ));
      final now = DateTime.now();
      await prefs.setString(keyLastBackup, now.toUtc().toIso8601String());
      lastBackup.state = now;
      messenger.showSnackBar(const SnackBar(
        content: Text('Respaldo creado. Guárdalo en un lugar seguro (Drive, correo, tu computadora).'),
      ));
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo crear el respaldo.')));
    }
  }

  Future<void> _restaurarRespaldo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(expensesStateProvider.notifier);

    final picked = await FilePicker.pickFiles(dialogTitle: 'Elige tu respaldo de MiGasto');
    if (picked.isEmpty || !context.mounted) return;
    final path = picked.first.path;
    if (path == null) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo leer el archivo.')));
      return;
    }
    final data = await File(path).readAsBytes();
    if (!context.mounted) return;

    final passphrase = await showDialog<String>(
      context: context,
      builder: (_) => const _PassphraseDialog(creating: false),
    );
    if (passphrase == null || !context.mounted) return;

    try {
      final contents = await _conEspera(
        context,
        'Abriendo tu respaldo…',
        () => const BackupService().decrypt(data, passphrase),
      );
      if (!context.mounted) return;
      final nuevos = notifier.cuantosSonNuevos(contents);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restaurar respaldo'),
          content: Text(
            'Creado el ${DateFormat('d MMM y, HH:mm', 'es').format(contents.creado.toLocal())}.\n\n'
            '• ${contents.movimientos.length} movimientos en el respaldo, $nuevos nuevos para este teléfono.\n'
            '• Presupuesto: ${formatSoles(contents.presupuesto)}.\n\n'
            'No se borra nada de lo que ya tienes.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
          ],
        ),
      );
      if (ok != true) return;
      final agregados = await notifier.restaurarRespaldo(contents);
      messenger.showSnackBar(SnackBar(
        content: Text(agregados == 0
            ? 'No había nada nuevo: ya tenías todos esos movimientos.'
            : 'Se restauraron $agregados movimientos.'),
      ));
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir el respaldo.')));
    }
  }

  Future<void> _toggleLock(BuildContext context, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(passcodeEnabledProvider.notifier);
    final auth = ref.read(localAuthProvider);

    if (!enable) {
      await notifier.setEnabled(false);
      return;
    }
    // Se comprueba que el teléfono tenga un desbloqueo antes de activarlo.
    var ok = false;
    try {
      if (await auth.isDeviceSupported()) {
        ok = await auth.authenticate(
          localizedReason: 'Confirma para activar el bloqueo de MiGasto',
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Configura un PIN, huella o rostro en tu teléfono para usar el bloqueo.'),
          ),
        );
        return;
      }
    } catch (_) {
      ok = false;
    }
    if (ok) await notifier.setEnabled(true);
  }

  // -------------------------------------------------------------- simulador

  Widget _simulator(BuildContext context) {
    final theme = Theme.of(context);
    const samples = [
      'Yapeaste S/ 18.50 a Starbucks',
      'Juan Pérez te yapeó S/ 15.00',
      'Compra por S/ 89.20 en Metro con Google Wallet',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.box),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Probar la lectura de pagos', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Escribe un texto como el de una notificación. Pasa por el mismo camino que un pago real.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in samples)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _simController.text = s),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _simController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Texto de la notificación'),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _runSimulation, child: const Text('Probar')),
        ],
      ),
    );
  }

  Future<void> _runSimulation() async {
    final text = _simController.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(expensesStateProvider.notifier);
    final permissions = ref.read(permissionsCheckerProvider);

    // Mismas reglas que usa la detección real (assets/reader_rules.json).
    final reader = await PaymentReader.fromAsset();
    final parsed = reader.parse(text);
    if (parsed == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos leer este pago. Incluye el monto, por ejemplo S/ 15.00, y la app (Yape, Plin o Google Wallet).',
          ),
        ),
      );
      return;
    }

    if (_isAndroid) {
      // Pasa por el mismo camino que una notificación real.
      await permissions.simulateNotification(text);
    } else {
      // iPhone: el pago pasa por la cola nativa, como el de la acción de Atajos.
      await permissions.debugEnqueue({
        'amount': parsed.amount,
        'peer': parsed.peer,
        'provider': parsed.provider,
        'type': parsed.type,
        'channel': 'wallet',
        'card': 'Visa BBVA ···4821',
        'rawText': text,
        'confirmed': parsed.type == 'gasto',
        'at': DateTime.now().millisecondsSinceEpoch,
      });
      await notifier.drainNativeQueue();
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Leído: ${parsed.type} de ${formatSoles(parsed.amount)}')),
    );
  }
}

/// Fila de ajustes: ícono, título, subtítulo y, a la derecha, estado, valor,
/// interruptor o flecha.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.switchValue,
    this.onSwitch,
  });

  final AppIcons icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSwitch = switchValue != null;

    Widget? right = trailing;
    if (isSwitch) {
      right = Switch(value: switchValue!, onChanged: onSwitch);
    } else if (trailingText != null) {
      right = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText!,
            style: AppText.amount(
                theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          AppIcon(AppIcons.chevron, size: AppIconSize.small, color: scheme.onSurfaceVariant),
        ],
      );
    } else if (right == null && onTap != null) {
      right = AppIcon(AppIcons.chevron, size: AppIconSize.small, color: scheme.onSurfaceVariant);
    }

    return Semantics(
      container: true,
      button: onTap != null && !isSwitch,
      toggled: isSwitch ? switchValue : null,
      label: [title, ?subtitle].join('. '),
      excludeSemantics: !isSwitch,
      child: InkWell(
        onTap: isSwitch ? () => onSwitch?.call(!switchValue!) : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                AppIcon(icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall!.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (right != null) ...[const SizedBox(width: 8), right],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interruptor de una fuente de pago, con su punto de color.
/// Pide la contraseña del respaldo. Al crear pide confirmarla.
class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.creating});

  final bool creating;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _first.text;
    if (widget.creating) {
      if (value.length < BackupService.minPassphraseLength) {
        setState(() => _error = 'Usa al menos ${BackupService.minPassphraseLength} caracteres.');
        return;
      }
      if (value != _second.text) {
        setState(() => _error = 'Las contraseñas no coinciden.');
        return;
      }
    } else if (value.isEmpty) {
      setState(() => _error = 'Escribe la contraseña.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Contraseña del respaldo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.creating)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Elige una contraseña que recuerdes. MiGasto no la guarda: si la olvidas, nadie podrá abrir el respaldo.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            TextField(
              controller: _first,
              obscureText: !_visible,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: _visible ? 'Ocultar' : 'Mostrar',
                  icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
              onSubmitted: (_) => widget.creating ? null : _submit(),
            ),
            if (widget.creating) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _second,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Repite la contraseña'),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: _submit,
          child: Text(widget.creating ? 'Crear respaldo' : 'Abrir'),
        ),
      ],
    );
  }
}

class _AutoIncomeSwitch extends ConsumerWidget {
  const _AutoIncomeSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final on = ref.watch(autoSaveIncomeProvider);
    final notifier = ref.read(autoSaveIncomeProvider.notifier);
    return Semantics(
      container: true,
      toggled: on,
      label: 'Guardar ingresos automáticamente',
      excludeSemantics: true,
      child: InkWell(
        onTap: notifier.toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guardar ingresos automáticamente', style: theme.textTheme.titleSmall),
                      Text(
                        on
                            ? 'Los ingresos se guardan solos, como los gastos.'
                            : 'Apagado: cada ingreso espera tu confirmación.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(value: on, onChanged: (_) => notifier.toggle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceSwitch extends ConsumerWidget {
  const _SourceSwitch({
    required this.label,
    required this.sourceKey,
    required this.enabled,
  });

  final String label;
  final String sourceKey;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = context.appColors.sourceColor(sourceKey);
    return Semantics(
      container: true,
      toggled: enabled,
      label: 'Registrar pagos de $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => ref.read(providersEnabledProvider.notifier).toggleProvider(sourceKey),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const SizedBox(width: 5),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 17),
                Expanded(child: Text('Registrar pagos de $label', style: theme.textTheme.titleSmall)),
                Switch(
                  value: enabled,
                  onChanged: (_) =>
                      ref.read(providersEnabledProvider.notifier).toggleProvider(sourceKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
