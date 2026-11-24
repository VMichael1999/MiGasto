import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/presentation/permissions/reading_disclosure.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePermissions extends PermissionsChecker {
  _FakePermissions() : super(const MethodChannel('test/permissions'));
  final calls = <String>[];

  @override
  Future<void> openNotificationListenerSettings() async => calls.add('notificaciones');
  @override
  Future<void> openAccessibilitySettings() async => calls.add('pantalla');
}

/// El aviso destacado que pide Google Play antes de activar cada lectura.
void main() {
  late _FakePermissions permissions;
  late SharedPreferences prefs;

  Future<void> pumpButton(WidgetTester tester, ReadingKind kind) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    permissions = _FakePermissions();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        permissionsCheckerProvider.overrideWithValue(permissions),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openReadingWithDisclosure(context, ref, kind),
                child: const Text('Activar'),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('la lectura de pantalla explica qué lee antes de abrir los ajustes', (tester) async {
    await pumpButton(tester, ReadingKind.pantalla);
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(find.text('MiGasto leerá la pantalla de tus apps de pago'), findsOneWidget);
    expect(find.textContaining('No es una herramienta de accesibilidad'), findsOneWidget);
    expect(permissions.calls, isEmpty);

    await tester.tap(find.text('Aceptar y activar'));
    await tester.pumpAndSettle();
    expect(permissions.calls, ['pantalla']);
    expect(prefs.getBool(consentKey(ReadingKind.pantalla)), isTrue);
  });

  testWidgets('«Ahora no» no abre nada ni guarda el consentimiento', (tester) async {
    await pumpButton(tester, ReadingKind.notificaciones);
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(permissions.calls, isEmpty);
    expect(prefs.getBool(consentKey(ReadingKind.notificaciones)), isNull);
  });

  testWidgets('aceptado una vez, la próxima va directo a los ajustes', (tester) async {
    await pumpButton(tester, ReadingKind.notificaciones);
    await prefs.setBool(consentKey(ReadingKind.notificaciones), true);
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(find.text('MiGasto leerá tus avisos de pago'), findsNothing);
    expect(permissions.calls, ['notificaciones']);
  });
}
