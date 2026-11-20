import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/data/services/auth_service.dart';
import 'package:mi_gasto/main.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_harness.dart';

class _Auth implements AuthService {
  String? createdName;
  @override
  AuthAccount? get current => null;
  @override
  Future<AuthAccount> signInWithGoogle() async => const AuthAccount(uid: 'g');
  @override
  Future<AuthAccount> signInWithApple() async => const AuthAccount(uid: 'a');
  @override
  Future<AuthAccount> signInWithEmail(String e, String p) async => AuthAccount(uid: 's', email: e);
  @override
  Future<AuthAccount> createWithEmail(String e, String p, {String? name}) async {
    createdName = name;
    return AuthAccount(uid: 'new', email: e, name: name);
  }
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('Crear cuenta: valida, crea y entra a la app con el nombre en el perfil', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = _Auth();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localDatabaseProvider.overrideWithValue(MemoryDb()),
        authServiceProvider.overrideWithValue(auth),
      ],
      child: MyApp(themeOverride: ThemeData(brightness: Brightness.dark)),
    ));
    for (var i = 0; i < 60 && find.text('Crea tu cuenta').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(find.text('Crea tu cuenta'));
    await tester.tap(find.text('Crea tu cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsOneWidget);

    // Vacío: muestra los avisos y no crea nada.
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(find.text('Usa 6 o más caracteres.'), findsOneWidget);
    expect(auth.createdName, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Pérez');
    await tester.enterText(fields.at(1), 'ana@correo.com');
    await tester.enterText(fields.at(2), 'secreto1');
    await tester.enterText(fields.at(3), 'otra-cosa');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    await tester.enterText(fields.at(3), 'secreto1');
    await tester.tap(find.text('Crear cuenta'));
    for (var i = 0; i < 60 && find.text('Balance disponible').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Balance disponible'), findsOneWidget);
    expect(auth.createdName, 'Ana Pérez');
    expect(prefs.getString(authModeKey), 'account');
    expect(prefs.getString('profile_name'), 'Ana Pérez');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
