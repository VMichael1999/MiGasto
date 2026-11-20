import 'package:flutter/material.dart';

import '../../core/theme/mg_colors.dart';
import '../expenses/movement_detail_screen.dart';

/// Detalle de un movimiento como panel que entra deslizando desde la derecha y
/// cubre solo las columnas de la derecha (la de Inicio queda a la vista).
///
/// Se cierra con el botón de atrás del detalle o deslizando hacia la derecha.
/// Mientras está cerrado no construye el detalle.
class MovementDetailPanel extends StatefulWidget {
  const MovementDetailPanel({
    super.key,
    required this.movementId,
    required this.open,
    required this.onClose,
  });

  /// Último movimiento abierto (se conserva mientras el panel se cierra).
  final String? movementId;
  final bool open;
  final VoidCallback onClose;

  @override
  State<MovementDetailPanel> createState() => _MovementDetailPanelState();
}

class _MovementDetailPanelState extends State<MovementDetailPanel> {
  // Se construye el detalle solo mientras el panel está abierto o animándose.
  late bool _built = widget.open;

  @override
  void didUpdateWidget(covariant MovementDetailPanel old) {
    super.didUpdateWidget(old);
    if (widget.open && !_built) _built = true;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.movementId;
    return IgnorePointer(
      ignoring: !widget.open,
      child: AnimatedSlide(
        offset: widget.open ? Offset.zero : const Offset(1.03, 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        onEnd: () {
          if (!widget.open && _built) setState(() => _built = false);
        },
        child: GestureDetector(
          // Deslizar hacia la derecha vuelve a Inicio.
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) widget.onClose();
          },
          child: Material(
            color: MgColors.bg,
            elevation: 12,
            shadowColor: Colors.black,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            ),
            child: _built && id != null
                ? MediaQuery.removePadding(
                    context: context,
                    // El panel no está en el borde izquierdo: sin el hueco del notch.
                    removeLeft: true,
                    // Espacio para la barra de pestañas flotante, que queda encima.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: MovementDetailScreen(id: id, onClose: widget.onClose),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
