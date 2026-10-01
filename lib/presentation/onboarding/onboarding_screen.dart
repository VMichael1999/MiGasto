import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/app_icons.dart';
import '../providers.dart';

/// Primera pantalla: aviso de privacidad y permisos.
///
/// En Android explica, antes de pedir nada, qué lee la app y qué no (el aviso
/// destacado que exige Google Play) y deja usar la app solo con registro manual.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  bool _accessibilityOn = false;
  bool _overlayOn = false;
  bool _batteryOn = false;

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
    if (!_isAndroid) return;
    final permissions = ref.read(permissionsCheckerProvider);
    final accessibility = await permissions.isNotificationListenerEnabled();
    final overlay = await permissions.isOverlayGranted();
    final battery = await permissions.isBatteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _batteryOn = battery;
      _accessibilityOn = accessibility;
      _overlayOn = overlay;
    });
  }

  Future<void> _finish() async {
    await ref.read(sharedPreferencesProvider).setBool('onboarding_complete', true);
    if (mounted) context.go('/dashboard');
  }

  Future<void> _primary() async {
    final permissions = ref.read(permissionsCheckerProvider);
    if (!_isAndroid) {
      // iPhone: la guía de Apple Pay es el siguiente paso.
      if (mounted) context.go('/setup/apple-pay?onboarding=1');
      return;
    }
    if (!_accessibilityOn) {
      await permissions.openNotificationListenerSettings();
    } else if (!_overlayOn) {
      await permissions.requestOverlayPermission();
    } else if (!_batteryOn) {
      await permissions.openBatterySettings();
    } else {
      await _finish();
    }
  }

  String get _primaryLabel {
    if (!_isAndroid) return 'Continuar';
    if (!_accessibilityOn) return 'Aceptar y activar la lectura';
    if (!_overlayOn) return 'Permitir la ventana flotante';
    if (!_batteryOn) return 'Quitar la restricción de batería';
    return 'Empezar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'm/',
                        semanticsLabel: 'MiGasto',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAndroid
                          ? 'Registra tus pagos sin escribirlos.'
                          : 'Registra lo que gastas y lo que recibes.',
                      style: theme.textTheme.headlineMedium!.copyWith(
                        fontSize: 26,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAndroid
                          ? 'MiGasto anota los pagos de Yape, Plin y Google Wallet por ti y te deja confirmar cada uno.'
                          : 'Anota tus gastos e ingresos en segundos y mira cuánto te queda del mes.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: 14.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _privacyBox(context),
                    if (_isAndroid) ...[
                      const SizedBox(height: 20),
                      _step(context, 1, 'Activa la lectura de pagos',
                          'En Acceso a notificaciones, activa MiGasto', _accessibilityOn),
                      const SizedBox(height: 14),
                      _step(context, 2, 'Permite la ventana flotante',
                          'Para confirmar cada pago al instante. Es opcional.', _overlayOn),
                      const SizedBox(height: 14),
                      _step(context, 3, 'Evita que el teléfono la duerma',
                          'En Batería, elige «No restringido». Así no se pierden pagos.', _batteryOn),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(onPressed: _primary, child: Text(_primaryLabel)),
                  if (_isAndroid) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        _accessibilityOn ? 'Terminar después' : 'Usar solo registro manual',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyBox(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget line(String bold, String rest) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13),
              children: [
                TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: rest),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.info, size: AppIconSize.small, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                _isAndroid ? 'Qué lee la app y qué no' : 'Tus datos',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          if (_isAndroid) ...[
            line('Lee: ',
                'las notificaciones y la pantalla de Yape, Plin y Google Wallet, solo para detectar el monto, el comercio y si el dinero entra o sale.'),
            line('No lee: ', 'tus mensajes, fotos, contactos ni otras apps.'),
          ],
          line('Dónde se guarda: ',
              'solo en tu ${_isAndroid ? 'teléfono' : 'iPhone'}. No se envía a ningún servidor.'),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int n, String title, String hint, bool done) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'Paso $n: $title. ${done ? 'Listo' : hint}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? scheme.primary : scheme.outline,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: done
                ? AppIcon(AppIcons.check, size: AppIconSize.small, color: scheme.onPrimary)
                : Text('$n',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall!.copyWith(fontSize: 14)),
                Text(done ? 'Listo' : hint,
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
