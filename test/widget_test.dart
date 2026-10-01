import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/main.dart';
import 'package:mi_gasto/presentation/providers.dart';

/// Base en memoria: la prueba no debe depender de archivos ni del Keychain.
class _MemoryDb implements LocalDatabase {
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

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('App loads dashboard correctly', (WidgetTester tester) async {
    // Stub native method channels
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.example.mi_gasto/accessibility'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'isAccessibilityServiceEnabled') {
          return false;
        }
        if (methodCall.method == 'isOverlayPermissionGranted') {
          return false;
        }
        return null;
      },
    );

    // Mock path provider to avoid native exceptions
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localDatabaseProvider.overrideWithValue(_MemoryDb()),
        ],
        child: MyApp(
          themeOverride: ThemeData(
            brightness: Brightness.dark,
            // Override with basic text theme to avoid Google Fonts errors
          ),
        ),
      ),
    );
    
    // Wait for async database init to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    // El onboarding muestra qué lee la app y deja usarla solo con registro manual
    expect(find.text('Qué lee la app y qué no'), findsOneWidget);
    expect(find.text('Usar solo registro manual'), findsOneWidget);

    // Sin dar permisos se puede entrar al Resumen
    await tester.tap(find.text('Usar solo registro manual'));
    
    // Process route transition frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify we are now on the 'Resumen' (Dashboard) screen: the rediseño no
    // tiene título 'Resumen' arriba, solo la etiqueta de la barra inferior.
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Te quedan de este mes'), findsOneWidget);
  });
}
