import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/expenses/expenses_screen.dart';
import '../../presentation/expenses/manual_entry_screen.dart';
import '../../presentation/expenses/movement_detail_screen.dart';
import '../../presentation/expenses/where_screen.dart';
import '../../presentation/setup/apple_pay_setup_screen.dart';
import '../../presentation/setup/avisos_setup_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/onboarding/permissions_screen.dart';
import '../../presentation/onboarding/splash_screen.dart';
import '../../presentation/onboarding/forgot_password_screen.dart';
import '../../presentation/onboarding/login_screen.dart';
import '../../presentation/setup/tutorial_video_screen.dart';
import '../../presentation/onboarding/register_screen.dart';
import '../../presentation/providers.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/plan/plan_screen.dart';
import '../../presentation/plan/new_limit_screen.dart';
import '../../presentation/plan/category_detail_screen.dart';
import '../../presentation/ai/ai_screen.dart';
import '../../shared/widgets/overlay_timer_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/movimiento.dart';
import '../theme/mg_colors.dart';
import '../widgets/mg_tab_bar.dart';
import '../widgets/register_sheet.dart';
import '../layout/adaptive.dart';

/// A dónde lleva un enlace `migasto://` de los widgets y del Centro de control:
/// `migasto://new` (registrar gasto), `migasto://new?type=ingreso`, `migasto://movement/<id>`
/// y `migasto://movements`. Cualquier otro abre Inicio.
String deepLinkLocation(Uri uri) {
  final segments = [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty).toList();
  final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
  return switch (segments) {
    ['new'] => '/new$query',
    ['movement', final id] => '/movement/${Uri.encodeComponent(id)}',
    ['movements'] => '/expenses',
    _ => '/dashboard',
  };
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    // Enlaces migasto:// de los widgets y del Centro de control (ver [deepLinkLocation]).
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'migasto') return deepLinkLocation(uri);

      final location = state.matchedLocation;

      // El splash screen siempre debe ejecutarse libremente sin ser interrumpido
      if (location == '/splash') {
        return null;
      }

      final prefs = ref.read(sharedPreferencesProvider);
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      // 1. Si no ha completado la bienvenida, debe ver el onboarding
      if (!onboardingComplete) {
        // La bienvenida incluye el paso de permisos (y, en iPhone, la guía de Apple Pay).
        const welcomeFlow = {
          '/onboarding',
          '/permisos',
          '/setup/apple-pay',
          '/setup/apple-pay/tutorial',
        };
        return welcomeFlow.contains(location) ? null : '/onboarding';
      }

      // 2. Si completó bienvenida pero no ha iniciado sesión, forzar pantalla de login
      if (!isLoggedIn) {
        return (location == '/login' || location == '/register' || location == '/forgot')
            ? null
            : '/login';
      }

      // 3. Si ya tiene sesión activa y se intenta acceder a login u onboarding, enviar al dashboard
      if (isLoggedIn &&
          (location == '/login' ||
              location == '/register' ||
              location == '/forgot' ||
              location == '/onboarding')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Perfil: se abre desde el avatar de las cabeceras, no es una pestaña.
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/permisos',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) =>
            ForgotPasswordScreen(initialEmail: state.extra is String ? state.extra as String : ''),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
        path: '/setup/avisos',
        builder: (context, state) => const AvisosSetupScreen(),
      ),
      GoRoute(
        path: '/setup/apple-pay/tutorial',
        builder: (context, state) => const TutorialVideoScreen(),
      ),
      GoRoute(
        path: '/where',
        builder: (context, state) => const WhereScreen(),
      ),
      GoRoute(
        path: '/new',
        builder: (context, state) {
          final t = state.uri.queryParameters['type'];
          final initialType = (t == 'income' || t == 'ingreso')
              ? TipoMovimiento.ingreso
              : TipoMovimiento.gasto;
          return ManualEntryScreen(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/add',
        redirect: (context, state) =>
            '/new${state.uri.query.isNotEmpty ? '?${state.uri.query}' : ''}',
      ),
      GoRoute(
        path: '/limit/new',
        builder: (context, state) {
          final catName = state.uri.queryParameters['cat'];
          Categoria initialCat = Categoria.compras;
          if (catName != null) {
            for (final c in Categoria.values) {
              if (c.name.toLowerCase() == catName.toLowerCase()) {
                initialCat = c;
                break;
              }
            }
          }
          return NewLimitScreen(initialCategory: initialCat);
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) =>
            CategoryDetailScreen(categoryId: state.pathParameters['id']!),
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
            path: '/plan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlanScreen(),
            ),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiScreen(),
            ),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (context, state) => NoTransitionPage(
              // /expenses?focus=1 (la lupa de Inicio) abre con el teclado listo.
              child: ExpensesScreen(
                autofocusSearch: state.uri.queryParameters['focus'] == '1',
              ),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
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
    
    // Bottom navigation selection index mapping (MgTabBar 5 tabs)
    int selectedIndex = 0;
    if (location.startsWith('/dashboard')) {
      selectedIndex = 0;
    } else if (location.startsWith('/plan')) {
      selectedIndex = 1;
    } else if (location.startsWith('/ai')) {
      selectedIndex = 2;
    } else if (location.startsWith('/reports')) {
      selectedIndex = 3;
    } else if (location.startsWith('/expenses')) {
      selectedIndex = 4;
    }

    final landscape = context.isLandscapePhone;
    // Con el teclado abierto (escribiendo) la barra de navegación se oculta; vuelve al cerrarlo.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: Stack(
        children: [
          OverlayTimerWidget(
            child: child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // En horizontal la barra es baja, centrada y respeta los bordes del
            // teléfono (notch, Dynamic Island y barra inferior).
            child: IgnorePointer(
              ignoring: keyboardOpen,
              child: AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              offset: keyboardOpen ? const Offset(0, 1.4) : Offset.zero,
              child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: keyboardOpen ? 0 : 1,
              child: SafeArea(
              top: false,
              // En vertical la barra conserva su posición de siempre.
              bottom: landscape,
              left: landscape,
              right: landscape,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: landscape ? landscapeTabBarMaxWidth : double.infinity,
                  ),
                  child: MgTabBar(
                    compact: landscape,
                    selectedIndex: selectedIndex,
                    onTap: (index) {
                      if (index == 0) {
                        context.go('/dashboard');
                      } else if (index == 1) {
                        context.go('/plan');
                      } else if (index == 2) {
                        context.go('/ai');
                      } else if (index == 3) {
                        context.go('/reports');
                      } else if (index == 4) {
                        context.go('/expenses');
                      }
                    },
                    onAddTap: () {
                      RegisterSheet.show(
                        context: context,
                        onSelectExpense: () => context.push('/new'),
                        onSelectIncome: () => context.push('/new?type=ingreso'),
                      );
                    },
                  ),
                ),
              ),
            ),
            ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
