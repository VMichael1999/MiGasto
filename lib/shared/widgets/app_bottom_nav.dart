import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme.dart';
import 'app_icons.dart';

/// Barra inferior del rediseño: 4 destinos con nombre y botón "+" central.
/// Grilla `1fr 1fr 64px 1fr 1fr`, igual que la propuesta v0.2.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdd,
  });

  /// 0 Resumen, 1 Movimientos, 2 (botón agregar, no seleccionable), 3 Reportes, 4 Ajustes.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 16),
            child: Row(
              children: [
                _item(0, AppIcons.home, 'Resumen'),
                _item(1, AppIcons.list, 'Movimientos'),
                SizedBox(
                  width: 64,
                  child: Center(child: _AddButton(onPressed: onAdd)),
                ),
                _item(3, AppIcons.chart, 'Reportes'),
                _item(4, AppIcons.gear, 'Ajustes'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, AppIcons icon, String label) {
    return Expanded(
      child: _NavItem(
        icon: icon,
        label: label,
        selected: selectedIndex == index,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon,
                color: selected ? colors.brandInk : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Tooltip(
        message: 'Agregar movimiento',
        child: Semantics(
          button: true,
          label: 'Agregar movimiento',
          excludeSemantics: true,
          child: Material(
            color: AppTheme.neonGreen,
            borderRadius: BorderRadius.circular(AppRadius.fab),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.fab),
              child: const SizedBox(
                width: AppSizes.fab,
                height: AppSizes.fab,
                child: Center(
                  child: AppIcon(
                    AppIcons.plus,
                    size: AppIconSize.large,
                    color: AppTheme.darkBg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
