import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_harness.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_gasto/main.dart';
import 'package:mi_gasto/presentation/providers.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('Continuar como invitado entra a la app y deja el modo guardado', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localDatabaseProvider.overrideWithValue(MemoryDb()),
      ],
      child: MyApp(themeOverride: ThemeData(brightness: Brightness.dark)),
    ));
    for (var i = 0; i < 60 && find.text('Continuar como invitado').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(find.text('Continuar como invitado'));
    await tester.tap(find.text('Continuar como invitado'));
    for (var i = 0; i < 60 && find.text('Balance disponible').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Balance disponible'), findsOneWidget);
    expect(prefs.getBool('is_logged_in'), isTrue);
    expect(prefs.getString(authModeKey), 'guest');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
