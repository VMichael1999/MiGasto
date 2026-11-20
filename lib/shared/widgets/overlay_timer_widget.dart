import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/widgets/money_text.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../presentation/providers.dart';
import '../labels.dart';
import '../dispose_later.dart';

/// Aviso de "Pago detectado" dentro de la app, con el diseño oscuro unificado de MiGasto.
///
/// - Gasto: cuenta regresiva de 4 s que se pausa al tocar; al llegar a 0 se guarda.
/// - Ingreso: sin cuenta regresiva; nunca se guarda solo. Si se ignora, queda en
///   "Por confirmar".
class OverlayTimerWidget extends ConsumerStatefulWidget {
  final Widget child;

  const OverlayTimerWidget({super.key, required this.child});

  @override
  ConsumerState<OverlayTimerWidget> createState() => _OverlayTimerWidgetState();
}

class _OverlayTimerWidgetState extends ConsumerState<OverlayTimerWidget>
    with SingleTickerProviderStateMixin {
  static const _countdownMs = 4000;
  static const _tickMs = 100;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  Timer? _timer;
  int _remainingMs = _countdownMs;
  bool _paused = false;

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _start(Movimiento pending) {
    _timer?.cancel();
    _remainingMs = _countdownMs;
    _paused = false;

    if (MediaQuery.disableAnimationsOf(context)) {
      _slide.value = 1;
    } else {
      _slide.forward(from: 0);
    }

    // Un ingreso espera la confirmación del usuario.
    if (pending.esIngreso) return;

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      if (_paused || !mounted) return;
      setState(() => _remainingMs -= _tickMs);
      if (_remainingMs <= 0) {
        timer.cancel();
        _save();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _slide.value = 0;
  }

  void _pause() {
    if (!_paused) setState(() => _paused = true);
  }

  void _save() {
    final pending = ref.read(pendingExpenseProvider);
    if (pending == null) return;
    _timer?.cancel();
    ref.read(expensesStateProvider.notifier).confirmPendingExpense(pending.category, pending.notes);
  }

  void _dismiss() {
    _timer?.cancel();
    ref.read(expensesStateProvider.notifier).discardPendingExpense();
  }

  void _update(Movimiento updated) =>
      ref.read(expensesStateProvider.notifier).updatePending(updated);

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    ref.listen<Movimiento?>(pendingExpenseProvider, (prev, next) {
      if (next != null && next.id != prev?.id) {
        _start(next);
      } else if (next == null) {
        _stop();
      }
    });
    final pending = ref.watch(pendingExpenseProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (pending != null)
          Positioned(
            left: 14,
            right: 14,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _slide,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: _card(context, pending),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Movimiento pending) {
    final isIncome = pending.esIngreso;
    final time = DateFormat('HH:mm').format(pending.date);
    final seconds = ((_remainingMs + 999) ~/ 1000).clamp(0, 4);

    return Listener(
      // Tocar la ventana pausa la cuenta regresiva.
      onPointerDown: (_) {
        if (!isIncome) _pause();
      },
      child: Semantics(
        container: true,
        label: isIncome ? 'Ingreso detectado' : 'Gasto detectado',
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF515151B), // var(--card) con ligera translucidez
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              if (!isIncome && !_paused)
                BoxShadow(
                  color: MgColors.acc.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra timeline de cuenta regresiva
              if (!isIncome)
                SizedBox(
                  height: 3.5,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.06)),
                      FractionallySizedBox(
                        widthFactor: (_remainingMs / _countdownMs).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _paused
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFA78BFA),
                                      Color(0xFF7C5CFF),
                                    ],
                                  ),
                            color: _paused ? MgColors.ink3 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado: Origen y estado de tiempo
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _sourceColor(pending.source),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _sourceColor(pending.source).withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${sourceLabel(pending.source)} · $time',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: MgColors.ink2,
                            ),
                          ),
                        ),
                        if (!isIncome)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: _paused
                                  ? MgColors.soft
                                  : MgColors.accSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _paused
                                    ? MgColors.line
                                    : MgColors.accLine,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _paused ? 'En pausa' : 'Se guarda en ${seconds}s',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _paused ? MgColors.ink2 : MgColors.acc2,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Monto grande
                    MoneyText(
                      amount: pending.amount,
                      style: AppText.money(size: 34, weight: FontWeight.w800),
                      isExpense: !isIncome,
                      color: isIncome ? MgColors.up : MgColors.ink,
                    ),
                    const SizedBox(height: 4),

                    // Destinatario / Comercio
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: MgColors.ink2,
                        ),
                        children: [
                          TextSpan(text: isIncome ? 'de ' : 'a '),
                          TextSpan(
                            text: displayName(pending.merchant, ref.watch(aliasesProvider)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: MgColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fila de selección de categoría
                    _pickRow(context, pending, isIncome),
                    const SizedBox(height: 12),

                    // Nota informativa para ingresos
                    if (isIncome) ...[
                      _incomeNote(context),
                      const SizedBox(height: 12),
                    ],

                    // Botones de acción
                    _actions(context, pending, isIncome),
                    if (!isIncome) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _paused ? 'Toca cualquier botón para continuar' : 'Toca para pausar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: MgColors.ink3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'MiGasto · Detección',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: MgColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _sourceColor(PaymentSource source) {
    switch (source) {
      case PaymentSource.yape:
        return const Color(0xFF7C5CFF);
      case PaymentSource.plin:
        return const Color(0xFF00D1FF);
      case PaymentSource.googlePay:
        return const Color(0xFF4285F4);
      case PaymentSource.tarjeta:
        return const Color(0xFFFF8A3D);
      case PaymentSource.efectivo:
        return const Color(0xFF2FD98A);
      case PaymentSource.manual:
      case PaymentSource.otro:
        return MgColors.acc2;
    }
  }

  Widget _pickRow(BuildContext context, Movimiento pending, bool isIncome) {
    final catColor = _categoryColor(pending.category);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.lightImpact();
        _pause();
        _pickCategory(context, pending);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MgColors.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MgColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(
                _categoryIconData(pending.category),
                size: 15,
                color: catColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: MgColors.ink2),
                  children: [
                    TextSpan(text: isIncome ? 'Tipo: ' : 'Categoría: '),
                    TextSpan(
                      text: categoryLabel(pending.category),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Cambiar',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: MgColors.acc2,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: MgColors.acc2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomeNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MgColors.up.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: MgColors.up.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: MgColors.up),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12.5, color: MgColors.ink, height: 1.4),
                children: [
                  TextSpan(text: 'Es dinero que '),
                  TextSpan(
                    text: 'recibiste',
                    style: TextStyle(fontWeight: FontWeight.w700, color: MgColors.up),
                  ),
                  TextSpan(text: '. No se guardará hasta que lo confirmes.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, Movimiento pending, bool isIncome) {
    Widget button(
      String label,
      int flex, {
      Color? fill,
      Color? text,
      bool hasBorder = false,
      required VoidCallback onTap,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: fill ?? MgColors.soft,
                foregroundColor: text ?? MgColors.ink,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: hasBorder
                      ? const BorderSide(color: MgColors.line)
                      : BorderSide.none,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(label),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (isIncome) ...[
          button('Ignorar', 10, onTap: _dismiss),
          button(
            'Guardar ingreso',
            14,
            fill: MgColors.up,
            text: Colors.black,
            onTap: _save,
          ),
        ] else ...[
          button('Descartar', 10, onTap: _dismiss),
          button(
            'Editar',
            10,
            onTap: () {
              _pause();
              _edit(context, pending);
            },
          ),
          button(
            'Guardar',
            14,
            fill: MgColors.acc,
            text: Colors.white,
            onTap: _save,
          ),
        ],
      ],
    );
  }

  Color _categoryColor(Categoria cat) {
    switch (cat) {
      case Categoria.alimentacion:
        return const Color(0xFFFF5C8A);
      case Categoria.transporte:
        return const Color(0xFF22D3EE);
      case Categoria.compras:
        return const Color(0xFFF5A524);
      case Categoria.servicios:
        return const Color(0xFF7C5CFF);
      case Categoria.entretenimiento:
        return const Color(0xFFFF8A3D);
      case Categoria.sueldo:
        return const Color(0xFF2FD98A);
      case Categoria.transferenciaRecibida:
        return const Color(0xFF34D399);
      case Categoria.venta:
        return const Color(0xFF60A5FA);
      case Categoria.otros:
      case Categoria.otrosIngresos:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _categoryIconData(Categoria cat) {
    switch (cat) {
      case Categoria.alimentacion:
        return Icons.shopping_cart_outlined;
      case Categoria.transporte:
        return Icons.directions_bus_outlined;
      case Categoria.compras:
        return Icons.shopping_bag_outlined;
      case Categoria.servicios:
        return Icons.bolt_outlined;
      case Categoria.entretenimiento:
        return Icons.subscriptions_outlined;
      case Categoria.sueldo:
        return Icons.account_balance_wallet_outlined;
      case Categoria.transferenciaRecibida:
        return Icons.arrow_downward_rounded;
      case Categoria.venta:
        return Icons.sell_outlined;
      case Categoria.otros:
      case Categoria.otrosIngresos:
        return Icons.category_outlined;
    }
  }

  // ------------------------------------------------------------------ hojas

  void _pickCategory(BuildContext context, Movimiento pending) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MgColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asa superior
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              pending.esIngreso ? 'Tipo de ingreso' : 'Seleccionar categoría',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    for (final cat in Categoria.paraTipo(pending.tipo)) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _update(pending.copyWith(category: cat));
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _categoryColor(cat).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _categoryIconData(cat),
                                  size: 17,
                                  color: _categoryColor(cat),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  categoryLabel(cat),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: cat == pending.category
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: cat == pending.category
                                        ? MgColors.ink
                                        : MgColors.ink2,
                                  ),
                                ),
                              ),
                              if (cat == pending.category)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 19,
                                  color: MgColors.acc2,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, Movimiento pending) {
    final merchant = TextEditingController(text: pending.merchant);
    final amount = TextEditingController(text: pending.amount.toStringAsFixed(2));
    final notes = TextEditingController(text: pending.notes);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MgColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa superior
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              pending.esIngreso ? 'Editar ingreso detectado' : 'Editar gasto detectado',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MgColors.ink,
              ),
            ),
            const SizedBox(height: 18),

            // Campo Monto
            _buildField(
              label: 'Monto',
              icon: Icons.attach_money_rounded,
              child: TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 15, color: MgColors.ink, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  prefixText: 'S/ ',
                  prefixStyle: TextStyle(color: MgColors.acc2, fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Campo Comercio
            _buildField(
              label: pending.esIngreso ? 'De quién' : 'Comercio',
              icon: Icons.storefront_outlined,
              child: TextField(
                controller: merchant,
                style: const TextStyle(fontSize: 14.5, color: MgColors.ink),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Campo Notas
            _buildField(
              label: 'Nota (opcional)',
              icon: Icons.edit_note_rounded,
              child: TextField(
                controller: notes,
                style: const TextStyle(fontSize: 14.5, color: MgColors.ink),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Guardar
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(amount.text.replaceAll(',', '.'));
                  if (value == null || value <= 0 || merchant.text.trim().isEmpty) return;
                  _update(pending.copyWith(
                    amount: value,
                    merchant: merchant.text.trim(),
                    notes: notes.text.trim(),
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MgColors.acc,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => disposeControllersLater([merchant, amount, notes]));
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MgColors.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MgColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: MgColors.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MgColors.ink3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

