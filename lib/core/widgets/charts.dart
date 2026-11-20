import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../theme/mg_colors.dart';

class DonutSegment {
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Gráfico de dona (DonutChart) de alta fidelidad, con extremos redondeados,
/// separación limpia entre categorías y animación suave.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.total,
    this.size = 200,
    this.strokeWidth = 22,
    this.centerTitle = 'Total',
    this.centerWidget,
  });

  final List<DonutSegment> segments;
  final double? total;
  final double size;
  final double strokeWidth;
  final String centerTitle;
  final Widget? centerWidget;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _anim.forward();
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sum = widget.total ??
        widget.segments.fold<double>(0.0, (double acc, DonutSegment s) => acc + s.value);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DonutPainter(
                  segments: widget.segments,
                  total: sum,
                  strokeWidth: widget.strokeWidth,
                  progress: _curve.value,
                ),
              );
            },
          ),
          widget.centerWidget ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink2,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'S/ ${NumberFormat('#,##0', 'en').format(sum)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: MgColors.ink,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.progress,
  });

  final List<DonutSegment> segments;
  final double total;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Fondo tenue circular
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    double currentAngle = -math.pi / 2;
    const double gap = 0.045; // Separación limpia entre categorías

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.value <= 0) continue;
      final double segTotalSweep = (seg.value / total) * 2 * math.pi;

      // Stagger por segmento (50ms aprox en progreso de 0 a 1)
      final double segStart = (i * 0.08).clamp(0.0, 0.6);
      final double segEnd = (segStart + 0.4).clamp(0.0, 1.0);
      final double t = (progress <= segStart)
          ? 0.0
          : (progress >= segEnd ? 1.0 : (progress - segStart) / (segEnd - segStart));
      final double easedT = Curves.easeOutCubic.transform(t);

      final double currentSweep = segTotalSweep * easedT;
      final double actualSweep = math.max(0.0, currentSweep - gap);

      if (actualSweep > 0) {
        final paint = Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(rect, currentAngle + (gap / 2), actualSweep, false, paint);
      }
      currentAngle += segTotalSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.segments != segments || old.total != total;
}

/// Gráfica circular de anillos concéntricos estilo Apple Activity / Radial Bar
/// con Syncfusion (SfCircularChart y RadialBarSeries).
class RadialRingsChart extends StatelessWidget {
  const RadialRingsChart({
    super.key,
    required this.segments,
    this.total,
    this.size = 200,
    this.centerTitle = 'Total',
    this.centerWidget,
  });

  final List<DonutSegment> segments;
  final double? total;
  final double size;
  final String centerTitle;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    final double sum = total ??
        segments.fold<double>(0.0, (double acc, DonutSegment s) => acc + s.value);

    // Tomamos las principales categorías y las invertimos para que la mayor quede afuera
    final topSegments = segments.take(4).toList().reversed.toList();
    final maxVal = segments.fold<double>(
      1.0,
      (prev, el) => math.max(prev, el.value),
    );

    return SizedBox(
      width: size,
      height: size,
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        annotations: <CircularChartAnnotation>[
          CircularChartAnnotation(
            widget: centerWidget ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'S/ ${NumberFormat('#,##0', 'en').format(sum)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: MgColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
          ),
        ],
        series: <RadialBarSeries<DonutSegment, String>>[
          RadialBarSeries<DonutSegment, String>(
            dataSource: topSegments,
            xValueMapper: (DonutSegment d, _) => d.label,
            yValueMapper: (DonutSegment d, _) => d.value,
            pointColorMapper: (DonutSegment d, _) => d.color,
            maximumValue: maxVal * 1.15,
            radius: '100%',
            innerRadius: '52%',
            gap: '8%',
            cornerStyle: CornerStyle.bothCurve,
            trackColor: const Color(0xFF22222D),
            trackOpacity: 0.65,
            useSeriesColor: false,
            animationDuration: 850,
            enableTooltip: false,
          ),
        ],
      ),
    );
  }
}

class MonthBarItem {
  const MonthBarItem({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}

/// Barras pareadas mensuales (Ingresos vs Gastos) con Syncfusion (SfCartesianChart).
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.data,
    this.height = 180,
  });

  final List<MonthBarItem> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SfCartesianChart(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(width: 0),
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: MgColors.ink2,
          ),
        ),
        primaryYAxis: const NumericAxis(
          isVisible: false,
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
        ),
        series: <CartesianSeries<MonthBarItem, String>>[
          ColumnSeries<MonthBarItem, String>(
            name: 'Ingresos',
            dataSource: data,
            xValueMapper: (MonthBarItem d, _) => d.label,
            yValueMapper: (MonthBarItem d, _) => d.income,
            color: MgColors.up,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            width: 0.35,
            spacing: 0.15,
            animationDuration: 750,
          ),
          ColumnSeries<MonthBarItem, String>(
            name: 'Gastos',
            dataSource: data,
            xValueMapper: (MonthBarItem d, _) => d.label,
            yValueMapper: (MonthBarItem d, _) => d.expense,
            color: MgColors.down,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            width: 0.35,
            spacing: 0.15,
            animationDuration: 750,
          ),
        ],
      ),
    );
  }
}
