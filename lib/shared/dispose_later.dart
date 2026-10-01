import 'package:flutter/widgets.dart';

/// Libera campos de texto un momento después de cerrar un diálogo u hoja: mientras
/// se anima el cierre el campo todavía se dibuja, y liberarlo antes da error.
void disposeControllersLater(Iterable<TextEditingController> controllers) {
  Future<void>.delayed(const Duration(milliseconds: 500), () {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
