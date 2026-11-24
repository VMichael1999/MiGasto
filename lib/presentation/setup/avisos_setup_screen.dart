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

/// Guía (iPhone) para registrar lo que pagas con Yape, Plin y tu banco.
///
/// iPhone no deja leer las notificaciones de otras apps, así que el texto llega por
/// Atajos a la acción «Registrar aviso de pago»: desde un correo, un SMS o la pantalla
/// de la constancia. La app no puede crear las automatizaciones: la guía explica cómo.
class AvisosSetupScreen extends ConsumerStatefulWidget {
  const AvisosSetupScreen({super.key});

  @override
  ConsumerState<AvisosSetupScreen> createState() => _AvisosSetupScreenState();
}

class _AvisosSetupScreenState extends ConsumerState<AvisosSetupScreen> {
  bool _notificationsAsked = false;

  Future<void> _openShortcuts() async {
    final permissions = ref.read(permissionsCheckerProvider);
    if (!_notificationsAsked) {
      _notificationsAsked = true;
      // Para avisarte qué se guardó después de cada aviso.
      await permissions.requestNotificationPermission();
    }
    await permissions.openShortcuts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // En iPhone solo «Registrar aviso de pago» deja movimientos con canal de notificación.
    final last = ref
        .watch(expensesStateProvider)
        .where((m) => m.canal == CanalMovimiento.notificacion)
        .firstOrNull;

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
                              child: Center(child: AppIcon(AppIcons.back, color: scheme.onSurface)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const BrandMark(),
                    const SizedBox(height: 16),
                    Text(
                      'Registra lo que pagas con Yape, Plin y tu banco.',
                      style: theme.textTheme.headlineMedium!.copyWith(fontSize: 26, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'iPhone no deja que otras apps lean tus notificaciones. Con Atajos, MiGasto lee el correo o el SMS de tu banco, o la constancia que tienes en pantalla.',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontSize: 14.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    const SetupStep(
                      number: 1,
                      title: 'MiGasto ya agregó la acción a Atajos',
                      hint: 'Se llama "Registrar aviso de pago"',
                      done: true,
                    ),
                    const SizedBox(height: 14),
                    const SetupStep(
                      number: 2,
                      title: 'Correos del banco: se registran solos',
                      hint: 'En Atajos, Automatización, +, elige "Correo". En Remitente pon el correo de tu banco (el BCP usa notificaciones@notificacionesbcp.com.pe). Agrega "Registrar aviso de pago" de MiGasto, en Texto elige "Entrada de atajo" y marca "Ejecutar de inmediato". Ese correo tiene que estar en la app Mail',
                      done: false,
                    ),
                    const SizedBox(height: 14),
                    const SetupStep(
                      number: 3,
                      title: 'SMS del banco: también solos',
                      hint: 'Automatización, +, "Mensaje". En Remitente pon el número de tu banco (el BCP usa el 19896) y agrega la misma acción con "Entrada de atajo" y "Ejecutar de inmediato"',
                      done: false,
                    ),
                    const SizedBox(height: 14),
                    const SetupStep(
                      number: 4,
                      title: 'Constancias en pantalla: dos toques atrás',
                      hint: 'Crea un atajo con "Tomar captura de pantalla", "Extraer texto de la imagen" y "Registrar aviso de pago" (en Texto, "Texto extraído"; activa "Avisar si no es un pago"). Luego, en Ajustes, Accesibilidad, Tocar, Tocar atrás, elige ese atajo. Con la constancia de Yape, Plin o tu banco en pantalla, toca dos veces la parte de atrás del iPhone',
                      done: false,
                    ),
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
                          AppIcon(AppIcons.info, size: AppIconSize.small, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: last != null
                                        ? 'Último aviso registrado: ${DateFormat("d MMM, HH:mm", 'es').format(last.date)}. '
                                        : 'Cuando llegue tu primer aviso, lo verás en Inicio. ',
                                  ),
                                  const TextSpan(text: 'Cada pago queda «Por confirmar» hasta que lo revises (en Ajustes puedes guardarlos solos). '),
                                  const TextSpan(text: 'Yape: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const TextSpan(
                                      text: 'te manda un correo al pagar un servicio, y en sus Ajustes puedes pedir un correo por cada yapeo que envías.'),
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
                  TextButton(onPressed: () => context.pop(), child: const Text('Cerrar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
