import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/mg_card.dart';
import '../providers.dart';

/// Último paso de la bienvenida: privacidad y permisos.
///
/// En Android explica, antes de pedir nada, qué lee la app y qué no (el aviso
/// destacado que exige Google Play) y guía los permisos de la lectura
/// automática. Siempre se puede seguir con solo registro manual. En iPhone
/// lleva a la guía de Apple Pay.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _listenerOn = false;
  bool _overlayOn = false;
  bool _alertsOn = false;
  bool _batteryOn = false;
  bool _locationOn = false;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes del sistema se actualizan los pasos.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final location = await ref.read(locationServiceProvider).hasPermission();
    if (mounted && location != _locationOn) setState(() => _locationOn = location);
    if (!_isAndroid) return;
    final permissions = ref.read(permissionsCheckerProvider);
    final listener = await permissions.isNotificationListenerEnabled();
    final overlay = await permissions.isOverlayGranted();
    final alerts = await permissions.isPostNotificationsGranted();
    final battery = await permissions.isBatteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _listenerOn = listener;
      _overlayOn = overlay;
      _alertsOn = alerts;
      _batteryOn = battery;
    });
  }

  Future<void> _askLocation() async {
    final granted = await ref.read(locationServiceProvider).requestPermission();
    if (mounted) setState(() => _locationOn = granted);
  }

  /// Cierra la bienvenida y sigue con el inicio de sesión.
  Future<void> _finish() async {
    await ref.read(sharedPreferencesProvider).setBool('onboarding_complete', true);
    if (mounted) context.go('/login');
  }

  Future<void> _primary() async {
    if (!_isAndroid) {
      // iPhone: la guía de Apple Pay es el siguiente paso.
      context.go('/setup/apple-pay?onboarding=1');
      return;
    }
    final permissions = ref.read(permissionsCheckerProvider);
    if (!_listenerOn) {
      await permissions.openNotificationListenerSettings();
    } else if (!_overlayOn) {
      await permissions.requestOverlayPermission();
    } else if (!_alertsOn) {
      await permissions.requestPostNotifications();
    } else if (!_batteryOn) {
      await permissions.openBatterySettings();
    } else {
      await _finish();
    }
  }

  String get _primaryLabel {
    if (!_isAndroid) return 'Continuar';
    if (!_listenerOn) return 'Aceptar y activar la lectura';
    if (!_overlayOn) return 'Permitir la ventana flotante';
    if (!_alertsOn) return 'Permitir los avisos';
    if (!_batteryOn) return 'Quitar la restricción de batería';
    return 'Empezar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAndroid
                          ? 'Registra tus pagos\nsin escribirlos'
                          : 'Registra lo que gastas\ny lo que recibes',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                        height: 1.15,
                        color: MgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isAndroid
                          ? 'MiGasto anota los pagos de Yape, Plin y Google Wallet por ti y te deja confirmar cada uno.'
                          : 'Anota tus gastos e ingresos en segundos y mira cuánto te queda del mes.',
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: MgColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _privacyBox(),
                    if (_isAndroid) ...[
                      const SizedBox(height: 22),
                      _step(1, 'Activa la lectura de pagos',
                          'En Acceso a notificaciones, activa MiGasto', _listenerOn),
                      _step(2, 'Permite la ventana flotante',
                          'Para confirmar cada pago al instante. Es opcional.', _overlayOn),
                      _step(3, 'Recibe un aviso de cada pago',
                          'Una notificación cuando detecta un pago con la pantalla bloqueada.', _alertsOn),
                      _step(4, 'Evita que el teléfono la duerma',
                          'En Batería, elige «No restringido». Así no se pierden pagos.', _batteryOn),
                    ],
                    // Ubicación (opcional, también en iPhone): solo mientras la app está en uso.
                    SizedBox(height: _isAndroid ? 0 : 22),
                    _step(_isAndroid ? 5 : 1, 'Permite la ubicación (opcional)',
                        'Para ver en el mapa dónde pagaste y centrarlo donde estás. Solo se usa cuando tú lo pides, nunca en segundo plano.',
                        _locationOn),
                    if (!_locationOn)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _askLocation,
                            icon: const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text('Permitir ubicación'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MgColors.acc2,
                              side: const BorderSide(color: MgColors.line),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _primary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MgColors.acc,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(_primaryLabel),
                    ),
                  ),
                  if (_isAndroid)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(foregroundColor: MgColors.ink2),
                      child: Text(
                        _listenerOn ? 'Terminar después' : 'Usar solo registro manual',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyBox() {
    Widget line(String bold, String rest) => Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.45, color: MgColors.ink2),
              children: [
                TextSpan(
                  text: bold,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: MgColors.ink),
                ),
                TextSpan(text: rest),
              ],
            ),
          ),
        );

    return MgCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 17, color: MgColors.acc2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isAndroid ? 'Qué lee la app y qué no' : 'Tus datos',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (_isAndroid) ...[
            line('Lee: ',
                'las notificaciones y la pantalla de Yape, Plin y Google Wallet, solo para detectar el monto, el comercio y si el dinero entra o sale.'),
            line('No lee: ', 'tus mensajes, fotos, contactos ni otras apps.'),
          ],
          line('Dónde se guarda: ',
              'tus movimientos se quedan solo en tu ${_isAndroid ? 'teléfono' : 'iPhone'}. Si creas una cuenta, sirve solo para identificarte. Para mostrar el logo de cada comercio se consulta su sitio web (sin montos ni datos tuyos); lo apagas en Perfil.'),
        ],
      ),
    );
  }

  Widget _step(int n, String title, String hint, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        label: 'Paso $n: $title. ${done ? 'Listo' : hint}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? MgColors.up : Colors.transparent,
                border: Border.all(
                  color: done ? MgColors.up : MgColors.ink3,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                  : Text(
                      '$n',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink2,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    done ? 'Listo' : hint,
                    style: const TextStyle(fontSize: 12.5, height: 1.35, color: MgColors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
