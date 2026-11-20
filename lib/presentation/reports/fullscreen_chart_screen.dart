import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/mg_card.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/labels.dart';

/// Pantalla completa para explorar el gráfico de gastos por categoría
/// y el desglose detallado con porcentajes y barras proporcionales.
class FullscreenChartScreen extends StatefulWidget {
  const FullscreenChartScreen({
    super.key,
    required this.month,
    required this.spaceName,
    required this.segments,
    required this.catList,
    required this.total,
    required this.isHide,
    this.initialChartIndex = 0,
  });

  final DateTime month;
  final String spaceName;
  final List<DonutSegment> segments;
  final List<MapEntry<Categoria, double>> catList;
  final double total;
  final bool isHide;
  final int initialChartIndex;

  @override
  State<FullscreenChartScreen> createState() => _FullscreenChartScreenState();
}

class _FullscreenChartScreenState extends State<FullscreenChartScreen> {
  late int _chartIndex = widget.initialChartIndex;

  String _formatMonth(DateTime d) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[d.month - 1]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final topCat = widget.catList.isNotEmpty ? widget.catList.first : null;

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera superior
            _buildHeader(context),

            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta principal con el gráfico en gran tamaño
                    _buildHeroChartCard(),

                    const SizedBox(height: 14),

                    // Fila de métricas rápidas
                    _buildKpiRow(topCat),

                    const SizedBox(height: 18),

                    // Título del desglose
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Desglose por categoría',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MgColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${widget.catList.length} categorías',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MgColors.ink2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Lista completa de categorías con barras de proporción
                    _buildCategoryBreakdownCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra superior con botón volver, título y selector de gráfico
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: MgColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gastos por categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_formatMonth(widget.month)} · ${widget.spaceName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          // Selector Anillos / Dona
          Container(
            height: 30,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleTab(
                  label: 'Anillos',
                  icon: Icons.track_changes_rounded,
                  isSelected: _chartIndex == 0,
                  onTap: () => setState(() => _chartIndex = 0),
                ),
                _buildToggleTab(
                  label: 'Dona',
                  icon: Icons.donut_large_rounded,
                  isSelected: _chartIndex == 1,
                  onTap: () => setState(() => _chartIndex = 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? MgColors.acc : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : MgColors.ink2,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : MgColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta con gráfico grande y total
  Widget _buildHeroChartCard() {
    final formattedTotal = widget.isHide
        ? '••••'
        : 'S/ ${NumberFormat('#,##0.00', 'en').format(widget.total)}';

    return MgCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: _chartIndex == 0
                ? RadialRingsChart(
                    key: const ValueKey('full_radial_rings'),
                    segments: widget.segments,
                    total: widget.total,
                    size: 250,
                    centerWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedTotal,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: MgColors.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'gastado este mes',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MgColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  )
                : DonutChart(
                    key: const ValueKey('full_donut_chart'),
                    segments: widget.segments,
                    total: widget.total,
                    size: 230,
                    strokeWidth: 24,
                    centerWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedTotal,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: MgColors.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'gastado este mes',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MgColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Fila de métricas rápidas
  Widget _buildKpiRow(MapEntry<Categoria, double>? topCat) {
    final topPercent = (widget.total > 0 && topCat != null)
        ? ((topCat.value / widget.total) * 100).toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: MgColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mayor gasto',
                  style: TextStyle(fontSize: 11, color: MgColors.ink2),
                ),
                const SizedBox(height: 4),
                Text(
                  topCat != null ? categoryLabel(topCat.key) : 'Sin datos',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$topPercent% del total',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MgColors.acc2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: MgColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promedio diario',
                  style: TextStyle(fontSize: 11, color: MgColors.ink2),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isHide
                      ? '••••'
                      : 'S/ ${NumberFormat('#,##0.00', 'en').format(widget.total / 30)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'en 30 días',
                  style: TextStyle(fontSize: 11, color: MgColors.ink2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Desglose completo de todas las categorías
  Widget _buildCategoryBreakdownCard() {
    return MgCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < widget.catList.length; i++) ...[
            _buildCategoryRow(widget.catList[i]),
            if (i < widget.catList.length - 1)
              Divider(
                height: 18,
                color: Colors.white.withValues(alpha: 0.05),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(MapEntry<Categoria, double> entry) {
    final catColor = CategoryIcon.colorForCategory(entry.key);
    final ratio = widget.total > 0 ? (entry.value / widget.total) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);
    final formattedVal = widget.isHide
        ? '••••'
        : 'S/ ${NumberFormat('#,##0.00', 'en').format(entry.value)}';

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                CategoryIcon.iconForCategory(entry.key),
                size: 16,
                color: catColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel(entry.key),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percent% del total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: MgColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formattedVal,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra proporcional de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(catColor),
          ),
        ),
      ],
    );
  }
}
