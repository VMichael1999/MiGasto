import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/expense.dart';
import '../expenses/expense_detail_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBalanceHidden = false;
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStateProvider);

    final now = DateTime.now();
    
    // Filter confirmed expenses for THIS month
    final confirmedExpenses = expenses.where((e) {
      return e.isConfirmed &&
          e.date.year == now.year &&
          e.date.month == now.month;
    }).toList();
    
    // Calculate total spent this month
    final totalSpent = confirmedExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final budget = ref.watch(budgetProvider);

    // Group by category totals (this month)
    final categoryMap = <ExpenseCategory, double>{};
    for (final exp in confirmedExpenses) {
      categoryMap[exp.category] = (categoryMap[exp.category] ?? 0.0) + exp.amount;
    }

    // Calculate previous month total spent
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthExpenses = expenses.where((e) {
      return e.isConfirmed &&
          e.date.year == lastMonthYear &&
          e.date.month == lastMonth;
    }).toList();
    final lastMonthSpent = lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    double percentDiff = 0.0;
    if (lastMonthSpent > 0) {
      percentDiff = ((totalSpent - lastMonthSpent) / lastMonthSpent) * 100.0;
    }

    // Top recent movements (confirmed, all-time, up to 3)
    final allConfirmed = expenses.where((e) => e.isConfirmed).toList();
    final recentMovements = allConfirmed.take(3).toList();

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppTheme.cardBg,
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final name = ref.watch(profileNameProvider);
                final email = ref.watch(profileEmailProvider);
                final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
                final initialsToShow = initials.length > 2 ? initials.substring(0, 2) : initials;

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D1B26),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppTheme.neonGreen,
                    child: Text(
                      initialsToShow.isNotEmpty ? initialsToShow : 'U',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  accountName: Text(
                    name.isNotEmpty ? name : 'Configurar Nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: name.isNotEmpty ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  accountEmail: Text(
                    email.isNotEmpty ? email : 'correo@ejemplo.com',
                    style: TextStyle(
                      color: email.isNotEmpty ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppTheme.neonGreen),
              title: const Text('Resumen / Inicio', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.white70),
              title: const Text('Historial de Gastos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/expenses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white70),
              title: const Text('Reportes', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text('Ajustes del Sistema', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            if (kDebugMode)
              const Divider(color: Color(0xFF2E2B3B)),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: Colors.orangeAccent),
                title: const Text('Simular Transacción', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _simulateRandomTransaction(context, ref);
                },
              ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text('Resumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              _showNotificationStatusDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOTAL SPENT HEADER CARD
            _buildTotalSpentCard(context, totalSpent, lastMonthSpent, percentDiff),
            const SizedBox(height: 20),

            // BUDGET PROGRESS BAR
            if (budget > 0) ...[
              _buildBudgetProgressCard(context, totalSpent, budget),
              const SizedBox(height: 20),
            ],

            // POR CATEGORÍA PIE CHART CARD
            if (confirmedExpenses.isNotEmpty) ...[
              _buildCategoryChartCard(context, categoryMap, totalSpent),
              const SizedBox(height: 20),
            ],

            // ÚLTIMOS MOVIMIENTOS CARD
            _buildRecentMovementsCard(context, recentMovements, now),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSpentCard(
    BuildContext context,
    double totalSpent,
    double lastMonthSpent,
    double percentDiff,
  ) {
    return Card(
      color: AppTheme.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gasto total este mes',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isBalanceHidden ? 'S/ ••••' : 'S/ ${totalSpent.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            if (lastMonthSpent > 0) ...[
              Row(
                children: [
                  Icon(
                    percentDiff <= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: percentDiff <= 0 ? Colors.greenAccent : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentDiff <= 0 ? "" : "+"}${percentDiff.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: percentDiff <= 0 ? Colors.greenAccent[400] : Colors.redAccent[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'vs. mes anterior',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Sin datos del mes anterior',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChartCard(
    BuildContext context,
    Map<ExpenseCategory, double> categoryMap,
    double totalSpent,
  ) {
    // Generate sections
    final List<PieChartSectionData> sections = [];
    int index = 0;
    categoryMap.forEach((category, amount) {
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 38.0 : 32.0;
      final color = AppTheme.getCategoryColor(category);

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '', // Don't show percentages on pie slice to match mockup look
          radius: radius,
        ),
      );
      index++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Por categoría',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Pie Chart Container
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 128,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: sections,
                          ),
                        ),
                        // Text in center matching mockup
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isBalanceHidden ? 'S/ ••••' : 'S/ ${(totalSpent / 1000).toStringAsFixed(2)}k',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Legend list on the right matching Mockup Screen 2 values
                Expanded(
                  flex: 5,
                  child: Column(
                    children: ExpenseCategory.values.map((cat) {
                      final amount = categoryMap[cat] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.getCategoryColor(cat),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppTheme.getCategoryNameEs(cat),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Text(
                              'S/ ${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMovementsCard(
    BuildContext context,
    List<Expense> list,
    DateTime now,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Últimos movimientos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/expenses');
              },
              child: const Text(
                'Ver todos',
                style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Card(
            color: AppTheme.cardBg,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No hay gastos confirmados en el mes.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exp = list[index];
              final timeStr = DateFormat('h:mm a', 'es').format(exp.date);
              final categoryColor = AppTheme.getCategoryColor(exp.category);

              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));
              final checkDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
              
              String dayText;
              if (checkDate == today) {
                dayText = 'Hoy';
              } else if (checkDate == yesterday) {
                dayText = 'Ayer';
              } else {
                dayText = DateFormat('dd MMM', 'es').format(exp.date);
              }

              return Dismissible(
                key: ValueKey(exp.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  final merchant = exp.merchant;
                  ref.read(expensesStateProvider.notifier).deleteExpense(exp.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gasto en "$merchant" eliminado')),
                  );
                },
                child: Card(
                  color: AppTheme.cardBg,
                  child: ListTile(
                    onTap: () => showExpenseDetailSheet(context, ref, exp),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildBadgeIcon(exp.source),
                    title: Text(
                      exp.merchant,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          '$dayText, $timeStr',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        // Styled category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: categoryColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Text(
                            AppTheme.getCategoryNameEs(exp.category),
                            style: TextStyle(
                              fontSize: 9,
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'S/ ${exp.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBadgeIcon(PaymentSource source) {
    Color color;
    String initial;
    switch (source) {
      case PaymentSource.yape:
        color = AppTheme.yapePurple;
        initial = 'Y';
        break;
      case PaymentSource.plin:
        color = AppTheme.plinTeal;
        initial = 'P';
        break;
      case PaymentSource.googlePay:
        color = AppTheme.googlePayBlue;
        initial = 'G';
        break;
      default:
        color = AppTheme.manualGray;
        initial = 'M';
    }

    return Container(

      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _simulateRandomTransaction(BuildContext context, WidgetRef ref) {
    final list = [
      {'amount': 25.50, 'merchant': 'Tambo', 'provider': 'yape', 'rawText': 'Yapeaste S/ 25.50 a Tambo'},
      {'amount': 15.00, 'merchant': 'Juan Pérez', 'provider': 'plin', 'rawText': 'Juan Pérez te envió S/ 15.00'},
      {'amount': 8.90, 'merchant': 'Oxxo', 'provider': 'googlePay', 'rawText': 'Pagaste S/ 8.90 en Oxxo'},
    ];
    final selected = (list..shuffle()).first;
    
    ref.read(expensesStateProvider.notifier).triggerIncomingPayment(
      amount: selected['amount'] as double,
      merchant: selected['merchant'] as String,
      providerStr: selected['provider'] as String,
      rawText: selected['rawText'] as String,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulado: ${selected['rawText']}'),
        backgroundColor: AppTheme.cardBg,
      ),
    );
  }

  Widget _buildBudgetProgressCard(BuildContext context, double totalSpent, double budget) {
    final ratio = totalSpent / budget;
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final percentage = (ratio * 100).toStringAsFixed(1);

    Color progressColor;
    if (ratio > 1.0) {
      progressColor = Colors.redAccent;
    } else if (ratio >= 0.75) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.greenAccent;
    }

    return Card(
      color: AppTheme.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuesto mensual',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clampedRatio,
                minHeight: 8,
                backgroundColor: const Color(0xFF2E2B3B),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'S/ ${totalSpent.toStringAsFixed(2)} de S/ ${budget.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationStatusDialog(BuildContext context) {
    final permissions = ref.read(permissionsCheckerProvider);
    final testerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder<List<bool>>(
              future: Future.wait([
                permissions.isAccessibilityEnabled(),
                permissions.isOverlayGranted(),
              ]),
              builder: (context, snapshot) {
                final isAccess = snapshot.data?[0] ?? false;
                final isOverlay = snapshot.data?[1] ?? false;

                return AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  title: const Row(
                    children: [
                      Icon(Icons.notifications_active, color: AppTheme.neonGreen),
                      SizedBox(width: 10),
                      Text(
                        'Lector de Notificaciones',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1B26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isAccess ? Icons.check_circle : Icons.error,
                                    color: isAccess ? Colors.greenAccent : Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isAccess ? 'Servicio de Accesibilidad activo' : 'Servicio de Accesibilidad inactivo',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isOverlay ? Icons.check_circle : Icons.error,
                                    color: isOverlay ? Colors.greenAccent : Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isOverlay ? 'Permiso de Superposición concedido' : 'Permiso de Superposición pendiente',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!isAccess)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await permissions.openAccessibilitySettings();
                              Future.delayed(const Duration(seconds: 1), () {
                                if (context.mounted) setDialogState(() {});
                              });
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Activar Accesibilidad'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        if (!isOverlay) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await permissions.requestOverlayPermission();
                              Future.delayed(const Duration(seconds: 1), () {
                                if (context.mounted) setDialogState(() {});
                              });
                            },
                            icon: const Icon(Icons.layers_outlined),
                            label: const Text('Conceder Superposición'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'Simular Entrada de Notificación',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: testerController,
                          decoration: const InputDecoration(
                            hintText: 'Ej. Juan te yapeó S/ 15.00',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E2B3B))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            final text = testerController.text.trim();
                            if (text.isNotEmpty) {
                              permissions.simulateNotification(text);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Probar Lector', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
