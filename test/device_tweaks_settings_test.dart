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
  _FakePermissions({this.vendor, this.restricted = false, this.screen = true})
      : super(const MethodChannel('test/permissions'));
  final String? vendor;
  final bool restricted;
  final bool screen;
  final calls = <String>[];

  @override
  Future<bool> isNotificationListenerEnabled() async => true;
  @override
  Future<bool> isOverlayGranted() async => true;
  @override
  Future<bool> isPostNotificationsGranted() async => true;
  @override
  Future<bool> isBatteryUnrestricted() async => true;
  @override
  Future<bool> isAccessibilityEnabled() async => screen;
  @override
  Future<String?> autostartVendor() async => vendor;
  @override
  Future<bool> mayNeedRestrictedSettings() async => restricted;
  @override
  Future<void> openAutostartSettings() async => calls.add('inicio');
  @override
  Future<void> openAppDetails() async => calls.add('ficha');
}

void main() {
  Future<_FakePermissions> pump(WidgetTester tester, _FakePermissions permissions) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      permissionsCheckerProvider.overrideWithValue(permissions),
    ]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const SettingsScreen())]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    ));
    await tester.pump(const Duration(seconds: 1));
    return permissions;
  }

  testWidgets('en un Xiaomi aparece «Inicio automático» y abre la pantalla de la marca', (tester) async {
    final p = await pump(tester, _FakePermissions(vendor: 'xiaomi'));
    expect(find.text('Inicio automático'), findsOneWidget);
    expect(find.textContaining('Xiaomi, Redmi y POCO'), findsOneWidget);
    await tester.tap(find.text('Inicio automático'));
    await tester.pump();
    expect(p.calls, ['inicio']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('en un Samsung o un Pixel no aparece', (tester) async {
    await pump(tester, _FakePermissions());
    expect(find.text('Inicio automático'), findsNothing);
    expect(find.text('Permitir ajustes restringidos'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('instalada desde un archivo y con una lectura apagada, explica los ajustes restringidos', (tester) async {
    final p = await pump(tester, _FakePermissions(restricted: true, screen: false));
    expect(find.text('Permitir ajustes restringidos'), findsOneWidget);
    await tester.tap(find.text('Permitir ajustes restringidos'));
    await tester.pump();
    expect(p.calls, ['ficha']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('con las dos lecturas activas ya no hace falta', (tester) async {
    await pump(tester, _FakePermissions(restricted: true));
    expect(find.text('Permitir ajustes restringidos'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
