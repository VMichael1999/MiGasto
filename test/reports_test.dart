import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/reports/reports_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('Reportes sin movimientos no muestra cifras inventadas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);

    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const ReportsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay gastos registrados este mes.'), findsOneWidget);
    expect(find.text('Aún no hay ingresos ni gastos registrados.'), findsOneWidget);
    expect(find.text('+324%'), findsNothing);
    expect(find.text('Martes'), findsNothing);
    // Sin gastos el mes anterior no hay con qué comparar.
    expect(find.text('—'), findsWidgets);
  });
}
