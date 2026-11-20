import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/mg_card.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/profile_avatar_button.dart';
import '../../shared/profile.dart';
import '../providers.dart';
import 'fullscreen_chart_screen.dart';
import '../../core/layout/adaptive.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _currentMonth = DateTime.now();
  final String _selectedSpace = 'Personal';
  int _chartTypeIndex = 1; // 0: Anillos concéntricos (Syncfusion), 1: Dona (DonutChart)

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _formatMonthHeader(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} de ${date.year}';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Martes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMovs = ref.watch(expensesStateProvider);
    final isHide = ref.watch(balanceHiddenProvider);

    // Movimientos del mes seleccionado
    final monthMovs = allMovs.where((m) =>
        m.isConfirmed &&
        m.date.year == _currentMonth.year &&
        m.date.month == _currentMonth.month).toList();

    // Mes anterior para comparación
    final prevMonthDate = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final prevMonthMovs = allMovs.where((m) =>
        m.isConfirmed &&
        m.date.year == prevMonthDate.year &&
        m.date.month == prevMonthDate.month).toList();

    final currentGastos = monthMovs
        .where((m) => m.tipo == TipoMovimiento.gasto)
        .fold<double>(0.0, (s, m) => s + m.amount);

    final prevGastos = prevMonthMovs
        .where((m) => m.tipo == TipoMovimiento.gasto)
        .fold<double>(0.0, (s, m) => s + m.amount);

    // Día que más gastas
    final daySpending = <int, double>{};
    for (final m in monthMovs.where((m) => m.tipo == TipoMovimiento.gasto)) {
      daySpending[m.date.weekday] = (daySpending[m.date.weekday] ?? 0.0) + m.amount;
    }
    String topDay = '—';
    if (daySpending.isNotEmpty) {
      final best = daySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
      topDay = _weekdayName(best.key);
    }

    // vs periodo anterior
    // Sin gastos el mes anterior no hay con qué comparar: no se muestra ningún porcentaje.
    String vsPeriodoText = '—';
    Color vsPeriodoColor = MgColors.ink2;
    if (prevGastos > 0) {
      final diff = ((currentGastos - prevGastos) / prevGastos) * 100;
      final sign = diff >= 0 ? '+' : '';
      vsPeriodoText = '$sign${diff.toStringAsFixed(0)}%';
      vsPeriodoColor = diff > 0 ? MgColors.down : MgColors.up;
    }

    // Gastos por categoría
    final catMap = <Categoria, double>{};
    for (final m in monthMovs.where((m) => m.tipo == TipoMovimiento.gasto)) {
      final cat = m.category;
      catMap[cat] = (catMap[cat] ?? 0.0) + m.amount;
    }

    final catList = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalPorCategorias = catList.fold<double>(0.0, (s, e) => s + e.value);

    final segments = catList.map((e) {
      return DonutSegment(
        label: categoryLabel(e.key),
        value: e.value,
        color: CategoryIcon.colorForCategory(e.key),
      );
    }).toList();

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera superior idéntica a inicio y plan
              _buildTopBar(context, isHide),

              // Selector de mes (.mnav)
              _buildMonthNav(),

              // Mini cards (.mini)
              _buildMiniCards(topDay, vsPeriodoText, vsPeriodoColor),

              // Tarjeta 1: Gastos por categoría
              _buildCategoryCard(context, segments, catList, totalPorCategorias, isHide),

              // Tarjeta 2: Ingresos vs gastos (6 meses)
              _buildIncomeVsExpenseCard(allMovs),

              SizedBox(height: context.tabBarClearance(160)),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabecera con selector de espacio, toggle de saldo y botón de notificaciones
  Widget _buildTopBar(BuildContext context, bool isHide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: MgColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: MgGradients.brandMark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialsOf(ref.watch(profileNameProvider)).isEmpty
                          ? 'MG'
                          : initialsOf(ref.watch(profileNameProvider)),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSpace,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Botón ocultar/mostrar saldos
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              ref.read(balanceHiddenProvider.notifier).toggle();
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Icon(
                isHide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: MgColors.ink2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const ProfileAvatarButton(size: 34),
        ],
      ),
    );
  }

  /// Selector de mes (.mnav)
  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _prevMonth,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: MgColors.ink2,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: MgColors.ink2,
              ),
              const SizedBox(width: 7),
              Text(
                _formatMonthHeader(_currentMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MgColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _nextMonth,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: MgColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mini tarjetas resumen (.mini)
  Widget _buildMiniCards(String topDay, String vsPeriodoText, Color vsPeriodoColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          // Tarjeta 1: Día que más gastas
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: MgColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0x227C5CFF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: Color(0xFFA78BFA),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Día que más gastas',
                    style: TextStyle(
                      fontSize: 11,
                      color: MgColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topDay,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Tarjeta 2: vs periodo anterior
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: MgColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0x22FF5C6E),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: MgColors.down,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'vs periodo anterior',
                    style: TextStyle(
                      fontSize: 11,
                      color: MgColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vsPeriodoText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: vsPeriodoColor,
                      letterSpacing: -0.2,
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

  /// Tarjeta: Gastos por categoría (.card)
  Widget _buildCategoryCard(
    BuildContext context,
    List<DonutSegment> segments,
    List<MapEntry<Categoria, double>> catList,
    double total,
    bool isHide,
  ) {
    final top4 = catList.take(4).toList();

    if (catList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: MgCard(
          padding: EdgeInsets.all(18),
          child: Text(
            'Aún no hay gastos registrados este mes.',
            style: TextStyle(fontSize: 13, color: MgColors.ink2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: MgCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con selector de tipo de gráfico y botón expandir
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gastos por categoría',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Selector de vista: Anillos / Dona
                Container(
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChartTypeTab(
                        label: 'Anillos',
                        icon: Icons.track_changes_rounded,
                        isSelected: _chartTypeIndex == 0,
                        onTap: () => setState(() => _chartTypeIndex = 0),
                      ),
                      _buildChartTypeTab(
                        label: 'Dona',
                        icon: Icons.donut_large_rounded,
                        isSelected: _chartTypeIndex == 1,
                        onTap: () => setState(() => _chartTypeIndex = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => FullscreenChartScreen(
                          month: _currentMonth,
                          spaceName: _selectedSpace,
                          segments: segments,
                          catList: catList,
                          total: total,
                          isHide: isHide,
                          initialChartIndex: _chartTypeIndex,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 20,
                      color: MgColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Gráfico animado (Anillos con Syncfusion o Dona de alta fidelidad)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: _chartTypeIndex == 0
                    ? RadialRingsChart(
                        key: const ValueKey('radial_rings_chart'),
                        segments: segments,
                        total: total,
                        size: 210,
                        centerWidget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isHide ? '••••' : 'S/ ${NumberFormat('#,##0.00', 'en').format(total)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: MgColors.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'gastado',
                              style: TextStyle(
                                fontSize: 11,
                                color: MgColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DonutChart(
                        key: const ValueKey('donut_chart'),
                        segments: segments,
                        total: total,
                        size: 195,
                        strokeWidth: 20,
                        centerWidget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isHide ? '••••' : 'S/ ${NumberFormat('#,##0.00', 'en').format(total)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: MgColors.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'gastado',
                              style: TextStyle(
                                fontSize: 11,
                                color: MgColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Leyenda top 4 (.leg)
            for (var i = 0; i < top4.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CategoryIcon.colorForCategory(top4[i].key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      CategoryIcon.iconForCategory(top4[i].key),
                      size: 15,
                      color: CategoryIcon.colorForCategory(top4[i].key),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryLabel(top4[i].key),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MgColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      isHide ? '••••' : 'S/ ${NumberFormat('#,##0.00', 'en').format(top4[i].value)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < top4.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
            ],

            const SizedBox(height: 10),

            // Botón "Ver todas"
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showAllCategoriesSheet(context, catList, total, isHide),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: MgColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Ver todas (${catList.length})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: MgColors.ink2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  /// Tarjeta: Ingresos vs gastos (.card)
  Widget _buildIncomeVsExpenseCard(List<Movimiento> allMovs) {
    // Últimos 6 meses (terminando en el mes elegido), con los movimientos reales.
    final history = <MonthBarItem>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(_currentMonth.year, _currentMonth.month - i);
      final inMonth = allMovs.where((m) =>
          m.isConfirmed && m.date.year == month.year && m.date.month == month.month);
      history.add(MonthBarItem(
        label: toBeginningOfSentenceCase(DateFormat('MMM', 'es').format(month))!,
        income: inMonth.where((m) => m.esIngreso).fold(0.0, (s, m) => s + m.amount),
        expense: inMonth.where((m) => m.esGasto).fold(0.0, (s, m) => s + m.amount),
      ));
    }
    final hasData = history.any((h) => h.income > 0 || h.expense > 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: MgCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresos vs gastos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MgColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),

            // Barras animadas (o aviso si todavía no hay movimientos)
            if (hasData)
              IncomeExpenseBars(
                data: history,
                height: 140,
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'Aún no hay ingresos ni gastos registrados.',
                    style: TextStyle(fontSize: 13, color: MgColors.ink2),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Leyenda (.leg2)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: MgColors.up,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ingresos',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: MgColors.down,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Gastos',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Modal con todas las categorías y su porcentaje
  void _showAllCategoriesSheet(
    BuildContext context,
    List<MapEntry<Categoria, double>> catList,
    double total,
    bool isHide,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: MgColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Todas las categorías',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: MgColors.ink,
                    ),
                  ),
                  Text(
                    isHide ? '••••' : 'S/ ${NumberFormat('#,##0.00', 'en').format(total)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MgColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: catList.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (_, index) {
                    final item = catList[index];
                    final pct = total > 0 ? (item.value / total) * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: CategoryIcon.colorForCategory(item.key).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              CategoryIcon.iconForCategory(item.key),
                              size: 18,
                              color: CategoryIcon.colorForCategory(item.key),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryLabel(item.key),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: MgColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pct.toStringAsFixed(1)} % del total',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: MgColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isHide ? '••••' : 'S/ ${NumberFormat('#,##0.00', 'en').format(item.value)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MgColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
