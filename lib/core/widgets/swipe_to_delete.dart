import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import 'confirm_sheet.dart';

/// Envuelve cualquier fila para permitir eliminación por deslizamiento hacia la izquierda.
/// Muestra fondo rojo con ícono de papelera, pide confirmación con ConfirmSheet y dispara onDelete.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onDelete,
    this.confirmTitle = '¿Eliminar movimiento?',
    this.confirmMessage = 'Esta acción no se puede deshacer.',
    this.confirmLabel = 'Eliminar',
    this.askConfirmation = true,
  });

  final Key itemKey;
  final Widget child;
  final VoidCallback onDelete;
  final String confirmTitle;
  final String confirmMessage;
  final String confirmLabel;
  final bool askConfirmation;

  Future<bool> _ask(BuildContext context) async {
    if (!askConfirmation) return true;
    return await ConfirmSheet.show(
      context,
      title: confirmTitle,
      message: confirmMessage,
      confirmLabel: confirmLabel,
      isDestructive: true,
      icon: Icons.delete_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart, // Solo hacia la izquierda
      dismissThresholds: const {DismissDirection.endToStart: 0.42},
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        color: MgColors.down,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (_) => _ask(context),
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}
