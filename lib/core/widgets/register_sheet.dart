import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';
import 'mg_sheet.dart';

/// Hoja modal inferior «Registrar» (Sección 4.5 del prompt y prototipo HTML):
/// - Gasto (Compras, servicios, etc.)
/// - Ingreso (Sueldo, ventas, etc.)
class RegisterSheet extends StatelessWidget {
  const RegisterSheet({
    super.key,
    required this.onSelectExpense,
    required this.onSelectIncome,
  });

  final VoidCallback onSelectExpense;
  final VoidCallback onSelectIncome;

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onSelectExpense,
    required VoidCallback onSelectIncome,
  }) {
    return MgSheet.show(
      context: context,
      child: RegisterSheet(
        onSelectExpense: onSelectExpense,
        onSelectIncome: onSelectIncome,
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
