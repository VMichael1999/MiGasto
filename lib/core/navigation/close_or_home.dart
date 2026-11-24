import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Cierra la pantalla; si se abrió directo desde un widget (no hay a dónde volver), va a Inicio.
void closeOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/dashboard');
  }
}
