import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/mg_colors.dart';

enum MgMenuAction {
  edit,
  compare,
  delete,
}

/// Menú contextual activado por toque prolongado anclado a la posición del dedo:
/// Editar · Comparar · Eliminar.
/// Emite `HapticFeedback.selectionClick()` al activarse.
class LongPressMenu extends StatelessWidget {
  const LongPressMenu({
    super.key,
    required this.child,
    required this.onAction,
    this.enabled = true,
  });

  final Widget child;
  final ValueChanged<MgMenuAction> onAction;
  final bool enabled;

  void _showMenu(BuildContext context, Offset globalPosition) async {
    if (!enabled) return;
    HapticFeedback.selectionClick();

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<MgMenuAction>(
      context: context,
      position: position,
      color: const Color(0xF2202028),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
      ),
      items: [
        _buildItem(
          action: MgMenuAction.edit,
          label: 'Editar',
          icon: Icons.edit_outlined,
        ),
        _buildItem(
          action: MgMenuAction.compare,
          label: 'Comparar',
          icon: Icons.swap_horiz,
        ),
        _buildItem(
          action: MgMenuAction.delete,
          label: 'Eliminar',
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
      ],
    );

    if (selected != null) {
      onAction(selected);
    }
  }

  PopupMenuEntry<MgMenuAction> _buildItem({
    required MgMenuAction action,
    required String label,
    required IconData icon,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? MgColors.down : MgColors.ink;
    return PopupMenuItem<MgMenuAction>(
      value: action,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Icon(
            icon,
            size: 18,
            color: isDestructive ? MgColors.down : MgColors.ink2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) => _showMenu(context, details.globalPosition),
      child: child,
    );
  }
}
