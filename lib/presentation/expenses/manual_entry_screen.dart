import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/category_icon.dart';
import 'new_category_sheet.dart';
import '../../shared/widgets/custom_icons.dart';
import '../providers.dart';

/// Registro manual de un gasto o un ingreso: para el efectivo y para lo que la
/// app no detecta solo.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key, this.initialType = TipoMovimiento.gasto});

  final TipoMovimiento initialType;

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  late TipoMovimiento _tipo = widget.initialType;
  String _raw = '';
  final _concept = TextEditingController();
  PaymentSource _source = PaymentSource.efectivo;
  late Categoria _category = _defaultCategory(widget.initialType);

  /// Categoría propia elegida (si hay una, [_category] es la de siempre para los totales).
  String? _propia;

  static const _sources = [
    PaymentSource.efectivo,
    PaymentSource.yape,
    PaymentSource.plin,
    PaymentSource.tarjeta,
    PaymentSource.otro,
  ];

  static Categoria _defaultCategory(TipoMovimiento tipo) =>
      tipo == TipoMovimiento.ingreso ? Categoria.otrosIngresos : Categoria.otros;

  bool get _isIncome => _tipo == TipoMovimiento.ingreso;

  double get _amount => double.tryParse(_raw.endsWith('.') ? '${_raw}0' : _raw) ?? 0;

  bool get _canSave => _amount > 0 && _concept.text.trim().isNotEmpty;

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- teclado

  void _press(String key) {
    setState(() {
      if (key == '<') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
        return;
      }
      if (key == '.') {
        if (_raw.contains('.')) return;
        _raw = _raw.isEmpty ? '0.' : '$_raw.';
        return;
      }
      final parts = _raw.split('.');
      if (parts.length == 2 && parts[1].length >= 2) return; // 2 decimales
      if (parts.length == 1 && parts[0].length >= 7) return; // hasta millones
      if (_raw == '0') {
        _raw = key;
      } else {
        _raw += key;
      }
    });
  }

  String get _display {
    if (_raw.isEmpty) return '0.00';
    if (_raw.contains('.')) return _raw;
    return formatAmount(double.parse(_raw));
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final messenger = ScaffoldMessenger.of(context);
    final isIncome = _isIncome;
    await ref.read(expensesStateProvider.notifier).addManualMovimiento(
          tipo: _tipo,
          amount: _amount,
          merchant: _concept.text.trim(),
          category: _category,
          categoriaPropia: _propia,
          source: _source,
        );
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(isIncome ? 'Ingreso guardado' : 'Gasto guardado')),
    );
  }

  Future<void> _pickSource() async {
    final picked = await showModalBottomSheet<PaymentSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              _isIncome ? 'Recibido por' : 'Pagado con',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final s in _sources)
              ListTile(
                minTileHeight: AppSizes.minTouch,
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.appColors.sourceColor(s.name),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(s == PaymentSource.otro ? 'Otro' : sourceLabel(s)),
                selected: s == _source,
                onTap: () => Navigator.pop(context, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _source = picked);
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final accent = _isIncome ? colors.income : scheme.onSurface;
    final now = DateFormat("'Hoy' HH:mm", 'es').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 12),
                    _typeSelector(context),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: _isIncome ? '+ S/ ' : 'S/ ',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: _display),
                          ]),
                          style: AppText.amount(theme.textTheme.displayLarge!.copyWith(
                            fontSize: 50,
                            letterSpacing: -1.5,
                            color: accent,
                          )),
                          semanticsLabel: 'Monto: $_display soles',
                        ),
                        Text(now, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _conceptField(context),
                    const SizedBox(height: 12),
                    _sourceField(context),
                    const SizedBox(height: 12),
                    _categoryGrid(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 12),
              child: Column(
                children: [
                  _keypad(context),
                  const SizedBox(height: 8),
                  _saveButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message: 'Cerrar',
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.field),
              onTap: () => context.pop(),
              child: SizedBox(
                width: AppSizes.iconButton,
                height: AppSizes.iconButton,
                child: Center(child: AppIcon(AppIcons.close, color: scheme.onSurface)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Nuevo movimiento',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: AppSizes.iconButton),
      ],
    );
  }

  Widget _typeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;

    Widget segment(String label, TipoMovimiento tipo) {
      final selected = _tipo == tipo;
      final color = !selected
          ? scheme.onSurfaceVariant
          : (tipo == TipoMovimiento.ingreso ? colors.income : scheme.onSurface);
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _tipo = tipo;
              _category = _defaultCategory(tipo);
              _propia = null;
            }),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch - 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.raised : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor == scheme.surface
            ? scheme.outline
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.field - 1),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          segment('Gasto', TipoMovimiento.gasto),
          segment('Ingreso', TipoMovimiento.ingreso),
        ],
      ),
    );
  }

  Widget _conceptField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: AppSizes.field,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.tag, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _concept,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: _isIncome ? 'De quién o por qué' : 'Comercio o detalle',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceField(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final label = _source == PaymentSource.otro ? 'Otro' : sourceLabel(_source);
    final prefix = _isIncome ? 'Recibido por ' : 'Pagado con ';

    return Semantics(
      button: true,
      label: '$prefix$label. Cambiar',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: _pickSource,
        child: Container(
          height: AppSizes.field,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.sourceColor(_source.name),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('$prefix$label', style: theme.textTheme.bodyLarge)),
              Text(
                'Cambiar',
                style: theme.textTheme.labelLarge!.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              AppIcon(AppIcons.chevron, size: AppIconSize.small, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final selectedColor = _isIncome ? colors.income : colors.brandInk;
    final categories = Categoria.paraTipo(_tipo);
    final propias =
        ref.watch(customCategoriesProvider).where((c) => c.tipo == _tipo).toList();

    Widget tile({
      required String label,
      required String shortLabel,
      required Widget Function(Color color) icon,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected ? selectedColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon(selected ? selectedColor : scheme.onSurfaceVariant),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      shortLabel,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.onSurface,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final cat in categories)
          tile(
            label: categoryLabel(cat),
            shortLabel: cat == Categoria.transferenciaRecibida
                ? 'Transferencia'
                : categoryLabel(cat),
            icon: (color) => AppIcon(categoryIcon(cat), color: color),
            selected: _propia == null && cat == _category,
            onTap: () => setState(() {
              _category = cat;
              _propia = null;
            }),
          ),
        for (final p in propias)
          tile(
            label: p.nombre,
            shortLabel: p.nombre,
            icon: (color) => Icon(customIconFor(p.icono), size: 22, color: color),
            selected: _propia == p.id,
            onTap: () => setState(() {
              _category = p.base;
              _propia = p.id;
            }),
          ),
        tile(
          label: 'Crear una categoría nueva',
          shortLabel: 'Nueva',
          icon: (color) => AppIcon(AppIcons.plus, color: color),
          selected: false,
          onTap: _createCategory,
        ),
      ],
    );
  }

  Future<void> _createCategory() async {
    final created = await showNewCategorySheet(context, ref, _tipo);
    if (created == null || !mounted) return;
    setState(() {
      _category = created.base;
      _propia = created.id;
    });
  }

  Widget _keypad(BuildContext context) {
    final theme = Theme.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '<'];
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 2.9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final k in keys)
          Semantics(
            button: true,
            label: k == '<' ? 'Borrar' : (k == '.' ? 'Punto decimal' : k),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _press(k),
              child: Center(
                child: k == '<'
                    ? AppIcon(AppIcons.backspace,
                        size: AppIconSize.large, color: theme.colorScheme.onSurface)
                    : Text(
                        k,
                        style: AppText.amount(theme.textTheme.titleLarge!.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _saveButton(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final fill = _isIncome ? colors.income : theme.colorScheme.primary;
    final onFill = _isIncome ? theme.scaffoldBackgroundColor : theme.colorScheme.onPrimary;
    final label = _isIncome ? 'Guardar ingreso' : 'Guardar gasto';

    return Semantics(
      button: true,
      enabled: _canSave,
      label: _canSave ? '$label, ${formatSoles(_amount)}' : '$label, completa monto y detalle',
      excludeSemantics: true,
      child: Opacity(
        opacity: _canSave ? 1 : 0.4,
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: _canSave ? _save : null,
            child: Container(
              height: AppSizes.primaryButton,
              alignment: Alignment.center,
              child: Text(
                _amount > 0 ? '$label · ${formatSoles(_amount)}' : label,
                style: theme.textTheme.titleLarge!.copyWith(color: onFill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
