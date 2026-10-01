import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/data/services/backup_service.dart';
import 'package:mi_gasto/domain/categoria_propia.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/shared/category_display.dart';
import 'package:mi_gasto/shared/widgets/custom_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movimiento _m({String? propia, Categoria category = Categoria.otros}) => Movimiento(
      id: 'm1',
      amount: 12,
      merchant: 'Peluquería',
      category: category,
      categoriaPropia: propia,
      source: PaymentSource.efectivo,
      date: DateTime(2026, 10, 1, 10),
      estado: EstadoMovimiento.confirmado,
    );

const _barberia = CategoriaPropia(
  id: 'c1',
  nombre: 'Barbería',
  icono: 'spa',
  tipo: TipoMovimiento.gasto,
);

void main() {
  group('Cómo se guarda la categoría', () {
    test('una de siempre se guarda con su nombre, como antes', () {
      expect(categoriaAlmacenada(Categoria.compras, null), 'compras');
      final r = leerCategoriaAlmacenada('compras', Categoria.otros);
      expect(r.categoria, Categoria.compras);
      expect(r.propia, isNull);
    });

    test('una propia va junto a su categoría de siempre', () {
      expect(categoriaAlmacenada(Categoria.otros, 'c1'), 'otros|c1');
      final r = leerCategoriaAlmacenada('otros|c1', Categoria.compras);
      expect(r.categoria, Categoria.otros);
      expect(r.propia, 'c1');
    });

    test('un nombre desconocido o vacío usa el de respaldo', () {
      expect(leerCategoriaAlmacenada('marte', Categoria.otros).categoria, Categoria.otros);
      expect(leerCategoriaAlmacenada(null, Categoria.venta).categoria, Categoria.venta);
      expect(leerCategoriaAlmacenada('otros|', Categoria.venta).propia, isNull);
    });
  });

  group('Movimiento', () {
    test('elegir una categoría de siempre quita la propia', () {
      final m = _m(propia: 'c1').copyWith(category: Categoria.compras);
      expect(m.categoriaPropia, isNull);
      expect(m.category, Categoria.compras);
    });

    test('elegir una propia la pone junto a su categoría de siempre', () {
      final m = _m().copyWith(category: Categoria.otros, categoriaPropia: 'c1');
      expect(m.categoriaPropia, 'c1');
    });

    test('cambiar otra cosa no toca la categoría propia', () {
      final m = _m(propia: 'c1').copyWith(estado: EstadoMovimiento.pendiente, notes: 'x');
      expect(m.categoriaPropia, 'c1');
    });
  });

  group('Qué se ve', () {
    test('una propia que existe muestra su nombre; si se borró, la de siempre', () {
      expect(categoryDisplay(Categoria.otros, 'c1', const [_barberia]).label, 'Barbería');
      expect(categoryDisplay(Categoria.otros, 'c1', const []).label, 'Otros');
      expect(categoryDisplay(Categoria.compras, null, const [_barberia]).label, 'Compras');
    });

    test('la clave de agrupar es la propia solo si existe', () {
      expect(categoryKey(_m(propia: 'c1'), const [_barberia]), 'c1');
      expect(categoryKey(_m(propia: 'c1'), const []), 'otros');
      expect(displayForKey('c1', const [_barberia]).label, 'Barbería');
      expect(displayForKey('compras', const [_barberia]).label, 'Compras');
    });

    test('un ícono desconocido cae en uno genérico', () {
      expect(customIconFor('no-existe'), isNotNull);
      expect(customCategoryIcons.keys, contains('spa'));
    });
  });

  group('Categorías propias guardadas', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    }

    test('crear la misma (mismo nombre y tipo) devuelve la existente', () async {
      final c = await container();
      addTearDown(c.dispose);
      final n = c.read(customCategoriesProvider.notifier);
      final a = await n.add('Barbería', 'spa', TipoMovimiento.gasto);
      final b = await n.add('  barbería ', 'cafe', TipoMovimiento.gasto);
      expect(b.id, a.id);
      expect(c.read(customCategoriesProvider), hasLength(1));
      // El mismo nombre en otro tipo sí es otra categoría.
      await n.add('Barbería', 'spa', TipoMovimiento.ingreso);
      expect(c.read(customCategoriesProvider), hasLength(2));
    });

    test('se guardan y se leen al abrir la app, y se pueden borrar', () async {
      final c = await container();
      addTearDown(c.dispose);
      final prefs = c.read(sharedPreferencesProvider);
      final creada = await c.read(customCategoriesProvider.notifier).add('Gym', 'gimnasio', TipoMovimiento.gasto);

      final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c2.dispose);
      expect(c2.read(customCategoriesProvider).single.nombre, 'Gym');

      await c2.read(customCategoriesProvider.notifier).remove(creada.id);
      expect(c2.read(customCategoriesProvider), isEmpty);
    });

    test('mezclar las de un respaldo no pisa las tuyas', () async {
      final c = await container();
      addTearDown(c.dispose);
      final n = c.read(customCategoriesProvider.notifier);
      final mia = await n.add('Gym', 'gimnasio', TipoMovimiento.gasto);
      await n.merge([
        CategoriaPropia(id: mia.id, nombre: 'Otro nombre', icono: 'spa', tipo: TipoMovimiento.gasto),
        _barberia,
      ]);
      final lista = c.read(customCategoriesProvider);
      expect(lista, hasLength(2));
      expect(lista.firstWhere((x) => x.id == mia.id).nombre, 'Gym');
    });

    test('datos dañados se ignoran', () {
      expect(categoriasPropiasDesdeJson('basura'), isEmpty);
      expect(categoriasPropiasDesdeJson([1, {'id': 'x'}, {'id': 'a', 'nombre': ' '}]), isEmpty);
    });
  });

  test('el respaldo conserva categorías propias y la elegida en cada movimiento', () async {
    const service = BackupService(iterations: 10000);
    final data = await service.encrypt(
      BackupContents(
        creado: DateTime.utc(2026, 10, 1),
        presupuesto: 0,
        aprendidas: const {},
        categoriasPropias: const [_barberia],
        movimientos: [_m(propia: 'c1')],
      ),
      'una contraseña larga',
    );
    final back = await service.decrypt(data, 'una contraseña larga');
    expect(back.categoriasPropias.single.nombre, 'Barbería');
    expect(back.categoriasPropias.single.icono, 'spa');
    expect(back.movimientos.single.categoriaPropia, 'c1');
  });

  test('la base de datos devuelve la categoría propia tal como se guardó', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseManager(prefs, executor: NativeDatabase.memory());
    await db.init();
    addTearDown(db.close);

    await db.saveExpense(_m(propia: 'c1'));
    await db.saveExpense(_m(category: Categoria.compras).copyWith(id: 'm2'));
    final list = await db.getExpenses();
    final propia = list.firstWhere((m) => m.id == 'm1');
    expect(propia.categoriaPropia, 'c1');
    expect(propia.category, Categoria.otros);
    final normal = list.firstWhere((m) => m.id == 'm2');
    expect(normal.categoriaPropia, isNull);
    expect(normal.category, Categoria.compras);
  });
}
