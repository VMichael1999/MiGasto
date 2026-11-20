import 'package:flutter/material.dart';

import '../theme/mg_colors.dart';

/// Ayudas para el teclado en toda la app (iPhone y Android):
/// - tocar fuera de un campo de texto baja el teclado;
/// - mientras el teclado está abierto aparece un botón pequeño para ocultarlo,
///   como el que Safari muestra en algunas páginas web.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  static void hide() => FocusManager.instance.primaryFocus?.unfocus();

  static final ValueNotifier<int> _suppressed = ValueNotifier<int>(0);

  /// Una pantalla que ya trae su propio botón de ocultar apaga el flotante mientras está abierta.
  static void suppressFloatingButton(bool on) {
    final next = _suppressed.value + (on ? 1 : -1);
    _suppressed.value = next < 0 ? 0 : next;
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final visible = inset > 80;
    return Stack(
      children: [
        // «translucent»: los botones y campos siguen ganando su propio toque; solo los
        // espacios vacíos llegan hasta aquí y bajan el teclado.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: hide,
            child: child,
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _suppressed,
          builder: (context, suppressed, _) => suppressed > 0
              ? const SizedBox.shrink()
              : Positioned(
          right: 14,
          bottom: inset + 10,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              // Sin Tooltip: este widget vive por encima del Navigator y no tiene Overlay.
              child: Semantics(
                button: true,
                label: 'Ocultar teclado',
                child: Material(
                  color: MgColors.card,
                  elevation: 4,
                  shape: const CircleBorder(side: BorderSide(color: MgColors.line)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: hide,
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.keyboard_hide_outlined, size: 22, color: MgColors.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ],
    );
  }
}
