import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Hoja modal de confirmación para acciones destructivas
/// (eliminar movimiento, eliminar límite, cerrar sesión).
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Eliminar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = true,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  /// Muestra la hoja modal y devuelve `true` si el usuario confirmó.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = true,
    IconData? icon,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon ?? (isDestructive ? Icons.delete_outline : Icons.info_outline),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(
          top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de agarre
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: MgColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDestructive ? MgColors.down.withValues(alpha: 0.12) : MgColors.accSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isDestructive ? MgColors.down : MgColors.acc2,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: MgColors.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppSizes.primaryButton,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: MgColors.soft,
                        foregroundColor: MgColors.ink,
                        side: const BorderSide(color: MgColors.line, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: AppSizes.primaryButton,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDestructive ? MgColors.down : MgColors.acc,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
