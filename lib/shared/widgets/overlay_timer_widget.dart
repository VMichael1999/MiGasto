import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../presentation/providers.dart';
import '../labels.dart';
import 'app_icons.dart';
import 'big_amount.dart';
import 'category_icon.dart';

/// Aviso de "Pago detectado" dentro de la app, con el mismo diseño de la ventana
/// flotante de Android.
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

  late final AnimationController _slide =
      AnimationController(vsync: this, duration: AppMotion.short);
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
            left: 10,
            right: 10,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _slide, curve: AppMotion.standard)),
                  child: _card(context, pending),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Movimiento pending) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
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
        child: Material(
          color: scheme.surface,
          elevation: 12,
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isIncome)
                SizedBox(
                  height: AppSizes.overlayTimeline,
                  child: Stack(
                    children: [
                      Container(color: scheme.outline),
                      FractionallySizedBox(
                        widthFactor: (_remainingMs / _countdownMs).clamp(0.0, 1.0),
                        child: Container(color: _paused ? scheme.onSurfaceVariant : scheme.primary),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.sourceColor(pending.source.name),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${sourceLabel(pending.source)} · $time',
                            style: theme.textTheme.bodySmall!
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!isIncome)
                          Text(
                            _paused ? 'En pausa' : 'Se guarda en $seconds s',
                            style: AppText.amount(theme.textTheme.bodySmall!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BigAmount(
                      pending.amount,
                      size: 38,
                      prefix: isIncome ? '+ S/' : 'S/',
                      color: isIncome ? colors.income : null,
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w400),
                        children: [
                          TextSpan(text: isIncome ? 'de ' : 'a '),
                          TextSpan(
                            text: displayName(pending.merchant, ref.watch(aliasesProvider)),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _pickRow(context, pending, isIncome),
                    const SizedBox(height: 12),
                    if (isIncome) ...[
                      _incomeNote(context),
                      const SizedBox(height: 12),
                    ],
                    _actions(context, pending, isIncome),
                    if (!isIncome) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_paused ? 'En pausa' : 'Toca para pausar',
                              style: theme.textTheme.labelSmall),
                          Text('MiGasto', style: theme.textTheme.labelSmall),
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

  Widget _pickRow(BuildContext context, Movimiento pending, bool isIncome) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _pause();
        _pickCategory(context, pending);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppIcon(categoryIcon(pending.category),
                size: AppIconSize.small, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13.5),
                  children: [
                    TextSpan(text: isIncome ? 'Tipo: ' : 'Categoría: '),
                    TextSpan(
                      text: categoryLabel(pending.category),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Text('Cambiar',
                style: theme.textTheme.labelLarge!
                    .copyWith(fontSize: 13, color: colors.brandInk)),
          ],
        ),
      ),
    );
  }

  Widget _incomeNote(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.incomeSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: AppIconSize.small, color: colors.income),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13),
                children: const [
                  TextSpan(text: 'Es dinero que '),
                  TextSpan(text: 'recibiste', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: '. No se guarda hasta que lo confirmes.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, Movimiento pending, bool isIncome) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    Widget button(String label, int flex, {Color? fill, Color? text, required VoidCallback onTap}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: fill ?? Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: fill == null
                  ? BorderSide(color: theme.colorScheme.outline, width: 1.5)
                  : BorderSide.none,
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              onTap: onTap,
              child: Container(
                height: AppSizes.minTouch,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall!
                      .copyWith(color: text ?? theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (isIncome) ...[
          button('Ignorar', 10, onTap: _dismiss),
          button('Guardar ingreso', 14,
              fill: colors.income, text: theme.scaffoldBackgroundColor, onTap: _save),
        ] else ...[
          button('Descartar', 10, onTap: _dismiss),
          button('Editar', 10, onTap: () {
            _pause();
            _edit(context, pending);
          }),
          button('Guardar', 14,
              fill: theme.colorScheme.primary, text: theme.colorScheme.onPrimary, onTap: _save),
        ],
      ],
    );
  }

  // ------------------------------------------------------------------ hojas

  void _pickCategory(BuildContext context, Movimiento pending) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                pending.esIngreso ? 'Tipo de ingreso' : 'Categoría',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              for (final cat in Categoria.paraTipo(pending.tipo))
                ListTile(
                  minTileHeight: AppSizes.minTouch,
                  leading: AppIcon(categoryIcon(cat),
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(categoryLabel(cat)),
                  selected: cat == pending.category,
                  onTap: () {
                    _update(pending.copyWith(category: cat));
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
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
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            18, 14, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar pago', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: merchant,
              decoration: InputDecoration(
                labelText: pending.esIngreso ? 'De quién' : 'Comercio',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            const SizedBox(height: 14),
            FilledButton(
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
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      merchant.dispose();
      amount.dispose();
      notes.dispose();
    });
  }
}
