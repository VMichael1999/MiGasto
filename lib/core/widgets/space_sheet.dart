import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

class SpaceItem {
  const SpaceItem({
    required this.id,
    required this.name,
    required this.description,
    this.icon = Icons.folder_outlined,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}

/// Hoja modal para alternar entre espacios de gasto (Personal, Trabajo, etc.).
class SpaceSheet extends StatelessWidget {
  const SpaceSheet({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.spaces = defaultSpaces,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;
  final List<SpaceItem> spaces;

  static const List<SpaceItem> defaultSpaces = [
    SpaceItem(
      id: 'personal',
      name: 'Personal',
      description: 'Gastos de tu día a día',
      icon: Icons.person_outline,
    ),
    SpaceItem(
      id: 'trabajo',
      name: 'Trabajo / Negocio',
      description: 'Facturas, suministros y proyectos',
      icon: Icons.work_outline,
    ),
    SpaceItem(
      id: 'compartido',
      name: 'Compartido / Hogar',
      description: 'Gastos divididos del departamento',
      icon: Icons.home_outlined,
    ),
  ];

  static Future<String?> show(
    BuildContext context, {
    required String selectedId,
    List<SpaceItem> spaces = defaultSpaces,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpaceSheet(
        selectedId: selectedId,
        spaces: spaces,
        onSelected: (id) => Navigator.pop(context, id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: MgColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tus espacios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Separa tus gastos personales de tu negocio o del hogar.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MgColors.ink2,
              ),
            ),
            const SizedBox(height: 14),
            for (final space in spaces) ...[
              _buildTile(space),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTile(SpaceItem space) {
    final isSelected = space.id == selectedId;

    return Material(
      color: isSelected ? MgColors.accSoft : MgColors.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onSelected(space.id),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? MgColors.acc : Colors.transparent,
              width: 1.4,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? MgColors.acc.withValues(alpha: 0.2) : MgColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  space.icon,
                  size: 20,
                  color: isSelected ? MgColors.acc2 : MgColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? MgColors.acc2 : MgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      space.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MgColors.acc,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'En uso',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
