import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/mg_colors.dart';

class MgTabItem {
  const MgTabItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Barra de navegación flotante con `GlassTabBar.bottom` de `liquid_glass_widgets`.
/// Incluye la física de lente líquida, efecto gota de agua al presionar (`indicatorPinchStrength: 1.0`),
/// deformación elástica al toque (`pressScale: 1.08`), resplandor direccional y refracción óptica.
/// Y cuenta con el botón circular de acción rápida a la derecha (`extraButton`) con el `+`.
class MgTabBar extends StatelessWidget {
  const MgTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.onAddTap,
    this.compact = false,
  });

  /// Versión baja para el teléfono en horizontal, donde sobra ancho y falta alto.
  final bool compact;

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddTap;

  static const List<GlassTab> defaultTabs = [
    GlassTab(
      icon: Icon(Icons.home_rounded, size: 20),
      label: 'Inicio',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.track_changes_rounded, size: 20),
      label: 'Plan',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.auto_awesome_rounded, size: 20),
      label: 'MiGastoIA',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.bar_chart_rounded, size: 20),
      label: 'Stats',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.search_rounded, size: 20),
      label: 'Buscar',
      glowColor: Color(0xFF7C5CFF),
    ),
  ];

  /// Mismas pestañas con íconos más chicos para el horizontal.
  static const List<GlassTab> compactTabs = [
    GlassTab(
      icon: Icon(Icons.home_rounded, size: 15),
      label: 'Inicio',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.track_changes_rounded, size: 15),
      label: 'Plan',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.auto_awesome_rounded, size: 15),
      label: 'MiGastoIA',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.bar_chart_rounded, size: 15),
      label: 'Stats',
      glowColor: Color(0xFF7C5CFF),
    ),
    GlassTab(
      icon: Icon(Icons.search_rounded, size: 15),
      label: 'Buscar',
      glowColor: Color(0xFF7C5CFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.bottom(
      tabs: compact ? compactTabs : defaultTabs,
      selectedIndex: selectedIndex,
      onTabSelected: (index) {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      // Botón circular satélite con el '+' tipo gota de vidrio líquida (como la luna de la referencia)
      extraButton: GlassTabBarExtraButton(
        icon: Icon(
          Icons.add_rounded,
          size: compact ? 20 : 26,
          color: Colors.white,
        ),
        iconColor: Colors.white,
        label: 'Nuevo movimiento',
        size: compact ? 36 : 58,
        onTap: () {
          HapticFeedback.mediumImpact();
          onAddTap?.call();
        },
      ),
      spacing: compact ? 6 : 10,
      horizontalPadding: compact ? 10 : 16,
      verticalPadding: compact ? 6 : 16,
      barHeight: compact ? 36 : 62,
      barBorderRadius: compact ? 18 : 24,
      // tabWidth: null hace que las pestañas se distribuyan en todo el espacio disponible
      tabWidth: null,
      iconLabelSpacing: compact ? 0 : 3,
      labelFontSize: compact ? 8 : 9.5,
      selectedIconColor: MgColors.acc2,
      unselectedIconColor: MgColors.ink3,
      selectedLabelColor: MgColors.acc2,
      unselectedLabelColor: MgColors.ink3,
      selectedLabelStyle: TextStyle(
        fontSize: compact ? 8 : 9.5,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: compact ? 8 : 9.5,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
      indicatorColor: MgColors.accSoft,
      indicatorBorderRadius: compact ? 14 : 18,
      indicatorExpansion: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      // Física de lente líquida y gota de agua
      indicatorPinchStrength: 1.0,
      pressScale: 1.08,
      interactionBehavior: GlassInteractionBehavior.full,
      interactionGlowColor: MgColors.acc,
      enableBlend: true,
      groupBackdrop: true,
      settings: const LiquidGlassSettings(
        thickness: 28,
        blur: 20,
        glassColor: Color(0xEB16161C),
        chromaticAberration: 0.03,
        lightIntensity: 0.7,
        fresnelStrength: 1.0,
        refractiveIndex: 1.25,
      ),
      indicatorSettings: const LiquidGlassSettings(
        thickness: 24,
        blur: 14,
        glassColor: MgColors.accSoft,
        refractiveIndex: 1.2,
      ),
    );
  }
}
