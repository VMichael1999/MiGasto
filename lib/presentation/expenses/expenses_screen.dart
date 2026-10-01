import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/csv_export.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/category_display.dart';
import '../../shared/widgets/movement_row.dart';
import '../providers.dart';
import 'expense_detail_dialog.dart';

enum _TypeFilter { all, expenses, income, pending }

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _TypeFilter _type = _TypeFilter.all;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  /// Clave de la categoría filtrada: nombre de la de siempre o id de la propia.
  String? _filterCategory;
  PaymentSource? _filterSource;
  RangeValues? _filterAmountRange;

  int get _activeFilters =>
      (_filterCategory != null ? 1 : 0) +
      (_filterSource != null ? 1 : 0) +
      (_filterAmountRange != null ? 1 : 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(expensesStateProvider);
    ref.watch(aliasesProvider); // para que la lista se redibuje si cambia un nombre
    final pendingCount =
        all.where((m) => m.estado == EstadoMovimiento.pendiente).length;
    final entries = _filtered(all);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 0),
              child: _isSearching ? _buildSearchField(context) : _buildHeader(context),
            ),
            const SizedBox(height: 12),
            _buildChips(context, pendingCount),
            const SizedBox(height: 12),
            Expanded(child: _buildList(context, entries)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Movimientos', style: theme.textTheme.headlineMedium),
        Row(
          children: [
            _IconButton(
              icon: AppIcons.search,
              label: 'Buscar',
              onTap: () => setState(() => _isSearching = true),
            ),
            const SizedBox(width: 8),
            _buildMoreMenu(context),
          ],
        ),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      onSelected: (value) {
        if (value == 'clear_all') {
          _showClearAllDialog(context);
        } else if (value == 'export_csv') {
          _exportToCsv(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'export_csv', child: Text('Exportar a CSV')),
        PopupMenuItem(value: 'clear_all', child: Text('Eliminar todos los movimientos')),
      ],
      child: Container(
        width: AppSizes.iconButton,
        height: AppSizes.iconButton,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        alignment: Alignment.center,
        child: AppIcon(AppIcons.more, color: scheme.onSurface),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: AppSizes.iconButton,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar comercio o persona',
          contentPadding: EdgeInsets.zero,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: AppIcon(AppIcons.search, color: scheme.onSurfaceVariant),
          ),
          suffixIcon: IconButton(
            tooltip: 'Cerrar búsqueda',
            onPressed: () => setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            }),
            icon: AppIcon(AppIcons.close, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- chips

  Widget _buildChips(BuildContext context, int pendingCount) {
    final colors = context.appColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _Chip(
            label: 'Todo',
            selected: _type == _TypeFilter.all,
            onTap: () => setState(() => _type = _TypeFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Gastos',
            selected: _type == _TypeFilter.expenses,
            onTap: () => setState(() => _type = _TypeFilter.expenses),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Ingresos',
            selected: _type == _TypeFilter.income,
            onTap: () => setState(() => _type = _TypeFilter.income),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: pendingCount > 0 ? 'Por confirmar · $pendingCount' : 'Por confirmar',
            selected: _type == _TypeFilter.pending,
            accent: colors.pendingReview,
            onTap: () => setState(() => _type = _TypeFilter.pending),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: _activeFilters > 0 ? 'Filtros · $_activeFilters' : 'Filtros',
            icon: AppIcons.filter,
            selected: _activeFilters > 0,
            onTap: () => _showFilterSheet(context),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ list

  List<Movimiento> _filtered(List<Movimiento> all) {
    final query = _searchQuery.trim().toLowerCase();
    var list = all.where((m) {
      switch (_type) {
        case _TypeFilter.all:
          break;
        case _TypeFilter.expenses:
          if (!m.esGasto) return false;
        case _TypeFilter.income:
          if (!m.esIngreso) return false;
        case _TypeFilter.pending:
          if (m.estado != EstadoMovimiento.pendiente) return false;
      }
      if (query.isNotEmpty &&
          !m.merchant.toLowerCase().contains(query) &&
          !displayName(m.merchant, ref.read(aliasesProvider)).toLowerCase().contains(query)) {
        return false;
      }
      if (_filterCategory != null &&
          categoryKey(m, ref.read(customCategoriesProvider)) != _filterCategory) {
        return false;
      }
      if (_filterSource != null && m.source != _filterSource) return false;
      final range = _filterAmountRange;
      if (range != null && (m.amount < range.start || m.amount > range.end)) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Widget _buildList(BuildContext context, List<Movimiento> entries) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      final filtering =
          _activeFilters > 0 || _searchQuery.isNotEmpty || _type != _TypeFilter.all;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filtering
                    ? 'No encontramos movimientos con esos filtros.'
                    : 'Aún no tienes movimientos. Toca + para agregar el primero.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (filtering) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _filterCategory = null;
                    _filterSource = null;
                    _filterAmountRange = null;
                    _searchQuery = '';
                    _searchController.clear();
                    _isSearching = false;
                    _type = _TypeFilter.all;
                  }),
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final groups = <DateTime, List<Movimiento>>{};
    for (final e in entries) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      groups.putIfAbsent(day, () => []).add(e);
    }
    final days = groups.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 18),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEntries = groups[day]!;
        final dayTotal = dayEntries
            .where((m) => m.esGasto && m.isConfirmed)
            .fold(0.0, (sum, m) => sum + m.amount);

        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dayLabel(day),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dayTotal > 0)
                      Text(
                        '${solesOrHidden(dayTotal, ref.watch(balanceHiddenProvider))} en gastos',
                        style: AppText.amount(theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < dayEntries.length; i++) ...[
                if (i > 0) Divider(color: theme.colorScheme.outline, height: 1),
                _buildRow(context, dayEntries[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, Movimiento m) {
    final colors = context.appColors;
    final timeFormat = DateFormat('HH:mm');
    final isPending = m.estado == EstadoMovimiento.pendiente;
    final notifier = ref.read(expensesStateProvider.notifier);

    return Dismissible(
      key: ValueKey(m.id),
      // Un movimiento pendiente también se confirma deslizando a la derecha.
      direction: isPending ? DismissDirection.horizontal : DismissDirection.endToStart,
      background: Container(
        color: colors.income,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppIcon(AppIcons.check, color: Theme.of(context).scaffoldBackgroundColor),
      ),
      secondaryBackground: Container(
        color: colors.budgetOver,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const AppIcon(AppIcons.trash, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await notifier.confirmMovimiento(m.id);
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        notifier.deleteExpense(m.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${m.esIngreso ? 'Ingreso' : 'Gasto'} de "${displayName(m.merchant, ref.read(aliasesProvider))}" eliminado',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () => notifier.restoreExpense(m),
              ),
            ),
          );
      },
      child: MovementRow(
        icon: categoryDisplay(m.category, m.categoriaPropia, ref.watch(customCategoriesProvider)).glyph,
        title: displayName(m.merchant, ref.watch(aliasesProvider)),
        amount: m.amount,
        sourceName: m.source.name,
        sourceLabel: sourceLabel(m.source),
        time: timeFormat.format(m.date),
        isIncome: m.esIngreso,
        isPending: isPending,
        onTap: () => showExpenseDetailSheet(context, ref, m),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekday = DateFormat('EEEE d', 'es').format(day);

    if (day == today) return 'Hoy, $weekday';
    if (day == yesterday) return 'Ayer, $weekday';
    return toBeginningOfSentenceCase(
        DateFormat("EEEE d 'de' MMMM", 'es').format(day));
  }

  // ---------------------------------------------------------------- dialogs

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar todos los movimientos'),
          content: const Text(
            'Se eliminarán todos tus gastos e ingresos guardados. Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.budgetOver,
              ),
              onPressed: () async {
                final all = ref.read(expensesStateProvider);
                final notifier = ref.read(expensesStateProvider.notifier);
                for (final m in all) {
                  await notifier.deleteExpense(m.id);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Se eliminaron todos los movimientos')),
                  );
                }
              },
              child: const Text('Eliminar todo'),
            ),
          ],
        );
      },
    );
  }

  void _exportToCsv(BuildContext context) {
    final csv = movimientosToCsv(ref.read(expensesStateProvider));
    Clipboard.setData(ClipboardData(text: csv)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimientos copiados al portapapeles')),
        );
      }
    });
  }

  void _showFilterSheet(BuildContext context) {
    String? tempCategory = _filterCategory;
    PaymentSource? tempSource = _filterSource;
    RangeValues tempRange = _filterAmountRange ?? const RangeValues(0, 500);
    bool rangeActive = _filterAmountRange != null;
    final categories = _type == _TypeFilter.income ? Categoria.ingresos : Categoria.gastos;
    final propias = ref.read(customCategoriesProvider).where((c) =>
        _type == _TypeFilter.income ? c.tipo == TipoMovimiento.ingreso : c.tipo == TipoMovimiento.gasto).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget section(String title) => Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                );

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Filtrar movimientos', style: theme.textTheme.titleLarge),
                    section('Categoría'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'Todas',
                          selected: tempCategory == null,
                          onTap: () => setSheetState(() => tempCategory = null),
                        ),
                        for (final cat in categories)
                          _Chip(
                            label: categoryLabel(cat),
                            selected: tempCategory == cat.name,
                            onTap: () => setSheetState(() => tempCategory = cat.name),
                          ),
                        for (final p in propias)
                          _Chip(
                            label: p.nombre,
                            selected: tempCategory == p.id,
                            onTap: () => setSheetState(() => tempCategory = p.id),
                          ),
                      ],
                    ),
                    section('Fuente'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'Todas',
                          selected: tempSource == null,
                          onTap: () => setSheetState(() => tempSource = null),
                        ),
                        for (final src in const [
                          PaymentSource.yape,
                          PaymentSource.plin,
                          PaymentSource.googlePay,
                          PaymentSource.tarjeta,
                          PaymentSource.efectivo,
                          PaymentSource.manual,
                        ])
                          _Chip(
                            label: sourceLabel(src),
                            selected: tempSource == src,
                            onTap: () => setSheetState(() => tempSource = src),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: section('Rango de monto')),
                        Text(
                          'S/ ${tempRange.start.toInt()} – S/ ${tempRange.end.toInt()}',
                          style: AppText.amount(theme.textTheme.bodySmall!),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: tempRange,
                      min: 0,
                      max: 500,
                      divisions: 50,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.outline,
                      labels: RangeLabels(
                        'S/ ${tempRange.start.toInt()}',
                        'S/ ${tempRange.end.toInt()}',
                      ),
                      onChanged: (values) => setSheetState(() {
                        tempRange = values;
                        rangeActive = true;
                      }),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _filterCategory = tempCategory;
                          _filterSource = tempSource;
                          _filterAmountRange = rangeActive ? tempRange : null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterCategory = null;
                          _filterSource = null;
                          _filterAmountRange = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Botón cuadrado de 44×44 del encabezado.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.field),
            onTap: onTap,
            child: SizedBox(
              width: AppSizes.iconButton,
              height: AppSizes.iconButton,
              child: Center(child: AppIcon(icon, color: scheme.onSurface)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de filtro: borde de 1.5, seleccionado en tinta sobre fondo.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppIcons? icon;

  /// Color de acento (p. ej. azul de "Por confirmar").
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final border = selected ? (accent ?? scheme.onSurface) : (accent ?? scheme.outline);
    final background = selected ? (accent ?? scheme.onSurface) : Colors.transparent;
    final foreground = selected
        ? theme.scaffoldBackgroundColor
        : (accent ?? scheme.onSurface);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    AppIcon(icon!, size: AppIconSize.small, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
