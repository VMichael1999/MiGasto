import 'entities/movimiento.dart';

/// Categoría que crea el usuario, con el ícono que elija.
///
/// Un movimiento con categoría propia guarda además su categoría de siempre
/// (Otros / Otros ingresos según el tipo), así los totales y las reglas
/// siguen funcionando aunque se borre la propia.
class CategoriaPropia {
  const CategoriaPropia({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.tipo,
  });

  final String id;
  final String nombre;

  /// Clave del ícono en `customCategoryIcons`.
  final String icono;
  final TipoMovimiento tipo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'icono': icono,
        'tipo': tipo.name,
      };

  /// `null` si el JSON no trae lo mínimo (se ignora esa categoría).
  static CategoriaPropia? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final nombre = raw['nombre'];
    final icono = raw['icono'];
    if (id is! String || id.isEmpty || nombre is! String || nombre.trim().isEmpty) {
      return null;
    }
    return CategoriaPropia(
      id: id,
      nombre: nombre.trim(),
      icono: icono is String ? icono : '',
      tipo: raw['tipo'] == TipoMovimiento.ingreso.name
          ? TipoMovimiento.ingreso
          : TipoMovimiento.gasto,
    );
  }

  /// La categoría de siempre que cuenta para los totales.
  Categoria get base =>
      tipo == TipoMovimiento.ingreso ? Categoria.otrosIngresos : Categoria.otros;
}

/// Lee una lista guardada; lo que no se entiende se ignora.
List<CategoriaPropia> categoriasPropiasDesdeJson(Object? raw) {
  if (raw is! List) return const [];
  return raw.map(CategoriaPropia.fromJson).whereType<CategoriaPropia>().toList();
}
