import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/expenses/expenses_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('el tema no pinta un marco de color al enfocar un campo', (tester) async {
    for (final theme in [AppTheme.darkTheme, AppTheme.lightTheme]) {
      final focused = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      final enabled = theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      expect(focused.borderSide.color, isNot(MgColors.acc));
      expect(focused.borderSide, enabled.borderSide);
    }
  });

  testWidgets('el buscador no se enmarca ni se rellena al enfocarlo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(expensesStateProvider.notifier);

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ExpensesScreen(autofocusSearch: true),
      ),
    ));
    await tester.pumpAndSettle();

    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Buscar por nombre, categoría o nota',
    );
    final decorator = tester.widget<InputDecorator>(
      find.descendant(of: field, matching: find.byType(InputDecorator)),
    );
    expect(decorator.isFocused, isTrue);
    // La decoración efectiva (con el tema aplicado) no tiene marcos ni relleno.
    final effective = decorator.decoration.applyDefaults(AppTheme.darkTheme.inputDecorationTheme);
    expect(effective.focusedBorder, InputBorder.none);
    expect(effective.enabledBorder, InputBorder.none);
    expect(effective.filled, isFalse);
  });
}
