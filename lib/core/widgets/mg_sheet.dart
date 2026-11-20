import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';

/// Hoja modal inferior base con tirador superior (`grab`), fondo `card`,
/// borde superior tenue de 1px y desenfoque de fondo.
class MgSheet extends StatelessWidget {
  const MgSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 28),
    this.maxHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxHeight;

  /// Helper estático para mostrar cualquier widget dentro de un MgSheet modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (_) => MgSheet(
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: const BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      padding: padding,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: MgColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );

    if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: content,
      );
    }

    return content;
  }
}
