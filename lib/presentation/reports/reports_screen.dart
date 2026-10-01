import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/movimiento.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;
  int _selectedYear = DateTime.now().year;
  late DateTimeRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStateProvider);
    final confirmed = expenses.where((e) => e.isConfirmed && e.esGasto).toList();

    // 1. Calculations for Monthly Tab
    final confirmedForMonth = confirmed.where((e) {
      return e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month;
    }).toList();
    final totalSpentForMonth = confirmedForMonth.fold(0.0, (sum, e) => sum + e.amount);
    final categoryMapForMonth = <Categoria, double>{};
    for (final exp in confirmedForMonth) {
      categoryMapForMonth[exp.category] = (categoryMapForMonth[exp.category] ?? 0.0) + exp.amount;
    }
    final weeklySpendingForMonth = _calculateWeeklySpending(confirmedForMonth);
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(_selectedMonth);
    final formattedMonth = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonGreen,
          labelColor: AppTheme.neonGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mensual'),
            Tab(text: 'Anual'),
            Tab(text: 'Personalizado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyReport(context, confirmedForMonth, categoryMapForMonth, weeklySpendingForMonth, totalSpentForMonth, formattedMonth),
          _buildAnnualReport(context, confirmed),
          _buildCustomReport(context, confirmed),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport(
    BuildContext context,
    List<Movimiento> list,
    Map<Categoria, double> categoryMap,
    List<double> weeklySpending,
    double totalSpent,
    String monthLabel,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Switcher Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                monthLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Spent Amount Display
          Center(
            child: Column(
              children: [
                Text(
                  'S/ ${totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Total de gastos',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // WEEKLY SPENDING BAR CHART
          _buildWeeklyBarChart(context, weeklySpending),
          const SizedBox(height: 24),

          // GASTOS POR CATEGORÍA PROGRESS BARS
          _buildCategoryBreakdownList(context, categoryMap, totalSpent),
        ],
      ),
    );
  }

  Widget _buildAnnualReport(BuildContext context, List<Movimiento> list) {
    // 1. Filter by selected year
    final confirmedForYear = list.where((e) => e.date.year == _selectedYear).toList();

    // 2. Total spent
    final totalSpent = confirmedForYear.fold(0.0, (sum, e) => sum + e.amount);

    // 3. Category breakdown
    final categoryMap = <Categoria, double>{};
    for (final exp in confirmedForYear) {
      categoryMap[exp.category] = (categoryMap[exp.category] ?? 0.0) + exp.amount;
    }

    // 4. Monthly spending distribution
    final monthlySpending = List.generate(12, (index) => 0.0);
    for (final exp in confirmedForYear) {
      if (exp.date.month >= 1 && exp.date.month <= 12) {
        monthlySpending[exp.date.month - 1] += exp.amount;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Year Switcher Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedYear--;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Año $_selectedYear',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Spent Amount Display
          Center(
            child: Column(
              children: [
                Text(
                  'S/ ${totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Total gastado en el año',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ANNUAL BAR CHART
          _buildAnnualBarChart(context, monthlySpending),
          const SizedBox(height: 24),

          // GASTOS POR CATEGORÍA
          _buildCategoryBreakdownList(context, categoryMap, totalSpent),
        ],
      ),
    );
  }

  Widget _buildCustomReport(BuildContext context, List<Movimiento> list) {
    // 1. Filter by range
    final confirmedForRange = list.where((e) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      final startOnly = DateTime(_selectedRange.start.year, _selectedRange.start.month, _selectedRange.start.day);
      final endOnly = DateTime(_selectedRange.end.year, _selectedRange.end.month, _selectedRange.end.day);
      return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) &&
             (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
    }).toList();

    // 2. Total spent
    final totalSpent = confirmedForRange.fold(0.0, (sum, e) => sum + e.amount);

    // 3. Category breakdown
    final categoryMap = <Categoria, double>{};
    for (final exp in confirmedForRange) {
      categoryMap[exp.category] = (categoryMap[exp.category] ?? 0.0) + exp.amount;
    }

    final df = DateFormat('dd/MM/yyyy');
    final rangeText = 'Desde ${df.format(_selectedRange.start)} hasta ${df.format(_selectedRange.end)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Range Selector Button
          Card(
            color: AppTheme.cardBg,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectDateRange(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.date_range, color: AppTheme.neonGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rangeText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Total Spent Amount Display
          Center(
            child: Column(
              children: [
                Text(
                  'S/ ${totalSpent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Gasto total en este rango',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // GASTOS POR CATEGORÍA
          _buildCategoryBreakdownList(context, categoryMap, totalSpent),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonGreen,
              onPrimary: Colors.black,
              surface: AppTheme.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  Widget _buildWeeklyBarChart(BuildContext context, List<double> weeklySpending) {
    final maxVal = weeklySpending.reduce((curr, next) => curr > next ? curr : next);
    final double maxY = maxVal > 0 ? (maxVal * 1.2).ceilToDouble() : 400.0;

    return Card(
      color: AppTheme.cardBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text = '';
                          switch (value.toInt()) {
                            case 0:
                              text = '1-7';
                              break;
                            case 1:
                              text = '8-14';
                              break;
                            case 2:
                              text = '15-21';
                              break;
                            case 3:
                              text = '22-31';
                              break;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              text,
                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                            textAlign: TextAlign.end,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(4, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklySpending[i],
                          color: AppTheme.neonGreen,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: const Color(0xFF131219),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualBarChart(BuildContext context, List<double> monthlySpending) {
    final maxVal = monthlySpending.reduce((curr, next) => curr > next ? curr : next);
    final double maxY = maxVal > 0 ? (maxVal * 1.2).ceilToDouble() : 400.0;

    final monthLabels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return Card(
      color: AppTheme.cardBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < 12) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthLabels[idx],
                                style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 8),
                            textAlign: TextAlign.end,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: monthlySpending[i],
                          color: AppTheme.neonGreen,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: const Color(0xFF131219),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownList(
    BuildContext context,
    Map<Categoria, double> categoryMap,
    double totalSpent,
  ) {
    // Sort categories by amount descending
    final list = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Gastos por categoría',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (list.isEmpty)
          Card(
            color: AppTheme.cardBg,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No hay datos en este período', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = list[index];
              final cat = entry.key;
              final amount = entry.value;
              final pct = totalSpent > 0 ? (amount / totalSpent) : 0.0;
              final catColor = AppTheme.getCategoryColor(cat);

              return Card(
                color: AppTheme.cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            AppTheme.getCategoryEmoji(cat),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppTheme.getCategoryNameEs(cat),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'S/ ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress Bar matching mockup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF131219),
                          valueColor: AlwaysStoppedAnimation<Color>(catColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  List<double> _calculateWeeklySpending(List<Movimiento> confirmed) {
    // 4 buckets representing week 1 (1-7), week 2 (8-14), week 3 (15-21), week 4 (22-31)
    final buckets = [0.0, 0.0, 0.0, 0.0];
    for (final exp in confirmed) {
      final day = exp.date.day;
      if (day >= 1 && day <= 7) {
        buckets[0] += exp.amount;
      } else if (day >= 8 && day <= 14) {
        buckets[1] += exp.amount;
      } else if (day >= 15 && day <= 21) {
        buckets[2] += exp.amount;
      } else {
        buckets[3] += exp.amount;
      }
    }
    return buckets;
  }
}
