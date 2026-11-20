import 'package:flutter/material.dart';

import '../theme/mg_colors.dart';

/// Capa de carga de MiGasto: oscurece la pantalla, bloquea los toques y muestra
/// una tarjeta con un anillo violeta y un mensaje. Se usa al iniciar sesión,
/// crear o vincular una cuenta.
///
/// Envuelve el contenido: `MgBusyOverlay(busy: _busy, message: '...', child: ...)`.
class MgBusyOverlay extends StatelessWidget {
  const MgBusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.message = 'Un momento…',
  });

  final bool busy;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Mientras carga no se puede volver atrás a medias.
      canPop: !busy,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !busy,
              child: AnimatedOpacity(
                opacity: busy ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: busy ? _Layer(message: message) : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Layer extends StatelessWidget {
  const _Layer({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(minWidth: 168, maxWidth: 260),
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          decoration: BoxDecoration(
            color: MgColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: MgColors.acc.withValues(alpha: 0.28),
                blurRadius: 36,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  color: MgColors.acc2,
                  backgroundColor: MgColors.line,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MgColors.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
