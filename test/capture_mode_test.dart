import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePermissions extends PermissionsChecker {
  _FakePermissions() : super(const MethodChannel('test/permissions'));
  int cleared = 0;

  @override
  Future<void> clearCaptureLog() async => cleared++;
  @override
  Future<String> readCaptureLog() async => '';
  @override
  Future<bool> isNotificationListenerEnabled() async => true;
  @override
  Future<bool> isOverlayGranted() async => true;
  @override
  Future<bool> isPostNotificationsGranted() async => true;
  @override
  Future<bool> isBatteryUnrestricted() async => true;
  @override
  Future<bool> isAccessibilityEnabled() async => true;
}

void main() {
  late SharedPreferences prefs;
  late _FakePermissions permissions;

  Future<ProviderContainer> open(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    permissions = _FakePermissions();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      permissionsCheckerProvider.overrideWithValue(permissions),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('viene apagado y al encenderlo lo lee el código nativo', () async {
    final container = await open({});
    expect(container.read(captureModeProvider), isFalse);
    await container.read(captureModeProvider.notifier).set(true);
    expect(container.read(captureModeProvider), isTrue);
    // Kotlin lo lee como «flutter.migasto_capture_mode» en FlutterSharedPreferences.
    expect(prefs.getBool('migasto_capture_mode'), isTrue);
    expect(permissions.cleared, 0);
  });

  test('al apagarlo se borra lo guardado', () async {
    final container = await open({'migasto_capture_mode': true});
    expect(container.read(captureModeProvider), isTrue);
    await container.read(captureModeProvider.notifier).set(false);
    expect(container.read(captureModeProvider), isFalse);
    expect(permissions.cleared, 1);
  });

  testWidgets('en Ajustes de Android se enciende y aparece «Compartir textos guardados»', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = await open({});
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const SettingsScreen())]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Modo captura'), findsOneWidget);
    expect(find.text('Compartir textos guardados'), findsNothing);
    final row = find.ancestor(of: find.text('Modo captura'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(captureModeProvider), isTrue);
    expect(find.text('Compartir textos guardados'), findsOneWidget);

    // Sin textos guardados todavía: avisa en lugar de compartir un archivo vacío.
    await tester.tap(find.text('Compartir textos guardados'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Aún no hay textos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    debugDefaultTargetPlatformOverride = null;
  });
}
