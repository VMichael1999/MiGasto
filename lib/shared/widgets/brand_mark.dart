import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// El logo de MiGasto (la boleta con el signo de sol) como en el icono de la app.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MiGasto',
      image: true,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: SvgPicture.asset('assets/brand/icon.svg', width: size, height: size),
      ),
    );
  }
}
