import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/widgets/app_icons.dart';
import '../providers.dart';

/// Guía para crear la automatización "Transacción" de Wallet en Atajos.
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
      if (mounted) context.go('/dashboard');
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text('m/',
                          semanticsLabel: 'MiGasto',
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.9,
                            color: scheme.onPrimary,
                          )),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registra solo lo que pagas con Apple Pay.',
                      style: theme.textTheme.headlineMedium!.copyWith(fontSize: 26, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada vez que acerques el iPhone al POS, MiGasto guarda el monto y el comercio, y te avisa qué guardó.',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontSize: 14.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _step(context, 1, 'MiGasto ya agregó la acción a Atajos',
                        'Se llama "Registrar movimiento"', true),
                    const SizedBox(height: 14),
                    _step(context, 2, 'Crea la automatización "Transacción"',
                        'En Atajos, Automatización, Transacción: elige tus tarjetas de Wallet y la acción de MiGasto, y pásale el monto, el comercio y la tarjeta',
                        verified),
                    const SizedBox(height: 14),
                    _step(context, 3, 'Actívala sin confirmación',
                        'Así se registra aunque no abras la app', verified),
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
                                        ? 'Último pago registrado: ${DateFormat("d MMM, HH:mm", 'es').format(last.date)}. '
                                        : 'Cuando llegue tu primer pago registrado, marcaremos los pasos. ',
                                  ),
                                  const TextSpan(
                                      text: 'Solo funciona al pagar acercando el iPhone. '),
                                  const TextSpan(
                                      text: 'Yape y Plin: ',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  const TextSpan(
                                      text: 'registra el pago con el botón + de MiGasto.'),
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
                  FilledButton(onPressed: _openShortcuts, child: const Text('Abrir Atajos')),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _later,
                    child: Text(widget.fromOnboarding ? 'Lo hago después' : 'Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              border: Border.all(color: done ? scheme.primary : scheme.outline, width: 1.5),
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
