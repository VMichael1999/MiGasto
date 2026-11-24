import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/layout/adaptive.dart';
import '../../core/layout/landscape_pane.dart';
import '../../core/navigation/close_or_home.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../providers.dart';
import '../plan/plan_providers.dart';

/// Pantalla 4: Nuevo gasto / ingreso (#s-nuevo / R.nuevo en migasto-prototipo.html)
/// - Cabecera (.nav): Botón atrás circular, título «Nuevo gasto» / «Nuevo ingreso».
/// - Monto (.amt-wrap): Selector de moneda «S/ v» y monto grande con micro-rebote al teclear.
/// - Chip de fecha (.datechip): Calendario y fecha seleccionada.
/// - Campo descripción (.field): Concepto / comercio opcional.
/// - Fila de categoría (.catrow): Ícono squircle, nombre de categoría y chevron que abre CategorySheet.
/// - Línea del límite (.limbar): El corazón de la pantalla. Muestra ProgressBar dinámico y texto
///   «Te quedarán S/ XX,XX después de este gasto» o en rojo «Te pasas S/ XX,XX del límite de [categoría]».
/// - Etiquetas (.tags): Chips interactivos (#cafe, #quincena, #casa, etc.) y botón para agregar etiqueta.
/// - Opciones auxiliares: Estado / Medio de pago y Agregar nota.
/// - Dock inferior (.nv-dock): Switch «Guardar y agregar otro» (MgToggle), teclado numérico (AmountKeypad) y botón primario «Guardar».
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key, this.initialType = TipoMovimiento.gasto});

  final TipoMovimiento initialType;

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  late final TipoMovimiento _tipo = widget.initialType;
  String _raw = '';
  final _concept = TextEditingController();
  PaymentSource _source = PaymentSource.efectivo;
  late Categoria _category = _defaultCategory(widget.initialType);
  String? _propia;

  DateTime _selectedDate = DateTime.now();
  final List<String> _tags = [];
  bool _guardarYOtro = false;
  String? _note;

  static const List<String> _suggestedTags = ['cafe', 'quincena', 'casa', 'almuerzo'];

  static const _sources = [
    PaymentSource.efectivo,
    PaymentSource.yape,
    PaymentSource.plin,
    PaymentSource.tarjeta,
    PaymentSource.otro,
  ];

  static Categoria _defaultCategory(TipoMovimiento tipo) =>
      tipo == TipoMovimiento.ingreso ? Categoria.otrosIngresos : Categoria.compras;

  bool get _isIncome => _tipo == TipoMovimiento.ingreso;

  double get _amount {
    if (_raw.isEmpty) return 0.0;
    final normalized = _raw.replaceAll(',', '.');
    return double.tryParse(normalized.endsWith('.') ? '${normalized}0' : normalized) ?? 0.0;
  }

  bool get _canSave => _amount > 0;

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- teclado

  void _press(String key) {
    setState(() {
      if (key == '<') {
        if (_raw.isNotEmpty) {
          _raw = _raw.substring(0, _raw.length - 1);
        }
        return;
      }
      if (key == ',' || key == '.') {
        if (_raw.contains(',') || _raw.contains('.')) return;
        _raw = _raw.isEmpty ? '0,' : '$_raw,';
        return;
      }
      final separator = _raw.contains(',') ? ',' : (_raw.contains('.') ? '.' : null);
      if (separator != null) {
        final parts = _raw.split(separator);
        if (parts.length == 2 && parts[1].length >= 2) return; // máximo 2 decimales
      } else {
        if (_raw.replaceAll(RegExp(r'\D'), '').length >= 7) return; // hasta millones
      }
      if (_raw == '0') {
        _raw = key;
      } else {
        _raw += key;
      }
    });
  }

  // ---------------------------------------------------------------- guardado

  Future<void> _save() async {
    if (!_canSave) return;
    final merchant = _concept.text.trim().isNotEmpty
        ? _concept.text.trim()
        : categoryLabel(_category);
    final amountToSave = _amount;
    final isIncome = _isIncome;

    await ref.read(expensesStateProvider.notifier).addManualMovimiento(
          tipo: _tipo,
          amount: amountToSave,
          merchant: merchant,
          category: _category,
          categoriaPropia: _propia,
          source: _source,
        );

    if (!mounted) return;

    final toastMsg = '${isIncome ? "Ingreso" : "Gasto"} de ${formatSoles(amountToSave)} guardado.';

    if (_guardarYOtro) {
      setState(() {
        _raw = '';
        _concept.clear();
        _tags.clear();
        _note = null;
      });
      MgToast.show(context, message: toastMsg);
    } else {
      closeOrHome(context);
      MgToast.show(context, message: toastMsg);
    }
  }

  // ---------------------------------------------------------------- hojas y selectores

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MgColors.acc,
              onPrimary: Colors.white,
              surface: MgColors.card,
              onSurface: MgColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickCategory() async {
    final picked = await CategorySheet.show(
      context,
      selected: _category,
      tipo: _tipo,
    );
    if (picked != null && mounted) {
      setState(() {
        _category = picked;
        _propia = null;
      });
    }
  }

  Future<void> _pickSource() async {
    final picked = await showAdaptiveSheet<PaymentSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: MgColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                _isIncome ? 'Recibido por' : 'Pagado con',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MgColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              for (final s in _sources)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s == PaymentSource.yape
                          ? const Color(0xFF742284)
                          : s == PaymentSource.plin
                              ? const Color(0xFF00BFA5)
                              : s == PaymentSource.tarjeta
                                  ? MgColors.acc
                                  : MgColors.up,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    sourceLabel(s),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: MgColors.ink,
                    ),
                  ),
                  trailing: s == _source
                      ? const Icon(Icons.check_rounded, color: MgColors.acc, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, s),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _source = picked);
    }
  }

  void _addTagPrompt() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MgColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nueva etiqueta', style: TextStyle(color: MgColors.ink, fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: MgColors.ink),
          cursorColor: MgColors.acc,
          decoration: const InputDecoration(
            hintText: 'ej. vacaciones, almuerzo',
            hintStyle: TextStyle(color: MgColors.ink3),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MgColors.line)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MgColors.acc)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: MgColors.ink2)),
          ),
          TextButton(
            onPressed: () {
              final tag = textController.text.trim().replaceAll('#', '');
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Agregar', style: TextStyle(color: MgColors.acc, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _addNotePrompt() {
    final textController = TextEditingController(text: _note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MgColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nota del movimiento', style: TextStyle(color: MgColors.ink, fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textController,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: MgColors.ink),
          cursorColor: MgColors.acc,
          decoration: const InputDecoration(
            hintText: 'Escribe cualquier detalle adicional...',
            hintStyle: TextStyle(color: MgColors.ink3),
            border: OutlineInputBorder(borderSide: BorderSide(color: MgColors.line)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: MgColors.acc)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: MgColors.ink2)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _note = textController.text.trim().isEmpty ? null : textController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: MgColors.acc, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // Teléfono girado: el formulario a la izquierda y el teclado con el botón
    // Guardar a la derecha, para que ambos quepan sin tapar el monto.
    if (context.isLandscapePhone) {
      return Scaffold(
        backgroundColor: MgColors.bg,
        body: SafeArea(
          child: Row(
            children: [
              LandscapePane(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _buildNav(context),
                  _buildAmountWrap(context),
                  _buildDateChip(context),
                  _buildDescriptionField(context),
                  _buildCategoryRow(context),
                  if (!_isIncome) _buildLimitBar(context),
                  _buildTagsRow(context),
                  _buildAuxiliaryRow(context),
                ],
              ),
              SizedBox(
                width: (MediaQuery.sizeOf(context).width * 0.4).clamp(300.0, 400.0),
                child: BleedClip(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    physics: const BouncingScrollPhysics(),
                    child: _buildDock(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Área de scroll superior
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNav(context),
                    _buildAmountWrap(context),
                    _buildDateChip(context),
                    _buildDescriptionField(context),
                    _buildCategoryRow(context),
                    if (!_isIncome) _buildLimitBar(context),
                    _buildTagsRow(context),
                    _buildAuxiliaryRow(context),
                  ],
                ),
              ),
            ),
            // Dock inferior fijo con interruptor, teclado numérico y botón Guardar
            _buildDock(context),
          ],
        ),
      ),
    );
  }

  // 1. Cabecera (.nav)
  Widget _buildNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón atrás (.rnd)
          Material(
            color: MgColors.soft,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => closeOrHome(context),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: MgColors.ink,
                  ),
                ),
              ),
            ),
          ),
          // Título central
          Expanded(
            child: Text(
              _isIncome ? 'Nuevo ingreso' : 'Nuevo gasto',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: MgColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Monto grande (.amt-wrap)
  Widget _buildAmountWrap(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón selector de moneda (.cur)
          GestureDetector(
            onTap: () => MgToast.show(context, message: 'Por ahora MiGasto trabaja solo en soles (S/).'),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'S/',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: MgColors.ink2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Monto con micro-rebote (.amt-big)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: AmountDisplay(
                rawAmount: _raw,
                fontSize: 44,
                color: _isIncome ? MgColors.up : MgColors.ink,
                align: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Chip de fecha (.datechip)
  Widget _buildDateChip(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateText = isToday
        ? 'Hoy, ${DateFormat('d MMM', 'es').format(_selectedDate)}'
        : DateFormat("d 'de' MMMM", 'es').format(_selectedDate);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Material(
          color: MgColors.soft,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: _pickDate,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: MgColors.ink2,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: MgColors.ink2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: MgColors.ink2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. Campo de descripción (.field)
  Widget _buildDescriptionField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Descripción ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: MgColors.ink2,
                  ),
                ),
                TextSpan(
                  text: '(opcional)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: MgColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: _concept,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: MgColors.ink,
            ),
            cursorColor: MgColors.acc,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              hintText: _isIncome ? 'De quién o por qué' : 'Para qué fue',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: MgColors.ink3,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: MgColors.line),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: MgColors.line),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: MgColors.acc, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Fila de categoría (.field .catrow)
  Widget _buildCategoryRow(BuildContext context) {
    final catColor = CategoryIcon.colorForCategory(_category);
    final iconData = CategoryIcon.iconForCategory(_category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categoría',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: MgColors.ink2,
            ),
          ),
          const SizedBox(height: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickCategory,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Squircle 34×34 (.catrow .ic)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 17,
                          color: catColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        categoryLabel(_category),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: MgColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: MgColors.ink3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Línea del límite (.limbar) - El corazón de la pantalla
  Widget _buildLimitBar(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final expenses = ref.watch(expensesStateProvider);
    final now = DateTime.now();

    final currentMonthExpenses = expenses
        .where((m) =>
            m.isConfirmed &&
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.esGasto)
        .toList();

    final spentInCat = currentMonthExpenses
        .where((m) => m.category == _category)
        .fold(0.0, (s, m) => s + m.amount);
    final totalSpent =
        currentMonthExpenses.fold(0.0, (s, m) => s + m.amount);
    final safeToSpend = (budget - totalSpent).clamp(0.0, double.infinity);

    // Límites de categoría desde el provider reactivo
    final categoryLimits = ref.watch(categoryLimitsProvider);
    final limitItem = categoryLimits.where((l) => l.category == _category).firstOrNull;
    final hasLimit = limitItem != null;
    final catLimit = limitItem?.limit;
    final base = hasLimit ? catLimit! : (safeToSpend > 0 ? safeToSpend : 1.0);
    final queda = hasLimit
        ? (catLimit! - spentInCat - _amount)
        : (safeToSpend - _amount);
    final pct = base > 0 ? (1.0 - (queda / base)).clamp(0.0, 1.0) : 1.0;

    // Sin límite de la categoría ni presupuesto del mes no hay contra qué
    // comparar: no se muestra nada (antes avisaba "Te pasas" sin límite).
    if (!hasLimit && budget <= 0) return const SizedBox.shrink();
    final overLabel = hasLimit
        ? 'del límite de ${categoryLabel(_category).toLowerCase()}'
        : 'del presupuesto del mes';

    final barColor = queda < 0
        ? MgColors.down
        : (pct > 0.8 ? MgColors.warn : MgColors.up);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progreso esbelta (4px)
          ProgressBar(
            percent: pct,
            height: 4,
            color: barColor,
          ),
          const SizedBox(height: 8),
          // Texto descriptivo con aviso en rojo si se sobrepasa
          if (queda < 0)
            Text(
              'Te pasas ${formatSoles(queda.abs())} $overLabel.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MgColors.down,
              ),
            )
          else
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: MgColors.ink2,
                ),
                children: [
                  const TextSpan(text: 'Te quedarán '),
                  TextSpan(
                    text: formatSoles(queda),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                    ),
                  ),
                  const TextSpan(text: ' después de este gasto.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 7. Fila de etiquetas (.field .tags)
  Widget _buildTagsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Etiquetas ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: MgColors.ink2,
                  ),
                ),
                TextSpan(
                  text: '(opcional)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: MgColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              // Etiquetas seleccionadas (.tagc.on)
              for (final t in _tags)
                Material(
                  color: MgColors.accSoft,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => setState(() => _tags.remove(t)),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: MgColors.acc),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$t',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: MgColors.acc2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: MgColors.acc2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Botón agregar etiqueta (.tagc #+)
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: _addTagPrompt,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: MgColors.line),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: MgColors.ink2,
                        ),
                        Text(
                          '#',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: MgColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Sugerencias no seleccionadas
              for (final t in _suggestedTags.where((t) => !_tags.contains(t)))
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => setState(() => _tags.add(t)),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: MgColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$t',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: MgColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Opciones auxiliares: Estado, Nota, Recurrente
  Widget _buildAuxiliaryRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          // Estado / Medio de pago
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _pickSource,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: MgColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: MgColors.ink2,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sourceLabel(_source),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Agregar nota
          Material(
            color: _note != null ? MgColors.accSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _addNotePrompt,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _note != null ? MgColors.acc : MgColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 13,
                      color: _note != null ? MgColors.acc2 : MgColors.ink2,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _note != null ? 'Nota agregada' : 'Agregar nota',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _note != null ? MgColors.acc2 : MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 9. Dock inferior (.nv-dock)
  Widget _buildDock(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MgColors.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.9),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switch Guardar y agregar otro (.sw)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Guardar y agregar otro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: MgColors.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                MgToggle(
                  value: _guardarYOtro,
                  onChanged: (val) => setState(() => _guardarYOtro = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Teclado numérico (.pad)
          AmountKeypad(
            onKeyPress: _press,
            onDelete: () => _press('<'),
          ),
          const SizedBox(height: 10),
          // Botón Guardar (.btn)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _canSave ? 1.0 : 0.35,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MgColors.acc,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canSave
                    ? const [
                        BoxShadow(
                          color: Color(0x737C5CFF),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _canSave ? _save : null,
                  child: Center(
                    child: Text(
                      _amount > 0 ? 'Guardar · ${formatSoles(_amount)}' : 'Guardar',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
