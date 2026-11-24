import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/brand_mark.dart';
import '../providers.dart';
import 'setup_step.dart';

/// Guía para crear la automatización de Wallet (en inglés "Transaction") en Atajos.
///
/// La app no puede crearla sola: la pantalla guía los pasos y marca los que ya
/// se cumplen. Cuando llega el primer pago registrado por Wallet, la
/// automatización queda comprobada.
class ApplePaySetupScreen extends ConsumerStatefulWidget {
  const ApplePaySetupScreen({super.key, this.fromOnboarding = false});

  /// Si viene del primer inicio, "Lo hago después" entra a la app.
  final bool fromOnboarding;

  @override
  ConsumerState<ApplePaySetupScreen> createState() => _ApplePaySetupScreenState();
}

class _ApplePaySetupScreenState extends ConsumerState<ApplePaySetupScreen> {
  bool _notificationsAsked = false;

  Future<void> _openShortcuts() async {
    final permissions = ref.read(permissionsCheckerProvider);
    if (!_notificationsAsked) {
      _notificationsAsked = true;
      // Para avisarte qué se guardó después de cada pago.
      await permissions.requestNotificationPermission();
    }
    await permissions.openShortcuts();
  }

  Future<void> _later() async {
    if (widget.fromOnboarding) {
      await ref.read(sharedPreferencesProvider).setBool('onboarding_complete', true);
      if (mounted) context.go('/login');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = ref
        .watch(expensesStateProvider)
        .where((m) => m.canal == CanalMovimiento.wallet)
        .firstOrNull;
    final verified = last != null;

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
                    if (!widget.fromOnboarding)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Tooltip(
                          message: 'Volver',
                          child: Material(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.field),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.field),
                              onTap: () => context.pop(),
                              child: SizedBox(
                                width: AppSizes.iconButton,
                                height: AppSizes.iconButton,
                                child: Center(
                                    child: AppIcon(AppIcons.back, color: scheme.onSurface)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const BrandMark(),
                    const SizedBox(height: 16),
                    Text(
                      'Registra solo lo que pagas con Apple Pay.',
                      style: theme.textTheme.headlineMedium!.copyWith(fontSize: 26, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada vez que acerques el iPhone al POS, MiGasto anota el monto y el comercio, y te avisa para que lo confirmes (en Ajustes puedes guardarlos solos).',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontSize: 14.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    // Video de 42 s dentro de la app: explica la automatización paso a paso.
                    OutlinedButton.icon(
                      onPressed: () => context.push('/setup/apple-pay/tutorial'),
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                      label: const Text('Ver tutorial en video'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SetupStep(number: 1, title: 'MiGasto ya agregó la acción a Atajos',
                        hint: 'Se llama "Registrar pago de Wallet"', done: true),
                    const SizedBox(height: 14),
                    SetupStep(number: 2, title: 'Crea la automatización de Wallet',
                        hint: 'En Atajos, Automatización, +, elige "Wallet" (al realizar un pago sin contacto). Agrega la acción "Registrar pago de Wallet" de MiGasto y, en el campo Pago, elige "Entrada de atajo"',
                        done: verified),
                    const SizedBox(height: 14),
                    SetupStep(number: 3, title: 'Actívala sin confirmación',
                        hint: 'Deja "Automatización" activada y "Notificar" apagado. Así se registra aunque no abras la app',
                        done: verified),
                    const SizedBox(height: 14),
                    SetupStep(number: 4, title: 'Opcional: guarda dónde pagaste',
                        hint: 'En el atajo, antes de "Registrar pago de Wallet" agrega "Obtener ubicación actual" y ponla en el campo Ubicación. Así el pago aparece en el mapa de "Dónde gasto"',
                        done: last?.tieneUbicacion ?? false),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon(AppIcons.info,
                              size: AppIconSize.small, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: verified
                                        ? 'Último pago registrado: ${DateFormat("d MMM, HH:mm", 'es').format(last.date)}. Si fue una prueba con el atajo, paga una vez con Apple Pay para confirmar que corre solo. '
                                        : 'Cuando llegue tu primer pago registrado, marcaremos los pasos. ',
                                  ),
                                  const TextSpan(
                                      text: 'Solo funciona al pagar acercando el iPhone. '),
                                  const TextSpan(
                                      text: 'Yape y Plin: ',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  const TextSpan(
                                      text: 'abre la captura de la constancia, toca Compartir y elige MiGasto.'),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  if (verified) ...[
                    // Ya llegó un pago: se puede seguir. Atajos queda a un toque por si hay que ajustar.
                    FilledButton(
                      onPressed: _later,
                      child: Text(widget.fromOnboarding ? 'Continuar' : 'Listo'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(onPressed: _openShortcuts, child: const Text('Abrir Atajos')),
                  ] else ...[
                    FilledButton(onPressed: _openShortcuts, child: const Text('Abrir Atajos')),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _later,
                      child: Text(widget.fromOnboarding ? 'Lo hago después' : 'Cerrar'),
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
}
