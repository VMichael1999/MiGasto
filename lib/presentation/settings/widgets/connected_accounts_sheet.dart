import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mg_colors.dart';
import '../../../core/widgets/mg_sheet.dart';
import '../../providers.dart';

/// Qué pagos detecta la app. Las claves son las que manda el código nativo
/// (`yape`, `plin`, `googlePay`) y el interruptor se guarda en el dispositivo:
/// un pago de un medio apagado se ignora.
class ConnectedAccountsSheet extends ConsumerWidget {
  const ConnectedAccountsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return MgSheet.show<void>(
      context: context,
      child: const ConnectedAccountsSheet(),
    );
  }

  static const _labels = {
    'yape': ('Yape', 'Notificaciones de Yape'),
    'plin': ('Plin', 'Notificaciones de Plin'),
    'googlePay': ('Google Wallet', 'Pagos con tarjeta desde Google Wallet'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersEnabledProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const Text(
          'Pagos detectados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MgColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Elige de qué medios MiGasto anota los pagos. La app no guarda claves ni números completos.',
          style: TextStyle(fontSize: 12.5, height: 1.35, color: MgColors.ink2),
        ),
        const SizedBox(height: 14),
        for (final entry in providers.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: MgColors.acc,
            title: Text(
              _labels[entry.key]?.$1 ?? entry.key,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: MgColors.ink,
              ),
            ),
            subtitle: Text(
              _labels[entry.key]?.$2 ?? '',
              style: const TextStyle(fontSize: 12, color: MgColors.ink2),
            ),
            value: entry.value,
            onChanged: (_) =>
                ref.read(providersEnabledProvider.notifier).toggleProvider(entry.key),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
