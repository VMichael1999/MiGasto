import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/backup_service.dart';
import 'package:mi_gasto/domain/aliases.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('alias', () {
    test('la clave ignora mayúsculas y espacios de más', () {
      expect(aliasKey('  MICHAEL   ANTHONY  Valdiviezo '), 'michael anthony valdiviezo');
      expect(aliasKey('Ñandú Pérez'), 'ñandú pérez');
    });

    test('se muestra el alias si existe y el original si no', () {
      final aliases = {'michael anthony valdiviezo maza': 'Michael'};
      expect(displayName('MICHAEL ANTHONY VALDIVIEZO MAZA', aliases), 'Michael');
      expect(displayName('Michael  Anthony Valdiviezo Maza', aliases), 'Michael');
      expect(displayName('Tambo Surco', aliases), 'Tambo Surco');
      expect(displayName('X', {'x': '  '}), 'X');
    });
  });

  group('alias en la app', () {
    late ProviderContainer container;
    late SharedPreferences prefs;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container.read(localDatabaseProvider).init();
      container.read(expensesStateProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() => container.dispose());

    test('guardar, cambiar y quitar un alias', () async {
      final aliases = container.read(aliasesProvider.notifier);
      await aliases.set('MICHAEL ANTHONY VALDIVIEZO MAZA', 'Michael');
      expect(container.read(aliasesProvider), {'michael anthony valdiviezo maza': 'Michael'});

      // Queda en la clave que lee el código nativo.
      final stored = jsonDecode(prefs.getString('migasto_aliases_v1')!) as Map<String, dynamic>;
      expect(stored['michael anthony valdiviezo maza'], 'Michael');

      await aliases.set('michael anthony valdiviezo maza', 'Mi yo');
      expect(container.read(aliasesProvider).values.single, 'Mi yo');

      // Un nombre vacío, o igual al original, lo quita.
      await aliases.set('MICHAEL ANTHONY VALDIVIEZO MAZA', '   ');
      expect(container.read(aliasesProvider), isEmpty);
      await aliases.set('Tambo', 'Tambo');
      expect(container.read(aliasesProvider), isEmpty);
    });

    test('el alias no cambia el movimiento guardado', () async {
      await container.read(expensesStateProvider.notifier).addManualMovimiento(
            tipo: TipoMovimiento.gasto,
            amount: 5,
            merchant: 'TAMBO SURCO',
            category: Categoria.alimentacion,
          );
      await container.read(aliasesProvider.notifier).set('TAMBO SURCO', 'Tambo');
      expect(container.read(expensesStateProvider).single.merchant, 'TAMBO SURCO');
    });

    test('el respaldo lleva los alias y restaurar no pisa los tuyos', () async {
      await container.read(aliasesProvider.notifier).set('Juan Perez', 'Juan');
      final notifier = container.read(expensesStateProvider.notifier);
      expect(notifier.contenidoDeRespaldo().alias, {'juan perez': 'Juan'});

      // Ida y vuelta por el archivo cifrado.
      const service = BackupService(iterations: 10000);
      final bytes = await service.encrypt(notifier.contenidoDeRespaldo(), 'una contraseña larga');
      final back = await service.decrypt(bytes, 'una contraseña larga');
      expect(back.alias, {'juan perez': 'Juan'});

      // Restaurar agrega los que faltan y respeta el tuyo si el nombre ya tenía alias.
      final contents = BackupContents(
        creado: DateTime.utc(2026, 10, 1),
        presupuesto: 1000,
        aprendidas: const {},
        movimientos: const [],
        alias: {'juan perez': 'Juanito', 'maria lopez': 'Mari'},
      );
      await notifier.restaurarRespaldo(contents);
      expect(container.read(aliasesProvider), {'juan perez': 'Juan', 'maria lopez': 'Mari'});
    });

    test('un respaldo hecho antes de los alias se sigue abriendo', () async {
      const service = BackupService(iterations: 10000);
      // Simula un respaldo viejo: sin el campo `alias`.
      final contents = BackupContents(
        creado: DateTime.utc(2026, 9, 1),
        presupuesto: 700,
        aprendidas: const {},
        movimientos: const [],
      );
      final bytes = await service.encrypt(contents, 'una contraseña larga');
      final back = await service.decrypt(bytes, 'una contraseña larga');
      expect(back.alias, isEmpty);
      expect(back.presupuesto, 700);
    });
  });
}
