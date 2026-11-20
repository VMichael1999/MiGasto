import 'package:flutter/widgets.dart';

/// Regla única para decidir si la app está en modo horizontal de teléfono.
///
/// Es horizontal cuando el ancho supera al alto y el lado corto sigue siendo de
/// teléfono (< 600 dp). Así un iPad o una tablet, que también giran, no cambian
/// al diseño compacto del teléfono.
bool isLandscapePhoneSize(Size size) =>
    size.width > size.height && size.shortestSide < 600;

extension AdaptiveContext on BuildContext {
  /// `true` con el teléfono girado (modo horizontal).
  bool get isLandscapePhone => isLandscapePhoneSize(MediaQuery.sizeOf(this));

  /// Espacio al final de una pantalla para que la barra flotante no tape el
  /// último elemento. En horizontal la barra es más baja.
  double tabBarClearance(double portrait, {double landscape = 74}) =>
      isLandscapePhone ? landscape : portrait;
}

/// Ancho máximo de la barra flotante en horizontal: centrada y sin estirarse
/// a todo el ancho del teléfono.
const double landscapeTabBarMaxWidth = 470;
