import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';
import 'mg_sheet.dart';
import 'mg_toast.dart';

/// Hoja modal inferior «Registrar» (Sección 4.5 del prompt y prototipo HTML):
/// - Gasto (Compras, servicios, etc.)
/// - Ingreso (Sueldo, ventas, etc.)
/// - Transferir entre espacios (De Principal a Ahorros)
/// - Botón degradado «Registro inteligente» (dictar «almorcé 25 soles»)
class RegisterSheet extends StatelessWidget {
  const RegisterSheet({
    super.key,
    required this.onSelectExpense,
    required this.onSelectIncome,
    required this.onSelectTransfer,
    this.onSmartRegister,
  });

  final VoidCallback onSelectExpense;
  final VoidCallback onSelectIncome;
  final VoidCallback onSelectTransfer;
  final VoidCallback? onSmartRegister;

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onSelectExpense,
    required VoidCallback onSelectIncome,
    required VoidCallback onSelectTransfer,
    VoidCallback? onSmartRegister,
  }) {
    return MgSheet.show(
      context: context,
      child: RegisterSheet(
        onSelectExpense: onSelectExpense,
        onSelectIncome: onSelectIncome,
        onSelectTransfer: onSelectTransfer,
        onSmartRegister: onSmartRegister,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegisterOption(
          icon: Icons.arrow_downward_rounded,
          iconColor: MgColors.down,
          iconBg: MgColors.down.withValues(alpha: 0.15),
          title: 'Gasto',
          subtitle: 'Compras, servicios, etc.',
          onTap: () {
            Navigator.of(context).pop();
            onSelectExpense();
          },
        ),
        const SizedBox(height: 4),
        _RegisterOption(
          icon: Icons.arrow_upward_rounded,
          iconColor: MgColors.up,
          iconBg: MgColors.up.withValues(alpha: 0.15),
          title: 'Ingreso',
          subtitle: 'Sueldo, ventas, etc.',
          onTap: () {
            Navigator.of(context).pop();
            onSelectIncome();
          },
        ),
        const SizedBox(height: 4),
        _RegisterOption(
          icon: Icons.swap_horiz_rounded,
          iconColor: MgColors.acc2,
          iconBg: MgColors.accSoft,
          title: 'Transferir entre espacios',
          subtitle: 'De Principal a Ahorros',
          onTap: () {
            Navigator.of(context).pop();
            onSelectTransfer();
          },
        ),
        const SizedBox(height: 12),
        // Botón degradado «Registro inteligente»
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pop();
              if (onSmartRegister != null) {
                onSmartRegister!();
              } else {
                MgToast.show(
                  context,
                  message: 'Dictas «almorcé 25 soles» y lo registra solo.',
                );
              }
            },
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [MgColors.acc2, MgColors.acc],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MgColors.acc.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Registro inteligente',
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterOption extends StatelessWidget {
  const _RegisterOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: MgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 11.5,
                        color: MgColors.ink2,
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
  }
}
