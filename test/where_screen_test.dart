import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_gasto/core/config/env.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/data/services/location_service.dart';
import 'package:mi_gasto/presentation/expenses/where_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocation implements LocationService {
  _FakeLocation(this.result);
  final LocationResult result;
  int calls = 0;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<LocationResult> captureCurrent() async {
    calls++;
    return result;
  }

  @override
  Future<void> openAppSettings() async {}
}

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

  Future<_FakeLocation> openWith(WidgetTester tester, LocationResult result) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Env.setForTest(const {});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = _FakeLocation(result);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationServiceProvider.overrideWithValue(fake),
      ],
      child: MaterialApp(theme: AppTheme.darkTheme, home: const WhereScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    return fake;
  }

  testWidgets('el botón de mi ubicación pide la ubicación y avisa si no hay permiso', (tester) async {
    final fake = await openWith(tester, const LocationResult.failed(LocationFailure.denied));
    expect(find.byTooltip('Mi ubicación'), findsOneWidget);
    await tester.tap(find.byTooltip('Mi ubicación'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(fake.calls, 1);
    expect(find.textContaining('permiso de ubicación'), findsOneWidget);
  });

  testWidgets('con permiso, el botón toma la ubicación sin errores', (tester) async {
    final fake = await openWith(
      tester,
      const LocationResult.ok(CapturedLocation(latitude: -12.05, longitude: -77.04, accuracy: 8)),
    );
    await tester.tap(find.byTooltip('Mi ubicación'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(fake.calls, 1);
    expect(tester.takeException(), isNull);
  });
}
