import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_gasto/core/navigation/navigation.dart';
import 'package:mi_gasto/presentation/onboarding/permissions_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Permisos simulados: no se toca el sistema, solo se registra qué se pidió.
class _FakePermissions extends PermissionsChecker {
  _FakePermissions({
    this.listener = false,
    this.overlay = false,
    this.alerts = false,
    this.battery = false,
  }) : super(const MethodChannel('test/permissions'));

  bool listener, overlay, alerts, battery;
  final calls = <String>[];

  @override
  Future<bool> isNotificationListenerEnabled() async => listener;
  @override
  Future<bool> isOverlayGranted() async => overlay;
  @override
  Future<bool> isPostNotificationsGranted() async => alerts;
  @override
  Future<bool> isBatteryUnrestricted() async => battery;

  @override
  Future<void> openNotificationListenerSettings() async => calls.add('lectura');
  @override
  Future<void> requestOverlayPermission() async => calls.add('ventana');
  @override
  Future<void> requestPostNotifications() async => calls.add('avisos');
  @override
  Future<void> openBatterySettings() async => calls.add('bateria');
}

void main() {
  late SharedPreferences prefs;

  /// La plataforma simulada se restablece antes de que termine la prueba:
  /// Flutter exige las variables de depuración sin tocar al final.
  void androidTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Future<void> open(WidgetTester tester, _FakePermissions fake) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(initialLocation: '/permisos', routes: [
      GoRoute(path: '/permisos', builder: (_, _) => const PermissionsScreen()),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('pantalla login'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionsCheckerProvider.overrideWithValue(fake),
      ],
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  androidTest('explica qué lee la app y muestra los cuatro pasos', (tester) async {
    await open(tester, _FakePermissions());

    expect(find.text('Qué lee la app y qué no'), findsOneWidget);
    expect(find.textContaining('No lee:', findRichText: true), findsOneWidget);
    expect(find.text('Activa la lectura de pagos'), findsOneWidget);
    expect(find.text('Permite la ventana flotante'), findsOneWidget);
    expect(find.text('Recibe un aviso de cada pago'), findsOneWidget);
    expect(find.text('Evita que el teléfono la duerma'), findsOneWidget);
    expect(find.text('Usar solo registro manual'), findsOneWidget);
  });

  androidTest('el botón principal pide los permisos en orden', (tester) async {
    final fake = _FakePermissions();
    await open(tester, fake);

    expect(find.text('Aceptar y activar la lectura'), findsOneWidget);
    await tester.tap(find.text('Aceptar y activar la lectura'));
    await tester.pump();
    expect(fake.calls, ['lectura']);

    // Al volver de los ajustes con la lectura activada, sigue la ventana flotante.
    fake.listener = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Permitir la ventana flotante'), findsOneWidget);
    expect(find.text('Terminar después'), findsOneWidget);
  });

  androidTest('usar solo registro manual completa la bienvenida y sigue al login', (tester) async {
    await open(tester, _FakePermissions());

    await tester.tap(find.text('Usar solo registro manual'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.text('pantalla login'), findsOneWidget);
  });

  androidTest('con todo concedido el botón dice Empezar y entra', (tester) async {
    await open(
      tester,
      _FakePermissions(listener: true, overlay: true, alerts: true, battery: true),
    );

    expect(find.text('Empezar'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.text('pantalla login'), findsOneWidget);
  });

  androidTest('sin completar la bienvenida, el router deja entrar a permisos y no manda al login', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      permissionsCheckerProvider.overrideWithValue(_FakePermissions()),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    ));
    router.go('/permisos');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Qué lee la app y qué no'), findsOneWidget);
    // Cualquier otra ruta sin bienvenida completa vuelve al onboarding.
    expect(router.routerDelegate.currentConfiguration.uri.path, '/permisos');
  });
}
