import 'package:flutter/material.dart';

import '../layout/adaptive.dart';
import '../theme/mg_colors.dart';

/// Cómo se presenta una hoja cuando el teléfono está en horizontal.
enum SheetKind {
  /// Panel pegado a la derecha, de todo el alto (listas y formularios).
  panel,

  /// Tarjeta compacta cerca de la barra inferior (menús cortos como «+»).
  menu,

  /// Diálogo pequeño centrado (confirmaciones).
  dialog,
}

/// Muestra una hoja.
///
/// - En **vertical** es la hoja inferior de siempre.
/// - En **horizontal** (teléfono girado) una hoja inferior taparía casi toda la
///   pantalla y dejaría franjas vacías a los lados, así que se presenta según
///   [kind]: panel lateral derecho, menú compacto o diálogo centrado. El panel
///   se cierra también deslizando hacia la derecha.
///
/// Acepta los mismos parámetros que `showModalBottomSheet` (los de aspecto solo
/// valen en vertical), para poder cambiar una llamada por otra sin más.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetKind kind = SheetKind.panel,
  Color? backgroundColor = Colors.transparent,
  ShapeBorder? shape,
  bool isScrollControlled = true,
  bool isDismissible = true,
  // Se aceptan por compatibilidad con showModalBottomSheet.
  // ignore: avoid_unused_constructor_parameters
  bool useRootNavigator = true,
  bool useSafeArea = false,
}) {
  if (!context.isLandscapePhone) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      builder: builder,
    );
  }

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: isDismissible,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => LandscapeSheet(kind: kind, child: builder(ctx)),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      switch (kind) {
        case SheetKind.panel:
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
            child: child,
          );
        case SheetKind.menu:
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        case SheetKind.dialog:
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
          );
      }
    },
  );
}

/// Ancho del panel lateral: casi la mitad, con topes para que no se estire.
double landscapePanelWidth(Size size) => (size.width * 0.46).clamp(340.0, 440.0);

/// El contenedor de una hoja en horizontal.
class LandscapeSheet extends StatelessWidget {
  const LandscapeSheet({super.key, required this.kind, required this.child});

  final SheetKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    // El teclado empuja el contenido en lugar de taparlo.
    Widget content(Widget c) => Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: c,
        );

    switch (kind) {
      case SheetKind.panel:
        return Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            // Deslizar hacia la derecha cierra el panel.
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 300) Navigator.of(context).maybePop();
            },
            child: SizedBox(
              width: landscapePanelWidth(size) + media.padding.right,
              height: size.height,
              child: Material(
                color: MgColors.card,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
                ),
                child: SafeArea(
                  left: false,
                  child: content(Align(alignment: Alignment.topCenter, child: child)),
                ),
              ),
            ),
          ),
        );
      case SheetKind.menu:
        return SafeArea(
          child: Align(
            alignment: const Alignment(0.55, 1),
            child: Padding(
              // Por encima de la barra de pestañas.
              padding: const EdgeInsets.only(bottom: 60),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: (size.width * 0.5).clamp(300.0, 440.0)),
                child: Material(
                  color: MgColors.card,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(22),
                  child: content(child),
                ),
              ),
            ),
          ),
        );
      case SheetKind.dialog:
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: size.height * 0.9,
              ),
              child: Material(
                color: MgColors.card,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(22),
                child: content(child),
              ),
            ),
          ),
        );
    }
  }
}
