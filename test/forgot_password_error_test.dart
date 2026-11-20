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
  _Auth({this.fail});
  final String? fail;
  final sent = <String>[];
  @override
  AuthAccount? get current => null;
  @override
  Future<AuthAccount> signInWithGoogle() async => const AuthAccount(uid: 'g');
  @override
  Future<AuthAccount> signInWithApple() async => const AuthAccount(uid: 'a');
  @override
  Future<AuthAccount> signInWithEmail(String e, String p) async => AuthAccount(uid: 's', email: e);
  @override
  Future<AuthAccount> createWithEmail(String e, String p, {String? name}) async =>
      AuthAccount(uid: 'n', email: e);
  @override
  Future<void> sendPasswordReset(String email) async {
    if (fail != null) throw AuthException(fail!);
    sent.add(email);
  }

  @override
  Future<void> signOut() async {}
}

Future<void> _openForgot(WidgetTester tester, _Auth auth) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localDatabaseProvider.overrideWithValue(MemoryDb()),
      authServiceProvider.overrideWithValue(auth),
    ],
    child: MyApp(themeOverride: ThemeData(brightness: Brightness.dark)),
  ));
  for (var i = 0; i < 60 && find.text('¿Olvidaste tu contraseña?').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.enterText(find.byType(TextField).first, 'ana@correo.com');
  await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
  await tester.tap(find.text('¿Olvidaste tu contraseña?'));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('recuperar contraseña: valida el correo y muestra el error si falla el envío', (tester) async {
    final auth = _Auth(fail: 'Sin conexión. Revisa tu internet e intenta de nuevo.');
    await _openForgot(tester, auth);
    await tester.enterText(find.byType(TextField).first, 'no-es-correo');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(auth.sent, isEmpty);

    await tester.enterText(find.byType(TextField).first, 'ana@correo.com');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión. Revisa tu internet e intenta de nuevo.'), findsOneWidget);
    expect(find.text('Revisa tu correo'), findsNothing);
    await _close(tester);
  });
}
