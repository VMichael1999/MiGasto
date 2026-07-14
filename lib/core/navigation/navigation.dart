import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/expenses/expenses_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/providers.dart';
import '../../shared/widgets/overlay_timer_widget.dart';
import '../../domain/entities/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.read(sharedPreferencesProvider).getBool('onboarding_complete') ?? false;
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: onboardingComplete ? '/dashboard' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffoldWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExpensesScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

// A wrapper that listens to the pending transaction from Riverpod and inserts the FloatingOverlayPanel
class MainScaffoldWrapper extends ConsumerWidget {
  final Widget child;

  const MainScaffoldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    
    // Bottom navigation selection index mapping
    int selectedIndex = 0;
    if (location == '/expenses') {
      selectedIndex = 1;
    } else if (location == '/reports') {
      selectedIndex = 3; // 2 is the Floating Action Button, 3 is Reports
    } else if (location == '/settings') {
      selectedIndex = 4;
    }

    return Scaffold(
      body: OverlayTimerWidget(
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/expenses');
          } else if (index == 2) {
            // Floating Action Button (+) tapped: trigger quick manual add dialog on dashboard
            _showQuickAddDialog(context, ref);
          } else if (index == 3) {
            context.go('/reports');
          } else if (index == 4) {
            context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Gastos',
          ),
          // We put a custom icon placeholder for the FAB (+)
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 40, color: Colors.greenAccent),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final conceptController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.compras;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              title: const Text(
                'Registrar Gasto Manual',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Monto (S/)',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixText: 'S/ ',
                        prefixStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E2B3B))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: conceptController,
                      decoration: InputDecoration(
                        labelText: 'Establecimiento / Detalle',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E2B3B))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: selectedCategory,
                      dropdownColor: AppTheme.cardBg,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E2B3B))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: ExpenseCategory.values.map((cat) {
                        String name = cat.name;
                        if (cat == ExpenseCategory.alimentacion) name = 'Alimentación';
                        if (cat == ExpenseCategory.transporte) name = 'Transporte';
                        if (cat == ExpenseCategory.compras) name = 'Compras';
                        if (cat == ExpenseCategory.servicios) name = 'Servicios';
                        if (cat == ExpenseCategory.entretenimiento) name = 'Entretenimiento';
                        if (cat == ExpenseCategory.otros) name = 'Otros';

                        return DropdownMenuItem(
                          value: cat,
                          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (cat) {
                        if (cat != null) {
                          setDialogState(() {
                            selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    final concept = conceptController.text.trim();
                    if (amt > 0 && concept.isNotEmpty) {
                      ref.read(expensesStateProvider.notifier).addManualExpense(amt, concept, selectedCategory);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
