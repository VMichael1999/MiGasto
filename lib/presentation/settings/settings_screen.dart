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
import '../../core/theme/mg_colors.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/mg_toast.dart';
import '../../data/debug_mock_data.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/payment_reader.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/csv_export.dart';
import '../../shared/format.dart';
import '../../shared/profile.dart';
import '../../shared/widgets/custom_icons.dart';
import '../lock/lock_gate.dart';
import '../providers.dart';
import '../../core/layout/landscape_pane.dart';
import '../../core/layout/adaptive.dart';
import '../../core/widgets/adaptive_sheet.dart';
import '../../shared/dispose_later.dart';
import '../payments/scheduled_payments_providers.dart';
import '../plan/plan_providers.dart';
import 'widgets/connected_accounts_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final lockOn = ref.watch(passcodeEnabledProvider);
    final budget = ref.watch(budgetProvider);
    final permissions = ref.read(permissionsCheckerProvider);

    final catCount = Categoria.gastos.length + ref.watch(customCategoriesProvider).length;

    final privacyNote = Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(
                  children: const [
                    Text(
                      'Tus datos se guardan solo en este teléfono.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: MgColors.ink3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'MiGasto v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: MgColors.ink3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
    // Solo en compilaciones de desarrollo.
    final debugSimulator = kDebugMode
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: _simulator(context),
          )
        : null;
    final topNav = _buildTopNav(context);
    final userCard = _buildUserCard(context);
    final accountGroup = _buildAccountGroup(context, catCount);
    final dataGroup = _buildDataSecurityGroup(context, budget, lockOn);
    final androidGroup = _isAndroid ? _buildAndroidGroup(context, permissions) : null;
    final logout = Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: _buildLogoutCard(context),
    );

    // Teléfono girado: perfil, cuenta y cierre de sesión a la izquierda; datos,
    // seguridad y permisos a la derecha.
    if (context.isLandscapePhone) {
      Widget side(List<Widget> children) => LandscapePane(
            padding: const EdgeInsets.only(bottom: 32),
            children: children,
          );
      return Scaffold(
        backgroundColor: MgColors.bg,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              side([topNav, userCard, accountGroup, logout]),
              side([
                dataGroup,
                ?androidGroup,
                privacyNote,
                ?debugSimulator,
              ]),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topNav,
              userCard,
              accountGroup,
              dataGroup,
              ?androidGroup,
              logout,
              privacyNote,
              ?debugSimulator,
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de navegación superior con botón volver y título Perfil
  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: MgColors.ink2,
              ),
            ),
          ),
          const Text(
            'Perfil',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MgColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  /// Tarjeta de usuario (.pf-card): iniciales, nombre y correo guardados por el usuario.
  Widget _buildUserCard(BuildContext context) {
    final name = ref.watch(profileNameProvider).trim();
    final email = ref.watch(profileEmailProvider).trim();
    final initials = initialsOf(name);
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Avatar 56×56 (.pf-av)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x227C5CFF),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0x447C5CFF)),
            ),
            alignment: Alignment.center,
            child: initials.isEmpty
                ? const Icon(Icons.person_outline_rounded,
                    size: 26, color: MgColors.acc2)
                : Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MgColors.acc2,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Nombre y correo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Tu perfil' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? 'Agrega tu nombre y correo' : email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          // Botón editar perfil
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => _editProfile(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 17,
                color: MgColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grupo: Cuenta (.grp)
  Widget _buildAccountGroup(BuildContext context, int catCount) {
    final providers = ref.watch(providersEnabledProvider);
    final activeCount = providers.values.where((on) => on).length;
    return _buildGroup(
      title: 'CUENTA',
      children: [
        // Yape, Plin y Google Wallet: solo se detectan en Android (lectura de notificaciones).
        if (_isAndroid) ...[
          _buildRow(
            icon: Icons.account_balance_outlined,
            title: 'Pagos detectados',
            tag: '$activeCount de ${providers.length}',
            onTap: () => ConnectedAccountsSheet.show(context),
          ),
          _buildDivider(),
        ],
        _buildRow(
          icon: Icons.sell_outlined,
          title: 'Categorías',
          tag: '$catCount',
          onTap: () => _showCustomCategories(context),
        ),
      ],
    );
  }

  /// Grupo: Datos y seguridad (.grp)
  Widget _buildDataSecurityGroup(BuildContext context, double budget, bool lockOn) {
    final lastBackup = ref.watch(lastBackupProvider);
    return _buildGroup(
      title: 'DATOS Y SEGURIDAD',
      children: [
        _buildRow(
          icon: Icons.map_outlined,
          title: 'Dónde gasto',
          onTap: () => context.push('/where'),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Presupuesto mensual',
          tag: budget > 0 ? formatSoles(budget) : 'Sin definir',
          onTap: () => _editBudget(context, budget),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.description_outlined,
          title: 'Exportar a CSV',
          onTap: () => _exportCsv(context),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.lock_outline_rounded,
          title: 'Respaldo cifrado',
          tag: lastBackup != null ? 'Hecho' : 'Pendiente',
          onTap: () => _crearRespaldo(context),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.file_upload_outlined,
          title: 'Restaurar respaldo',
          onTap: () => _restaurarRespaldo(context),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.fingerprint_rounded,
          title: 'Bloqueo con huella o PIN',
          trailing: Switch(
            value: lockOn,
            onChanged: (v) => _toggleLock(context, v),
          ),
        ),
      ],
    );
  }

  /// Grupo Android: Permisos automáticos
  Widget _buildAndroidGroup(BuildContext context, dynamic permissions) {
    return _buildGroup(
      title: 'REGISTRO AUTOMÁTICO (ANDROID)',
      children: [
        _buildRow(
          icon: Icons.notifications_active_outlined,
          title: 'Lectura de notificaciones',
          tag: _notificationsOn ? 'Activo' : 'Activar',
          onTap: () => permissions.openNotificationListenerSettings(),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.touch_app_outlined,
          title: 'Lectura de pantalla',
          tag: _screenOn ? 'Activo' : 'Activar',
          onTap: () => permissions.openAccessibilitySettings(),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.notifications_none_outlined,
          title: 'Avisos de pagos',
          tag: _alertsOn ? 'Activo' : 'Activar',
          onTap: () => permissions.requestPostNotifications(),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.picture_in_picture_alt_outlined,
          title: 'Ventana flotante',
          tag: _overlayOn ? 'Activo' : 'Activar',
          onTap: () => permissions.requestOverlayPermission(),
        ),
        _buildDivider(),
        _buildRow(
          icon: Icons.battery_charging_full_outlined,
          title: 'Batería sin restricciones',
          tag: _batteryOn ? 'Activo' : 'Activar',
          onTap: () => permissions.openBatterySettings(),
        ),
      ],
    );
  }

  /// Tarjeta de cerrar sesión al final de la pantalla
  Widget _buildLogoutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final confirm = await ConfirmSheet.show(
              context,
              title: '¿Cerrar sesión?',
              message: 'Tendrás que volver a iniciar sesión para acceder a tus movimientos.',
              confirmLabel: 'Cerrar sesión',
              isDestructive: true,
              icon: Icons.logout_rounded,
            );
            if (confirm && context.mounted) {
              await ref.read(sharedPreferencesProvider).setBool('is_logged_in', false);
              if (context.mounted) {
                MgToast.show(context, message: 'Sesión cerrada.');
                context.go('/login');
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x22FF5C6E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: MgColors.down,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: MgColors.down,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contenedor de grupo de opciones (.grp)
  Widget _buildGroup({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: MgColors.ink3,
              ),
            ),
          ),
          Material(
            color: MgColors.card,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila estándar interactiva (.rw) con InkWell confinado al radio de la tarjeta
  Widget _buildRow({
    required IconData icon,
    required String title,
    String? tag,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: MgColors.acc.withValues(alpha: 0.12),
        highlightColor: MgColors.acc.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
          children: [
            // Ícono dentro de squircle suave (.rw .ic)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0x22FF5C6E) : MgColors.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 17,
                color: isDestructive ? MgColors.down : MgColors.ink2,
              ),
            ),
            const SizedBox(width: 12),
            // Título
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? MgColors.down : MgColors.ink,
                ),
              ),
            ),
            // Etiqueta tag (.tag)
            if (tag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tag == 'En uso'
                      ? const Color(0x227C5CFF)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: tag == 'En uso' ? FontWeight.w600 : FontWeight.w400,
                    color: tag == 'En uso' ? MgColors.acc2 : MgColors.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Trailing o Chevron
            if (trailing != null)
              trailing
            else if (!isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: MgColors.ink3,
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  // ---------------------------------------------------------------- acciones

  Future<void> _editProfile(BuildContext context) async {
    final nameCtrl = TextEditingController(text: ref.read(profileNameProvider));
    final emailCtrl = TextEditingController(text: ref.read(profileEmailProvider));
    final nameNotifier = ref.read(profileNameProvider.notifier);
    final emailNotifier = ref.read(profileEmailProvider.notifier);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MgColors.card,
        title: const Text('Tu perfil', style: TextStyle(color: MgColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: MgColors.ink),
              decoration: const InputDecoration(hintText: 'Nombre'),
            ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: MgColors.ink),
              decoration: const InputDecoration(hintText: 'Correo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    disposeControllersLater([nameCtrl, emailCtrl]);
    if (ok != true) return;
    await nameNotifier.updateValue(name);
    await emailNotifier.updateValue(email);
  }

  Future<void> _editBudget(BuildContext context, double current) async {
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    final notifier = ref.read(expensesStateProvider.notifier);
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MgColors.card,
        title: const Text('Presupuesto de gastos', style: TextStyle(color: MgColors.ink)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: MgColors.ink),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'S/ ', hintText: 'Monto del mes'),
        ),
        actions: [
          if (current > 0)
            TextButton(onPressed: () => Navigator.pop(ctx, 0.0), child: const Text('Quitar')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null && parsed > 0) Navigator.pop(ctx, parsed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    disposeControllersLater([controller]);
    if (value == null || !context.mounted) return;
    await notifier.updateBudget(value);
    if (context.mounted) {
      MgToast.show(context, message: value > 0 ? 'Presupuesto actualizado' : 'Presupuesto quitado');
    }
  }

  void _showCustomCategories(BuildContext context) {
    showAdaptiveSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (ctx, ref, _) {
          final propias = ref.watch(customCategoriesProvider);
          return Container(
            decoration: const BoxDecoration(
              color: MgColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Mis categorías',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: MgColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Las creas al registrar un movimiento. Si borras una, sus movimientos pasan a verse como "Otros".',
                        style: TextStyle(fontSize: 12, color: MgColors.ink2),
                      ),
                      const SizedBox(height: 12),
                      if (propias.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Aún no has creado ninguna categoría propia.',
                              style: TextStyle(color: MgColors.ink2),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final p in propias)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  minTileHeight: AppSizes.minTouch,
                                  leading: Icon(customIconFor(p.icono), color: MgColors.acc2),
                                  title: Text(p.nombre, style: const TextStyle(color: MgColors.ink)),
                                  subtitle: Text(p.tipo == TipoMovimiento.ingreso ? 'Ingreso' : 'Gasto',
                                      style: const TextStyle(color: MgColors.ink2, fontSize: 12)),
                                  trailing: IconButton(
                                    tooltip: 'Borrar ${p.nombre}',
                                    icon: const Icon(Icons.delete_outline, size: 20, color: MgColors.down),
                                    onPressed: () =>
                                        ref.read(customCategoriesProvider.notifier).remove(p.id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final csv = movimientosToCsv(
      ref.read(expensesStateProvider),
      categoriasPropias: ref.read(customCategoriesProvider),
    );
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) {
      MgToast.show(context, message: 'Movimientos copiados al portapapeles');
    }
  }

  Future<T> _conEspera<T>(BuildContext context, String mensaje, Future<T> Function() task) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: MgColors.card,
          content: Row(
            children: [
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: MgColors.acc, strokeWidth: 3)),
              const SizedBox(width: 20),
              Expanded(child: Text(mensaje, style: const TextStyle(color: MgColors.ink))),
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
      if (context.mounted) {
        MgToast.show(context, message: 'Respaldo creado con éxito.');
      }
    } on BackupException catch (e) {
      if (context.mounted) MgToast.show(context, message: e.message);
    } catch (_) {
      if (context.mounted) MgToast.show(context, message: 'No se pudo crear el respaldo.');
    }
  }

  Future<void> _restaurarRespaldo(BuildContext context) async {
    final notifier = ref.read(expensesStateProvider.notifier);
    final picked = await FilePicker.pickFiles(dialogTitle: 'Elige tu respaldo de MiGasto');
    if (picked.isEmpty || !context.mounted) return;
    final path = picked.first.path;
    if (path == null) {
      MgToast.show(context, message: 'No se pudo leer el archivo.');
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
          backgroundColor: MgColors.card,
          title: const Text('Restaurar respaldo', style: TextStyle(color: MgColors.ink)),
          content: Text(
            'Creado el ${DateFormat('d MMM y, HH:mm', 'es').format(contents.creado.toLocal())}.\n\n'
            '• ${contents.movimientos.length} movimientos en el respaldo, $nuevos nuevos para este teléfono.\n'
            '• Presupuesto: ${formatSoles(contents.presupuesto)}.\n\n'
            'No se borra nada de lo que ya tienes.',
            style: const TextStyle(color: MgColors.ink2),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final agregados = await notifier.restaurarRespaldo(contents);
      if (context.mounted) {
        MgToast.show(
          context,
          message: agregados == 0
              ? 'No había nada nuevo: ya tenías todos esos movimientos.'
              : 'Se restauraron $agregados movimientos.',
        );
      }
    } on BackupException catch (e) {
      if (context.mounted) MgToast.show(context, message: e.message);
    } catch (_) {
      if (context.mounted) MgToast.show(context, message: 'No se pudo abrir el respaldo.');
    }
  }

  Future<void> _toggleLock(BuildContext context, bool enable) async {
    final notifier = ref.read(passcodeEnabledProvider.notifier);
    final auth = ref.read(localAuthProvider);

    if (!enable) {
      await notifier.setEnabled(false);
      return;
    }
    var ok = false;
    try {
      if (await auth.isDeviceSupported()) {
        ok = await auth.authenticate(
          localizedReason: 'Confirma para activar el bloqueo de MiGasto',
        );
      } else {
        if (context.mounted) {
          MgToast.show(context, message: 'Configura un PIN, huella o rostro en tu teléfono para usar el bloqueo.');
        }
        return;
      }
    } catch (_) {
      ok = false;
    }
    if (ok) await notifier.setEnabled(true);
  }

  // -------------------------------------------------------------- simulador

  Widget _simulator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Solo existe en compilaciones de desarrollo.
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos de ejemplo',
                      style: TextStyle(fontWeight: FontWeight.w600, color: MgColors.ink),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Solo en debug: sueldo de S/ 15,000 y unos S/ 7,500 en gastos. No se guardan en la base.',
                      style: TextStyle(fontSize: 12, color: MgColors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                activeThumbColor: MgColors.acc,
                value: debugMockEnabled(ref.read(sharedPreferencesProvider), runningUnderTest: false),
                onChanged: (on) async {
                  await ref.read(sharedPreferencesProvider).setBool(keyDebugMockData, on);
                  await ref.read(expensesStateProvider.notifier).reload();
                  // Los planes y pagos de ejemplo también se vuelven a leer.
                  ref.invalidate(categoryLimitsProvider);
                  ref.invalidate(savingsGoalProvider);
                  ref.invalidate(scheduledPaymentsProvider);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const Divider(color: MgColors.line, height: 20),
          const Text('Probar la lectura de pagos', style: TextStyle(fontWeight: FontWeight.w600, color: MgColors.ink)),
          const SizedBox(height: 4),
          const Text(
            'Escribe un texto como el de una notificación. Pasa por el mismo camino que un pago real.',
            style: TextStyle(fontSize: 12, color: MgColors.ink2),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _simController,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(color: MgColors.ink),
            decoration: const InputDecoration(hintText: 'Ej.: Yapeaste S/ 18.50 a una tienda'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _runSimulation, child: const Text('Probar')),
        ],
      ),
    );
  }

  Future<void> _runSimulation() async {
    final text = _simController.text.trim();
    if (text.isEmpty) return;
    final notifier = ref.read(expensesStateProvider.notifier);
    final permissions = ref.read(permissionsCheckerProvider);

    final reader = await PaymentReader.fromAsset();
    final parsed = reader.parse(text);
    if (parsed == null) {
      if (mounted) {
        MgToast.show(
          context,
          message: 'No pudimos leer este pago. Incluye el monto y la app (Yape, Plin o Google Wallet).',
        );
      }
      return;
    }

    if (_isAndroid) {
      await permissions.simulateNotification(text);
    } else {
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
    if (mounted) {
      MgToast.show(context, message: 'Leído: ${parsed.type} de ${formatSoles(parsed.amount)}');
    }
  }
}

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
    return AlertDialog(
      backgroundColor: MgColors.card,
      title: const Text('Contraseña del respaldo', style: TextStyle(color: MgColors.ink)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.creating)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Elige una contraseña que recuerdes. MiGasto no la guarda: si la olvidas, nadie podrá abrir el respaldo.',
                  style: TextStyle(fontSize: 12, color: MgColors.ink2),
                ),
              ),
            TextField(
              controller: _first,
              obscureText: !_visible,
              autofocus: true,
              style: const TextStyle(color: MgColors.ink),
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
                style: const TextStyle(color: MgColors.ink),
                decoration: const InputDecoration(labelText: 'Repite la contraseña'),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: MgColors.down),
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
