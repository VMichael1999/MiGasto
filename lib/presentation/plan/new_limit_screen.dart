import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../providers.dart';
import 'plan_providers.dart';

/// Pantalla para crear o ajustar un límite mensual (#s-limite / R.limite en migasto-prototipo.html)
/// - Cabecera (.nav): Botón atrás, título «Nuevo límite».
/// - Monto (.amt-wrap): Selector «S/ v» y display del monto grande con micro-rebote.
/// - Texto «Límite mensual» a la derecha.
/// - Fila de categoría (.catrow): Squircle con ícono y nombre, abre CategorySheet.
/// - Línea del límite (.limbar): Muestra cuánto llevas gastado y cuánto te quedaría.
/// - Dock (.nv-dock): AmountKeypad (12 teclas) y botón primario «Crear límite».
class NewLimitScreen extends ConsumerStatefulWidget {
  const NewLimitScreen({super.key, this.initialCategory = Categoria.compras});

  final Categoria initialCategory;

  @override
  ConsumerState<NewLimitScreen> createState() => _NewLimitScreenState();
}

class _NewLimitScreenState extends ConsumerState<NewLimitScreen> {
  late Categoria _category = widget.initialCategory;
  String _raw = '';

  double get _amount {
    if (_raw.isEmpty) return 0.0;
    final normalized = _raw.replaceAll(',', '.');
    return double.tryParse(normalized.endsWith('.') ? '${normalized}0' : normalized) ?? 0.0;
  }

  bool get _canSave => _amount > 0;

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
        if (parts.length == 2 && parts[1].length >= 2) return;
      } else {
        if (_raw.replaceAll(RegExp(r'\D'), '').length >= 7) return;
      }
      if (_raw == '0') {
        _raw = key;
      } else {
        _raw += key;
      }
    });
  }

  Future<void> _pickCategory() async {
    final picked = await CategorySheet.show(
      context,
      selected: _category,
      tipo: TipoMovimiento.gasto,
    );
    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
  }

  void _save() {
    if (!_canSave) return;
    ref.read(categoryLimitsProvider.notifier).setLimit(_category, _amount);
    context.pop();
    MgToast.show(
      context,
      message: 'Límite para ${categoryLabel(_category)} guardado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStateProvider);
    final now = DateTime.now();
    final spentThisMonth = expenses
        .where((m) =>
            m.isConfirmed &&
            m.category == _category &&
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.esGasto)
        .fold(0.0, (sum, m) => sum + m.amount);

    final catColor = CategoryIcon.colorForCategory(_category);
    final iconData = CategoryIcon.iconForCategory(_category);

    final limitAmount = _amount;
    final pct = limitAmount > 0
        ? (spentThisMonth / limitAmount).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = limitAmount > 0 && spentThisMonth > limitAmount;

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Cabecera (.nav)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: MgColors.soft,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.pop(),
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
                          const Text(
                            'Nuevo límite',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: MgColors.ink,
                            ),
                          ),
                          const SizedBox(width: 34),
                        ],
                      ),
                    ),

                    // 2. Monto (.amt-wrap)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => MgToast.show(
                              context,
                              message: 'Solo soles.',
                            ),
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
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: AmountDisplay(
                                rawAmount: _raw,
                                fontSize: 44,
                                align: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtítulo «Límite mensual»
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Límite mensual',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: MgColors.ink3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // 3. Fila de categoría (.field .catrow)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
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
                          const SizedBox(height: 6),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _pickCategory,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
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
                    ),

                    // 4. Línea del límite (.limbar)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProgressBar(
                            percent: pct,
                            height: 4,
                            color: isExceeded ? MgColors.down : catColor,
                          ),
                          const SizedBox(height: 8),
                          if (limitAmount <= 0)
                            const Text(
                              'Pon un monto para ver cómo vas este mes.',
                              style: TextStyle(
                                fontSize: 12,
                                color: MgColors.ink2,
                              ),
                            )
                          else if (isExceeded)
                            Text(
                              'Ya llevas ${formatSoles(spentThisMonth)} este mes, el límite quedaría pasado.',
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
                                  TextSpan(text: 'Este mes llevas ${formatSoles(spentThisMonth)}, te quedarían '),
                                  TextSpan(
                                    text: formatSoles(limitAmount - spentThisMonth),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: MgColors.ink,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dock (.nv-dock)
            Container(
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountKeypad(
                    onKeyPress: _press,
                    onDelete: () => _press('<'),
                  ),
                  const SizedBox(height: 12),
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
                          child: const Center(
                            child: Text(
                              'Crear límite',
                              style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}
