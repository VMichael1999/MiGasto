import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/plan/plan_providers.dart';
import 'package:mi_gasto/presentation/plan/plan_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('la meta de ahorro se crea desde la hoja y queda guardada', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);

    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const PlanScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Define tu meta de ahorro'), findsOneWidget);
    await tester.tap(find.text('Define tu meta de ahorro'));
    await tester.pumpAndSettle();

    expect(find.text('Meta de ahorro'), findsOneWidget);
    // La hoja queda dentro de la pantalla (no fuera de vista).
    final rect = tester.getRect(find.text('Guardar'));
    expect(rect.bottom, lessThanOrEqualTo(1000));
    await tester.enterText(find.widgetWithText(TextField, 'Nombre (ej. Viaje)'), 'Viaje');
    await tester.enterText(find.widgetWithText(TextField, 'Monto objetivo (S/)'), '2000');
    await tester.enterText(find.widgetWithText(TextField, 'Ahorrado hasta hoy (S/)'), '500');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final goal = container.read(savingsGoalProvider)!;
    expect(goal.title, 'Viaje');
    expect(goal.target, 2000);
    expect(goal.current, 500);
    expect(find.text('Viaje'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    // Persistida en el dispositivo.
    expect(prefs.getString('migasto_savings_goal'), contains('Viaje'));
  });
}
