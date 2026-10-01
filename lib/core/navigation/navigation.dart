import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/expenses/expenses_screen.dart';
import '../../presentation/expenses/manual_entry_screen.dart';
import '../../presentation/expenses/movement_detail_screen.dart';
import '../../presentation/expenses/where_screen.dart';
import '../../presentation/setup/apple_pay_setup_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/providers.dart';
import '../../shared/widgets/overlay_timer_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.read(sharedPreferencesProvider).getBool('onboarding_complete') ?? false;
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: onboardingComplete ? '/dashboard' : '/onboarding',
    // Enlaces migasto://new (widget y Centro de control) abren el registro manual.
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'migasto') {
        return uri.host == 'new' ? '/new' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/movement/:id',
        builder: (context, state) => MovementDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/setup/apple-pay',
        builder: (context, state) =>
            ApplePaySetupScreen(fromOnboarding: state.uri.queryParameters['onboarding'] == '1'),
      ),
      GoRoute(
        path: '/where',
        builder: (context, state) => const WhereScreen(),
      ),
      GoRoute(
        path: '/new',
        builder: (context, state) => const ManualEntryScreen(),
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
      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/expenses');
          } else if (index == 3) {
            context.go('/reports');
          } else if (index == 4) {
            context.go('/settings');
          }
        },
        onAdd: () => context.push('/new'),
      ),
    );
  }
}
