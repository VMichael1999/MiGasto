import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/labels.dart';
import 'category_icon.dart';

/// Hoja modal para seleccionar categoría con "Frecuentes" en grilla y "Todas" en lista.
class CategorySheet extends StatelessWidget {
  const CategorySheet({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tipo = TipoMovimiento.gasto,
  });

  final Categoria? selected;
  final ValueChanged<Categoria> onSelected;
  final TipoMovimiento tipo;

  static Future<Categoria?> show(
    BuildContext context, {
    Categoria? selected,
    TipoMovimiento tipo = TipoMovimiento.gasto,
  }) {
    return showModalBottomSheet<Categoria>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CategorySheet(
        selected: selected,
        tipo: tipo,
        onSelected: (cat) => Navigator.pop(context, cat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = Categoria.paraTipo(tipo);
    final frecuentes = categories.take(4).toList();

    return Container(
      decoration: const BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      // Material propio: los ListTile pintan tinta y fondo sobre el Material más cercano.
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MgColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MgColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              // Frecuentes
              const Text(
                'Frecuentes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MgColors.ink2,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
                children: [
                  for (final cat in frecuentes)
                    _buildFrecuenteTile(cat),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Todas las categorías',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MgColors.ink2,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: MgColors.line,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isCurrent = cat == selected;
  
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CategoryIcon(category: cat, size: 36, iconSize: 18),
                      title: Text(
                        categoryLabel(cat),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrent ? MgColors.acc2 : MgColors.ink,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check, color: MgColors.acc, size: 20)
                          : null,
                      onTap: () => onSelected(cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrecuenteTile(Categoria cat) {
    final isCurrent = cat == selected;
    return Material(
      color: isCurrent ? MgColors.accSoft : MgColors.soft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelected(cat),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? MgColors.acc : Colors.transparent,
              width: 1.4,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcon(category: cat, size: 34, iconSize: 18),
              const SizedBox(height: 6),
              Text(
                categoryLabel(cat),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: isCurrent ? MgColors.acc2 : MgColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
