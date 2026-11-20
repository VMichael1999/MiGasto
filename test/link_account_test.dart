import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/data/services/auth_service.dart';
import 'package:mi_gasto/presentation/auth/account_link.dart';
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
  Future<AuthAccount> createWithEmail(String email, String password, {String? name}) async =>
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

  testWidgets('al cerrar la sesión de la cuenta, el perfil del invitado queda limpio', (tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuth();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(auth),
    ]);
    addTearDown(container.dispose);
    late WidgetRef captured;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        }),
      ),
    ));

    await applyAccount(captured, const AuthAccount(uid: 'u1', email: 'ana@correo.com', name: 'Ana'));
    expect(container.read(profileEmailProvider), 'ana@correo.com');
    expect(container.read(isGuestProvider), isFalse);

    await signOutAccount(captured);
    expect(container.read(profileEmailProvider), '');
    expect(container.read(profileNameProvider), '');
    expect(container.read(isGuestProvider), isTrue);
    expect(prefs.getString('auth_uid'), isNull);
    expect(auth.signOuts, 1);
  });

  testWidgets('lo que el usuario escribió en su perfil no se borra al cerrar sesión', (tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': true, 'profile_name': 'Luis'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(FakeAuth()),
    ]);
    addTearDown(container.dispose);
    late WidgetRef captured;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        }),
      ),
    ));
    await applyAccount(captured, const AuthAccount(uid: 'u1', email: 'luis@correo.com', name: 'Otro'));
    // El nombre ya existía: no se pisa. El correo vino de la cuenta.
    expect(container.read(profileNameProvider), 'Luis');
    await signOutAccount(captured);
    expect(container.read(profileNameProvider), 'Luis');
    expect(container.read(profileEmailProvider), '');
  });
}
