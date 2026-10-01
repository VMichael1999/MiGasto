import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/categoria_propia.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/widgets/custom_icons.dart';
import '../providers.dart';

/// Pide nombre e ícono y crea una categoría propia para [tipo]. Devuelve la categoría
/// creada (o la que ya existía con ese nombre), o `null` si se cancela.
Future<CategoriaPropia?> showNewCategorySheet(
  BuildContext context,
  WidgetRef ref,
  TipoMovimiento tipo,
) {
  return showModalBottomSheet<CategoriaPropia>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _NewCategorySheet(tipo: tipo),
  );
}

class _NewCategorySheet extends ConsumerStatefulWidget {
  const _NewCategorySheet({required this.tipo});

  final TipoMovimiento tipo;

  @override
  ConsumerState<_NewCategorySheet> createState() => _NewCategorySheetState();
}

class _NewCategorySheetState extends ConsumerState<_NewCategorySheet> {
  static const _maxName = 20;

  final _name = TextEditingController();
  String _icon = customCategoryIcons.keys.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _create() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final created = await ref
        .read(customCategoriesProvider.notifier)
        .add(_name.text, _icon, widget.tipo);
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final accent = widget.tipo == TipoMovimiento.ingreso ? colors.income : colors.brandInk;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 8, AppSpacing.xl, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nueva categoría', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.tipo == TipoMovimiento.ingreso
                ? 'Para tus ingresos. Elige el nombre y el ícono que quieras.'
                : 'Para tus gastos. Elige el nombre y el ícono que quieras.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: _maxName,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre', counterText: ''),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 12),
          Text('Ícono', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in customCategoryIcons.entries)
                    Semantics(
                      button: true,
                      selected: entry.key == _icon,
                      label: 'Ícono ${entry.key}',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        onTap: () => setState(() => _icon = entry.key),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: entry.key == _icon ? accent : Colors.transparent,
                              width: 1.6,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 24,
                            color: entry.key == _icon ? accent : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSave ? _create : null,
            child: const Text('Crear categoría'),
          ),
        ],
      ),
    );
  }
}
