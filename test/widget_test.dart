import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_gasto/main.dart';
import 'package:mi_gasto/presentation/providers.dart';

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

    // Verify Onboarding screen has loaded by finding the 'Comenzar' button
    expect(find.text('Comenzar'), findsOneWidget);

    // Tap the 'Comenzar' button to navigate to the Resumen/Dashboard
    await tester.tap(find.text('Comenzar'));
    
    // Process route transition frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify we are now on the 'Resumen' (Dashboard) screen
    expect(find.text('Resumen'), findsNWidgets(2));
  });
}
