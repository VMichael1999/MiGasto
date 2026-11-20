import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/data/services/auth_service.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/settings/settings_screen.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuth implements AuthService {
  int signOuts = 0;
  @override
  AuthAccount? get current => null;
  @override
  Future<AuthAccount> signInWithGoogle() async =>
      const AuthAccount(uid: 'u1', email: 'ana@correo.com', name: 'Ana Pérez');
  @override
  Future<AuthAccount> signInWithApple() async => throw const AuthException('x', cancelled: true);
  @override
  Future<AuthAccount> signInWithEmail(String email, String password) async =>
      AuthAccount(uid: 'u2', email: email);
  @override
  Future<AuthAccount> createWithEmail(String email, String password) async =>
      AuthAccount(uid: 'u3', email: email);
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('el invitado vincula su cuenta desde el perfil y conserva sus datos', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'is_logged_in': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(FakeAuth()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const SettingsScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(isGuestProvider), isTrue);
    await tester.tap(find.text('Vincular cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Usar correo y contraseña'), findsOneWidget);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(container.read(isGuestProvider), isFalse);
    expect(prefs.getString('auth_uid'), 'u1');
    expect(container.read(profileEmailProvider), 'ana@correo.com');
    expect(container.read(profileNameProvider), 'Ana Pérez');
    // Ya no se ofrece vincular.
    expect(find.text('Vincular cuenta'), findsNothing);
  });
}
