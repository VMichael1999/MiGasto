import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mi_gasto/domain/categoria_propia.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/lock/lock_gate.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/shared/csv_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends LocalAuthentication {
  _FakeAuth(this.result);
  final bool result;
  int calls = 0;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    calls++;
    return result;
  }
}

void main() {
  group('Bloqueo', () {
    Future<(_FakeAuth, Widget)> app({required bool enabled, required bool authOk}) async {
      SharedPreferences.setMockInitialValues({'migasto_passcode_enabled': enabled});
      final prefs = await SharedPreferences.getInstance();
      final auth = _FakeAuth(authOk);
      return (
        auth,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localAuthProvider.overrideWithValue(auth),
          ],
          child: const MaterialApp(home: LockGate(child: Text('contenido'))),
        ),
      );
    }

    testWidgets('sin bloqueo activado no se pide nada', (tester) async {
      final (auth, widget) = await app(enabled: false, authOk: true);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.text('MiGasto está bloqueado'), findsNothing);
      expect(auth.calls, 0);
    });

    testWidgets('con bloqueo activado se pide el desbloqueo y se entra', (tester) async {
      final (auth, widget) = await app(enabled: true, authOk: true);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      expect(find.text('MiGasto está bloqueado'), findsNothing);
    });

    testWidgets('si falla la autenticación sigue bloqueado y se puede reintentar',
        (tester) async {
      final (auth, widget) = await app(enabled: true, authOk: false);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.text('MiGasto está bloqueado'), findsOneWidget);
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(auth.calls, 2);
      expect(find.text('MiGasto está bloqueado'), findsOneWidget);
    });
  });

  group('CSV', () {
    test('incluye tipo, canal y estado, y no la ubicación', () {
      final csv = movimientosToCsv([
        Movimiento(
          id: '1',
          amount: 25.5,
          merchant: 'Tambo "Miraflores"',
          category: Categoria.compras,
          source: PaymentSource.yape,
          date: DateTime(2026, 9, 27, 12, 41),
          tipo: TipoMovimiento.gasto,
          canal: CanalMovimiento.notificacion,
          estado: EstadoMovimiento.confirmado,
          latitud: -12.09,
          longitud: -77.03,
          lugar: 'Av. Arequipa 3120',
        ),
      ]);
      expect(csv, contains('ID,Tipo,Monto,Contraparte,Categoria,Fuente,Canal,Estado,Fecha,Notas'));
      expect(csv, contains('1,gasto,25.50,"Tambo ""Miraflores""",Compras,yape,notificacion,confirmado,'));
      expect(csv, isNot(contains('-12.09')));
      expect(csv, isNot(contains('Arequipa')));
    });

    test('muestra el nombre de la categoría propia, entre comillas si trae comas', () {
      const propia = CategoriaPropia(
        id: 'c1',
        nombre: 'Café, postres',
        icono: 'cafe',
        tipo: TipoMovimiento.gasto,
      );
      final csv = movimientosToCsv([
        Movimiento(
          id: '2',
          amount: 8,
          merchant: 'Lima Café',
          category: Categoria.otros,
          categoriaPropia: 'c1',
          source: PaymentSource.efectivo,
          date: DateTime(2026, 9, 27, 12, 41),
        ),
      ], categoriasPropias: const [propia]);
      expect(csv, contains('"Café, postres",efectivo'));
    });
  });
}
