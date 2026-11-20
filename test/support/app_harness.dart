import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/main.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base en memoria: la prueba no debe depender de archivos ni del Keychain.
class MemoryDb implements LocalDatabase {
  final _items = <String, Movimiento>{};

  @override
  Future<void> init() async {}

  @override
  Future<List<Movimiento>> getExpenses() async => _items.values.toList();

  @override
  Future<void> saveExpense(Movimiento expense) async => _items[expense.id] = expense;

  @override
  Future<void> deleteExpense(String id) async => _items.remove(id);
}

  /// Arranca la app ya con sesión iniciada, espera al Inicio y corre [body].
  /// Sin red, google_fonts no puede bajar las variantes de Inter y lanza errores
  /// asíncronos que no tienen que ver con la pantalla: se ignoran solo esos.
  Future<void> withHome(WidgetTester tester, Future<void> Function() body) async {
    // Tamaño de un teléfono en vertical (el predeterminado de las pruebas es 800×600).
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final done = Completer<void>();
    runZonedGuarded(() async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.example.mi_gasto/accessibility'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isAccessibilityServiceEnabled') return false;
          if (methodCall.method == 'isOverlayPermissionGranted') return false;
          return null;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') return '.';
          return null;
        },
      );

      // Usuario que ya vio la bienvenida e inició sesión: el arranque lo lleva al Inicio.
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'is_logged_in': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(MemoryDb()),
          ],
          child: MyApp(themeOverride: ThemeData(brightness: Brightness.dark)),
        ),
      );

      // La pantalla de arranque anima y luego navega al Inicio.
      for (var i = 0; i < 60 && find.text('Balance disponible').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await body();
      done.complete();
    }, (error, stack) {
      if (error.toString().contains('GoogleFonts')) return;
      if (!done.isCompleted) done.completeError(error, stack);
    });
    await done.future;
  }
