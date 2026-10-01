import '../domain/categoria_propia.dart';
import '../domain/entities/movimiento.dart';
import 'labels.dart';
import 'widgets/category_icon.dart';
import 'widgets/custom_icons.dart';

/// Nombre e ícono con que se ve una categoría.
class CategoryDisplay {
  const CategoryDisplay(this.label, this.glyph);
  final String label;
  final CategoryGlyph glyph;
}

/// Si [propiaId] es una categoría propia que todavía existe, se usa esa; si no (o si se
/// borró), la de siempre.
CategoryDisplay categoryDisplay(
  Categoria category,
  String? propiaId,
  List<CategoriaPropia> propias,
) {
  if (propiaId != null) {
    for (final p in propias) {
      if (p.id == propiaId) {
        return CategoryDisplay(p.nombre, CategoryGlyph.material(customIconFor(p.icono)));
      }
    }
  }
  return CategoryDisplay(categoryLabel(category), glyphFor(category));
}

/// Clave para agrupar y filtrar: la propia si existe, si no la de siempre.
String categoryKey(Movimiento m, List<CategoriaPropia> propias) =>
    m.categoriaPropia != null && propias.any((p) => p.id == m.categoriaPropia)
        ? m.categoriaPropia!
        : m.category.name;

/// Nombre e ícono de una clave de [categoryKey].
CategoryDisplay displayForKey(String key, List<CategoriaPropia> propias) {
  for (final p in propias) {
    if (p.id == key) return categoryDisplay(p.base, p.id, propias);
  }
  final category = Categoria.values.where((c) => c.name == key).firstOrNull ?? Categoria.otros;
  return categoryDisplay(category, null, propias);
}
