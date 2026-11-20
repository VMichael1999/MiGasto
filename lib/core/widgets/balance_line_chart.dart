import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mg_colors.dart';

/// Línea del saldo: lo ocurrido (trazo continuo con relleno) y la estimación
/// (trazo punteado). Se dibuja sin ejes, como un resumen.
class BalanceLineChart extends StatelessWidget {
  const BalanceLineChart({
    super.key,
    required this.history,
    required this.projected,
    this.height = 56,
    this.color = MgColors.acc2,
  });

  /// Saldo de cierre de los últimos días; el último es hoy.
  final List<double> history;

  /// Estimación; el primer punto coincide con el saldo de hoy.
  final List<double> projected;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(history: history, projected: projected, color: color),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.history, required this.projected, required this.color});

  final List<double> history;
  final List<double> projected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final all = [...history, ...projected.skip(1)];
    final minV = all.reduce(math.min);
    final maxV = all.reduce(math.max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    const pad = 4.0;
    final h = size.height - pad * 2;
    final dx = size.width / (all.length - 1);
    Offset pt(int i, double v) => Offset(i * dx, pad + h - ((v - minV) / range) * h);

    // Relleno bajo lo ocurrido.
    final hist = Path()..moveTo(0, pt(0, history.first).dy);
    for (var i = 1; i < history.length; i++) {
      final o = pt(i, history[i]);
      hist.lineTo(o.dx, o.dy);
    }
    final last = pt(history.length - 1, history.last);
    final fill = Path.from(hist)
      ..lineTo(last.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      hist,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Estimación punteada.
    if (projected.length > 1) {
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      var prev = last;
      for (var i = 1; i < projected.length; i++) {
        final next = pt(history.length - 1 + i, projected[i]);
        if (i.isOdd) canvas.drawLine(prev, next, dashPaint);
        prev = next;
      }
    }

    // Hoy.
    canvas.drawCircle(last, 3.2, Paint()..color = color);
    canvas.drawCircle(last, 1.4, Paint()..color = MgColors.card);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.history != history || old.projected != projected || old.color != color;
}
