import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/setup/apple_pay_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  Future<(ProviderContainer, SharedPreferences)> open(WidgetTester tester, {required bool paid}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    if (paid) {
      final m = Movimiento(
        id: 'w1',
        amount: 25.5,
        merchant: 'Tambo',
        category: Categoria.compras,
        source: PaymentSource.manual,
        date: DateTime.now().subtract(const Duration(minutes: 1)),
        tipo: TipoMovimiento.gasto,
        canal: CanalMovimiento.wallet,
        estado: EstadoMovimiento.confirmado,
      );
      await container.read(expenseRepositoryProvider).saveExpense(m);
      await container.read(expensesStateProvider.notifier).restoreExpense(m);
    }
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const ApplePaySetupScreen(fromOnboarding: true)),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('pantalla de login'))),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    return (container, prefs);
  }

  testWidgets('sin pagos: el botón principal abre Atajos y se puede dejar para después', (tester) async {
    await open(tester, paid: false);
    expect(find.text('Abrir Atajos'), findsOneWidget);
    expect(find.text('Lo hago después'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });

  testWidgets('con un pago de Wallet ya registrado: aparece Continuar y entra al login', (tester) async {
    final (_, prefs) = await open(tester, paid: true);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Lo hago después'), findsNothing);
    // Atajos sigue a mano como acción secundaria.
    expect(find.text('Abrir Atajos'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.text('pantalla de login'), findsOneWidget);
  });
}
