import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/movimiento.dart';
import 'expense_detail_dialog.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  Categoria? _filterCategory;
  RangeValues? _filterAmountRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStateProvider);

    // Filter confirmed
    final confirmedExpenses = expenses.where((e) => e.isConfirmed).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar establecimiento...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : const Text('Gastos'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppTheme.cardBg,
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog(context);
              } else if (value == 'export_csv') {
                _exportToCsv(context);
              } else if (value == 'simulate') {
                _simulateRandomTransaction(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Eliminar todos los gastos', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Text('Exportar a CSV', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: 'simulate',
                  child: Text('Simular Transacción', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonGreen,
          labelColor: AppTheme.neonGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Yape'),
            Tab(text: 'Plin'),
            Tab(text: 'Google Pay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpenseList(confirmedExpenses, 'all'),
          _buildExpenseList(confirmedExpenses, 'yape'),
          _buildExpenseList(confirmedExpenses, 'plin'),
          _buildExpenseList(confirmedExpenses, 'googlePay'),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<Movimiento> allList, String providerFilter) {
    // 1. Filter by provider
    var filtered = allList;
    if (providerFilter != 'all') {
      filtered = allList.where((e) => e.source.name.toLowerCase() == providerFilter.toLowerCase()).toList();
    }

    // 2. Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) => e.merchant.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 2b. Filter by category
    if (_filterCategory != null) {
      filtered = filtered.where((e) => e.category == _filterCategory).toList();
    }

    // 2c. Filter by amount range
    if (_filterAmountRange != null) {
      filtered = filtered.where((e) => e.amount >= _filterAmountRange!.start && e.amount <= _filterAmountRange!.end).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'No se encontraron gastos',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // 3. Group by Day
    final groupedMap = <String, List<Movimiento>>{};
    for (final exp in filtered) {
      final key = _getDayLabel(exp.date);
      groupedMap[key] ??= [];
      groupedMap[key]!.add(exp);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: groupedMap.keys.length,
      itemBuilder: (context, index) {
        final dayLabel = groupedMap.keys.elementAt(index);
        final dayExpenses = groupedMap[dayLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Day Header (e.g. Hoy, Ayer)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
              child: Text(
                dayLabel,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
            
            // List of cards for this day
            ...dayExpenses.map((exp) {
              final timeStr = DateFormat('h:mm a', 'es').format(exp.date);
              final categoryColor = AppTheme.getCategoryColor(exp.category);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Dismissible(
                  key: ValueKey(exp.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
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
                            timeStr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
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
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) {
      return 'Hoy';
    } else if (check == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE d \'de\' MMMM', 'es').format(date);
    }
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

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Eliminar Todo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('¿Estás seguro de que deseas eliminar todos los gastos confirmados? Esta acción es irreversible.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final expenses = ref.read(expensesStateProvider);
                final notifier = ref.read(expensesStateProvider.notifier);
                for (final exp in expenses) {
                  await notifier.deleteExpense(exp.id);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todos los gastos han sido eliminados')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Eliminar todo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _exportToCsv(BuildContext context) {
    final expenses = ref.read(expensesStateProvider);
    final buffer = StringBuffer();
    buffer.writeln('ID,Monto,Establecimiento,Categoria,Metodo,Fecha,Notas');
    for (final exp in expenses.where((e) => e.isConfirmed)) {
      final dateStr = exp.date.toIso8601String();
      final categoryName = AppTheme.getCategoryNameEs(exp.category);
      buffer.writeln('${exp.id},${exp.amount},"${exp.merchant}",$categoryName,${exp.source.name},$dateStr,"${exp.notes}"');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString())).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial exportado y copiado al portapapeles')),
        );
      }
    });
  }

  void _simulateRandomTransaction(BuildContext context) {
    final list = [
      {'amount': 45.00, 'merchant': 'Plaza Vea', 'provider': 'yape', 'rawText': 'Yapeaste S/ 45.00 a Plaza Vea'},
      {'amount': 12.50, 'merchant': 'KFC', 'provider': 'plin', 'rawText': 'Recibiste S/ 12.50 de KFC'},
      {'amount': 95.00, 'merchant': 'Saga Falabella', 'provider': 'googlePay', 'rawText': 'Pagaste S/ 95.00 en Saga Falabella'},
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

  void _showFilterDialog(BuildContext context) {
    Categoria? tempCategory = _filterCategory;
    RangeValues tempRange = _filterAmountRange ?? const RangeValues(0, 500);
    bool rangeActive = _filterAmountRange != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1826),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Filtrar gastos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  // Category filter
                  const Text('Categoría', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: tempCategory == null,
                            selectedColor: AppTheme.neonGreen,
                            labelStyle: TextStyle(
                              color: tempCategory == null ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: const Color(0xFF1E1D24),
                            onSelected: (_) {
                              setSheetState(() { tempCategory = null; });
                            },
                          ),
                        ),
                        ...Categoria.values.map((cat) {
                          final isSelected = tempCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(AppTheme.getCategoryNameEs(cat)),
                              selected: isSelected,
                              selectedColor: AppTheme.getCategoryColor(cat),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: const Color(0xFF1E1D24),
                              onSelected: (_) {
                                setSheetState(() { tempCategory = cat; });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount range filter
                  Row(
                    children: [
                      const Text('Rango de monto', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        'S/ ${tempRange.start.toInt()} - S/ ${tempRange.end.toInt()}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 500,
                    divisions: 50,
                    activeColor: AppTheme.neonGreen,
                    inactiveColor: const Color(0xFF2E2B3B),
                    labels: RangeLabels(
                      'S/ ${tempRange.start.toInt()}',
                      'S/ ${tempRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setSheetState(() {
                        tempRange = values;
                        rangeActive = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterCategory = tempCategory;
                        _filterAmountRange = rangeActive ? tempRange : null;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _filterCategory = null;
                          _filterAmountRange = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar filtros', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
