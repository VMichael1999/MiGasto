import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_gasto/core/config/env.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/expenses/where_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sin clave de mapas el aviso ocupa el ancho y no se parte letra por letra', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Env.setForTest(const {});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.darkTheme, home: const WhereScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final note = find.textContaining('El mapa no está disponible');
    expect(note, findsOneWidget);
    expect(tester.getSize(note).width, greaterThan(200));
    expect(find.textContaining('Dónde pagaste'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
