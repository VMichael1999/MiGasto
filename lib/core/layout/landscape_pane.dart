import 'package:flutter/material.dart';

/// Recorta solo en vertical. El contenido puede "sangrar" hacia los lados
/// (brillos y sombras de las tarjetas) sin que se corte en una línea recta
/// justo en el borde de la zona.
class BleedClip extends StatelessWidget {
  const BleedClip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ClipRect(clipper: const _VerticalOnlyClipper(), child: child);
}

class _VerticalOnlyClipper extends CustomClipper<Rect> {
  const _VerticalOnlyClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-240, 0, size.width + 240, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// Una zona del modo horizontal: ocupa su parte del ancho, tiene scroll
/// vertical propio y no corta los brillos de las tarjetas en los lados.
class LandscapePane extends StatelessWidget {
  const LandscapePane({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.flex = 1,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: BleedClip(
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
