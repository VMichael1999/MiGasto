import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Tarjeta base del diseño MiGasto:
/// Radio 20 (o 24 para balance), fondo `card` (#15151B), borde tenue de 1px
/// (`Colors.white.withOpacity(0.06)`), y padding por defecto de 15px.
class MgCard extends StatelessWidget {
  const MgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.margin,
    this.radius = AppRadius.card,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: MgColors.borderTenue,
          width: 1,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? MgColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          splashColor: MgColors.card2.withValues(alpha: 0.5),
          highlightColor: MgColors.card2.withValues(alpha: 0.3),
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: content);
    }
    return content;
  }
}
