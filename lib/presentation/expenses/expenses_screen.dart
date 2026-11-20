import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/category_display.dart';
import '../../shared/csv_export.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../providers.dart';
import 'expense_detail_dialog.dart';
import '../../core/layout/adaptive.dart';
import '../../core/layout/landscape_pane.dart';

enum _MovementFilter { todo, gastos, ingresos, pendientes }

/// Pantalla 2: Movimientos / Historial y Búsqueda (`#s-buscar` en prototipo HTML y Sección 4.10 del prompt).
/// - Campo de búsqueda estilizado (alto 48, radio 15, fondo `soft`, ícono lupa).
/// - Selector segmentado: Todo / Gastos / Ingresos (y Por confirmar si hay pendientes).
/// - Resumen de resultados: cantidad de movimientos y monto consolidado.
/// - Lista agrupada por día con totales por día.
/// - Deslizamiento a la izquierda para borrar (`SwipeToDelete`) con confirmación (`ConfirmSheet`) y deshacer (`MgToast`).
/// - Pulsación prolongada (`LongPressMenu`) con menú contextual.
/// - Estado vacío propio con ícono suave, título y sugerencias.
/// - Opciones avanzadas: filtro por categoría/fuente/rango, exportación a CSV y borrado masivo.
/// - Botón flotante (`MgFab`) que abre `RegisterSheet`.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key, this.autofocusSearch = false});

  /// Abre la pantalla con el cursor en el buscador (lupa de Inicio).
  final bool autofocusSearch;

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _MovementFilter _filter = _MovementFilter.todo;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _filterCategory;
  PaymentSource? _filterSource;
  RangeValues? _filterAmountRange;

  int get _extraFiltersCount =>
      (_filterCategory != null ? 1 : 0) +
      (_filterSource != null ? 1 : 0) +
      (_filterAmountRange != null ? 1 : 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isRecurring(Movimiento m) {
    final note = m.notes.toLowerCase();
    return note.contains('recurrente') ||
        note.contains('subs') ||
        m.category == Categoria.entretenimiento;
  }

  String _formatDayLabel(DateTime date, DateTime now) {
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoy';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ayer';
    }
    return toBeginningOfSentenceCase(DateFormat('d MMMM', 'es').format(date))!;
  }

  List<Movimiento> _filterList(List<Movimiento> all, Map<String, String> aliases) {
    final q = _searchQuery.trim().toLowerCase();

    return all.where((m) {
      // Filtro de tipo
      switch (_filter) {
        case _MovementFilter.todo:
          break;
        case _MovementFilter.gastos:
          if (!m.esGasto) return false;
        case _MovementFilter.ingresos:
          if (!m.esIngreso) return false;
        case _MovementFilter.pendientes:
          if (m.estado != EstadoMovimiento.pendiente) return false;
      }

      // Filtro de búsqueda por texto (nombre, alias, categoría, notas o monto)
      if (q.isNotEmpty) {
        final catName = categoryLabel(m.category).toLowerCase();
        final name = m.merchant.toLowerCase();
        final alias = displayName(m.merchant, aliases).toLowerCase();
        final note = m.notes.toLowerCase();
        final amt = m.amount.toStringAsFixed(2);
        if (!name.contains(q) &&
            !alias.contains(q) &&
            !catName.contains(q) &&
            !note.contains(q) &&
            !amt.contains(q)) {
          return false;
        }
      }

      // Filtros avanzados
      if (_filterCategory != null &&
          categoryKey(m, ref.read(customCategoriesProvider)) != _filterCategory) {
        return false;
      }
      if (_filterSource != null && m.source != _filterSource) {
        return false;
      }
      final range = _filterAmountRange;
      if (range != null && (m.amount < range.start || m.amount > range.end)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(expensesStateProvider);
    final aliases = ref.watch(aliasesProvider);
    final hidden = ref.watch(balanceHiddenProvider);

    final pendingCount =
        allExpenses.where((m) => m.estado == EstadoMovimiento.pendiente).length;
    final results = _filterList(allExpenses, aliases);

    // Suma consolidada de los movimientos visibles
    final totalAmount = results.fold<double>(
      0.0,
      (sum, m) => sum + (m.esIngreso ? m.amount : -m.amount),
    );

    // Agrupación por día
    final grouped = <String, List<Movimiento>>{};
    for (final m in results) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();

    final searchPanel = Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Column(
                    children: [
                      // Barra de búsqueda (.srch)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: MgColors.soft,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 19,
                                    color: MgColors.ink2,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: widget.autofocusSearch,
                                      onChanged: (val) =>
                                          setState(() => _searchQuery = val),
                                      style: const TextStyle(
                                        fontFamily: AppText.fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: MgColors.ink,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Buscar por nombre, categoría o nota',
                                        hintStyle: TextStyle(
                                          fontFamily: AppText.fontFamily,
                                          fontSize: 13.5,
                                          color: MgColors.ink3,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: MgColors.ink3,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón de filtros avanzados (.rnd)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showFilterSheet(context),
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _extraFiltersCount > 0
                                      ? MgColors.accSoft
                                      : MgColors.soft,
                                  borderRadius: BorderRadius.circular(15),
                                  border: _extraFiltersCount > 0
                                      ? Border.all(color: MgColors.accLine, width: 1)
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 19,
                                    color: _extraFiltersCount > 0
                                        ? MgColors.acc2
                                        : MgColors.ink2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Menú de opciones (Exportar CSV, etc.)
                          _buildMoreMenu(context),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Segmented Buttons (.segs)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: MgColors.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentItem('Todo', _MovementFilter.todo),
                            _buildSegmentItem('Gastos', _MovementFilter.gastos),
                            _buildSegmentItem('Ingresos', _MovementFilter.ingresos),
                            if (pendingCount > 0)
                              _buildSegmentItem(
                                'Por confirmar ($pendingCount)',
                                _MovementFilter.pendientes,
                                isAlert: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
    final summary = Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${results.length} movimiento${results.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontFamily: AppText.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MgColors.ink,
                        ),
                      ),
                      if (results.isNotEmpty)
                        Text(
                          hidden
                              ? '••••'
                              : (totalAmount >= 0
                                  ? '+${formatSoles(totalAmount)}'
                                  : '−${formatSoles(totalAmount.abs())}'),
                          style: AppText.money(
                            size: 13,
                            weight: FontWeight.w700,
                            color: totalAmount >= 0 ? MgColors.up : MgColors.ink2,
                          ),
                        ),
                    ],
                  ),
                );
    final listArea = Expanded(
                  child: results.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.only(bottom: context.tabBarClearance(120)),
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final key = sortedKeys[index];
                            final dayList = grouped[key]!;
                            final dayDate = dayList.first.date;
                            final dayTotal = dayList.fold<double>(
                              0.0,
                              (sum, m) =>
                                  sum + (m.esIngreso ? m.amount : -m.amount),
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cabecera del día (.day)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDayLabel(dayDate, now),
                                        style: const TextStyle(
                                          fontFamily: AppText.fontFamily,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: MgColors.ink2,
                                        ),
                                      ),
                                      Text(
                                        hidden
                                            ? '•••'
                                            : (dayTotal >= 0
                                                ? '+${formatSoles(dayTotal)}'
                                                : '−${formatSoles(dayTotal.abs())}'),
                                        style: const TextStyle(
                                          fontFamily: AppText.fontFamily,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: MgColors.ink2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Filas del día
                                for (final m in dayList) ...[
                                  SwipeToDelete(
                                    itemKey: ValueKey(m.id),
                                    confirmTitle: '¿Eliminar movimiento?',
                                    confirmMessage:
                                        'Se borrará «${displayName(m.merchant, aliases)}» de tu historial.',
                                    onDelete: () async {
                                      final deleted = m;
                                      await ref
                                          .read(expensesStateProvider.notifier)
                                          .deleteExpense(m.id);
                                      if (context.mounted) {
                                        MgToast.show(
                                          context,
                                          message: 'Movimiento eliminado',
                                          actionLabel: 'Deshacer',
                                          onAction: () {
                                            ref
                                                .read(expensesStateProvider.notifier)
                                                .restoreExpense(deleted);
                                          },
                                        );
                                      }
                                    },
                                    child: LongPressMenu(
                                      onAction: (action) async {
                                        switch (action) {
                                          case MgMenuAction.edit:
                                            context.push('/movement/${m.id}');
                                          case MgMenuAction.addToCommon:
                                            MgToast.show(
                                              context,
                                              message:
                                                  'Agregado a registros comunes',
                                            );
                                          case MgMenuAction.compare:
                                            MgToast.show(
                                              context,
                                              message:
                                                  'Comparando con periodos anteriores',
                                            );
                                          case MgMenuAction.delete:
                                            final ok = await ConfirmSheet.show(
                                              context,
                                              title: '¿Eliminar movimiento?',
                                              message:
                                                  'Se borrará «${displayName(m.merchant, aliases)}» de tu historial.',
                                              confirmLabel: 'Eliminar',
                                              isDestructive: true,
                                            );
                                            if (ok && context.mounted) {
                                              final deleted = m;
                                              await ref
                                                  .read(expensesStateProvider.notifier)
                                                  .deleteExpense(m.id);
                                              if (context.mounted) {
                                                MgToast.show(
                                                  context,
                                                  message: 'Movimiento eliminado',
                                                  actionLabel: 'Deshacer',
                                                  onAction: () {
                                                    ref
                                                        .read(expensesStateProvider.notifier)
                                                        .restoreExpense(deleted);
                                                  },
                                                );
                                              }
                                            }
                                        }
                                      },
                                      child: _MovementItemRow(
                                        movement: m,
                                        name: displayName(m.merchant, aliases),
                                        isRecurring: _isRecurring(m),
                                        hidden: hidden,
                                        onTap: () =>
                                            showExpenseDetailSheet(context, ref, m),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                );

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Teléfono girado: búsqueda, filtros y resumen a la izquierda y la
            // lista de movimientos a la derecha, para que la lista tenga alto.
            if (context.isLandscapePhone)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width * 0.42).clamp(280.0, 380.0),
                    child: BleedClip(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [searchPanel, summary],
                        ),
                      ),
                    ),
                  ),
                  listArea,
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [searchPanel, summary, listArea],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentItem(String title, _MovementFilter filter, {bool isAlert = false}) {
    final isSelected = _filter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? MgColors.acc : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isAlert ? MgColors.warn : MgColors.ink2),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _filter != _MovementFilter.todo ||
        _extraFiltersCount > 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MgColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.receipt_long_outlined,
                size: 28,
                color: MgColors.ink3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Nada con ese nombre' : 'Sin movimientos',
              style: const TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Prueba con «café», «Yape» o cambia el filtro de búsqueda.'
                  : 'Aún no registras gastos ni ingresos. Toca + para agregar el primero.',
              style: const TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 13,
                color: MgColors.ink2,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MgColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: MgColors.acc2,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _filter = _MovementFilter.todo;
                    _filterCategory = null;
                    _filterSource = null;
                    _filterAmountRange = null;
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      color: MgColors.card,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: MgColors.borderTenue, width: 1),
      ),
      onSelected: (value) {
        if (value == 'export_csv') {
          _exportToCsv(context);
        } else if (value == 'clear_all') {
          _showClearAllDialog(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'export_csv',
          child: Row(
            children: [
              Icon(Icons.download_rounded, size: 18, color: MgColors.ink2),
              SizedBox(width: 10),
              Text('Exportar a CSV', style: TextStyle(color: MgColors.ink)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear_all',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: MgColors.down),
              SizedBox(width: 10),
              Text('Eliminar todos los movimientos',
                  style: TextStyle(color: MgColors.down)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: MgColors.soft,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Icon(Icons.more_vert_rounded, size: 19, color: MgColors.ink2),
        ),
      ),
    );
  }

  void _exportToCsv(BuildContext context) {
    final csv = movimientosToCsv(ref.read(expensesStateProvider));
    Clipboard.setData(ClipboardData(text: csv)).then((_) {
      if (context.mounted) {
        MgToast.show(
          context,
          message: 'Movimientos copiados al portapapeles en formato CSV.',
        );
      }
    });
  }

  void _showClearAllDialog(BuildContext context) async {
    final ok = await ConfirmSheet.show(
      context,
      title: '¿Eliminar todos los movimientos?',
      message:
          'Se eliminarán todos tus gastos e ingresos guardados. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar todo',
      isDestructive: true,
    );
    if (ok && context.mounted) {
      final all = ref.read(expensesStateProvider);
      final notifier = ref.read(expensesStateProvider.notifier);
      for (final m in all) {
        await notifier.deleteExpense(m.id);
      }
      if (context.mounted) {
        MgToast.show(context, message: 'Se eliminaron todos los movimientos.');
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    String? tempCategory = _filterCategory;
    PaymentSource? tempSource = _filterSource;
    RangeValues tempRange = _filterAmountRange ?? const RangeValues(0, 1000);
    bool rangeActive = _filterAmountRange != null;
    final categories = Categoria.values.toList();
    final propias = ref.read(customCategoriesProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget section(String title) => Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink2,
                    ),
                  ),
                );

            return MgSheet(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filtros de movimientos',
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MgColors.ink,
                      ),
                    ),
                    section('Categoría'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Todas',
                          isSelected: tempCategory == null,
                          onTap: () => setSheetState(() => tempCategory = null),
                        ),
                        for (final cat in categories)
                          _FilterChip(
                            label: categoryLabel(cat),
                            isSelected: tempCategory == cat.name,
                            onTap: () =>
                                setSheetState(() => tempCategory = cat.name),
                          ),
                        for (final p in propias)
                          _FilterChip(
                            label: p.nombre,
                            isSelected: tempCategory == p.id,
                            onTap: () => setSheetState(() => tempCategory = p.id),
                          ),
                      ],
                    ),
                    section('Origen de pago'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Todos',
                          isSelected: tempSource == null,
                          onTap: () => setSheetState(() => tempSource = null),
                        ),
                        for (final src in PaymentSource.values)
                          _FilterChip(
                            label: sourceLabel(src),
                            isSelected: tempSource == src,
                            onTap: () => setSheetState(() => tempSource = src),
                          ),
                      ],
                    ),
                    section('Rango de monto'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rangeActive
                              ? 'S/ ${tempRange.start.toInt()} – S/ ${tempRange.end.toInt()}'
                              : 'Cualquier monto',
                          style: const TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 12.5,
                            color: MgColors.ink2,
                          ),
                        ),
                        if (rangeActive)
                          TextButton(
                            onPressed: () => setSheetState(() => rangeActive = false),
                            child: const Text('Restablecer',
                                style: TextStyle(fontSize: 12, color: MgColors.acc2)),
                          ),
                      ],
                    ),
                    RangeSlider(
                      values: tempRange,
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      activeColor: MgColors.acc,
                      inactiveColor: MgColors.soft,
                      onChanged: (vals) {
                        setSheetState(() {
                          tempRange = vals;
                          rangeActive = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: MgColors.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: MgColors.ink2,
                            ),
                            onPressed: () {
                              setState(() {
                                _filterCategory = null;
                                _filterSource = null;
                                _filterAmountRange = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MgColors.acc,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              setState(() {
                                _filterCategory = tempCategory;
                                _filterSource = tempSource;
                                _filterAmountRange =
                                    rangeActive ? tempRange : null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MgColors.accSoft : MgColors.soft,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: MgColors.accLine, width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppText.fontFamily,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? MgColors.acc2 : MgColors.ink,
          ),
        ),
      ),
    );
  }
}

class _MovementItemRow extends StatelessWidget {
  const _MovementItemRow({
    required this.movement,
    required this.name,
    required this.isRecurring,
    required this.hidden,
    required this.onTap,
  });

  final Movimiento movement;
  final String name;
  final bool isRecurring;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catName = categoryLabel(movement.category);
    final catColor = CategoryIcon.colorForCategory(movement.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              // Cuadrito redondeado de categoría (.ic)
              CategoryIcon(
                category: movement.category,
                size: 38,
                radius: 12,
              ),
              const SizedBox(width: 12),

              // Nombre y categoría (.mid)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppText.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.01 * 14,
                              color: MgColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: catColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      catName,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 11.5,
                        color: MgColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Monto (.amt)
              MoneyText(
                amount: movement.amount,
                isIncome: movement.esIngreso,
                isExpense: movement.esGasto,
                hidden: hidden,
                style: AppText.money(
                  size: 14.5,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
