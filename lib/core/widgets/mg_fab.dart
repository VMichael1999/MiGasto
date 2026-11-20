import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/mg_colors.dart';

/// Botón redondo flotante de registrar:
/// 56×56, fondo violeta `#7C5CFF`, sombra con resplandor violeta y respuesta táctil.
class MgFab extends StatefulWidget {
  const MgFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<MgFab> createState() => _MgFabState();
}

class _MgFabState extends State<MgFab> with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0.90,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scale.reverse();
  void _onTapUp(TapUpDetails _) {
    _scale.forward();
    HapticFeedback.lightImpact();
    widget.onPressed();
  }
  void _onTapCancel() => _scale.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MgColors.acc,
            boxShadow: [
              BoxShadow(
                color: MgColors.acc.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
