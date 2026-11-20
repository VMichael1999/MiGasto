import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/dispose_later.dart';
import '../../shared/labels.dart';
import '../../shared/profile.dart';
import '../providers.dart';
import 'plan_providers.dart';

/// Pantalla 5: Plan y Límites (#s-plan / R.plan en migasto-prototipo.html)
/// - Cabecera (.top): Mark squircle, selector de espacio «Personal v», ojo modo privado y avatar «MD».
/// - Meta de ahorro (.card): Alcancía verde, porcentaje 67%, ProgressBar, S/ 12,000.00 / S/ 18,000.00, «Faltan S/ 6,000.00».
/// - Lista de límites (.card.lim): Tarjeta por categoría con ícono squircle, porcentaje, barra a color,
///   gastado / límite y «Te quedan S/ XX,XX». Tocar abre el detalle de esa categoría.
/// - Botón «+ Agregar un límite» (.card.add-lim) con borde discontinuo que abre NewLimitScreen.
/// - Botón flotante (.fab) que abre RegisterSheet.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(balanceHiddenProvider);
    final limits = ref.watch(categoryLimitsProvider);
    final goal = ref.watch(savingsGoalProvider);
    final expenses = ref.watch(expensesStateProvider);

    final now = DateTime.now();
    final currentMonthExpenses = expenses
        .where((m) =>
            m.isConfirmed &&
            m.date.year == now.year &&
            m.date.month == now.month &&
            m.esGasto)
        .toList();

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabecera (.top)
                  _buildHeader(context, ref, hidden),

                  // 2. Tarjeta Meta de Ahorro (.card)
                  _buildSavingsGoalCard(context, ref, goal, hidden),

                  // 3. Tarjetas de límites por categoría (.card .lim)
                  for (final l in limits)
                    _buildCategoryLimitCard(
                      context,
                      l,
                      currentMonthExpenses,
                      hidden,
                    ),

                  // 4. Botón Agregar un límite (.card .add-lim)
                  _buildAddLimitButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Cabecera (.top)
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool hidden) {
    final initials = initialsOf(ref.watch(profileNameProvider));
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          // Official 3D Brand Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/brand/logo_3d.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // Espacio y mes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Personal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  toBeginningOfSentenceCase(
                      DateFormat("MMMM 'de' yyyy", 'es').format(DateTime.now()))!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          // Botón del ojo (modo privado)
          Material(
            color: MgColors.soft,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ref.read(balanceHiddenProvider.notifier).toggle();
              },
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: MgColors.ink2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar con las iniciales del usuario
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.go('/settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MgColors.soft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MgColors.line),
                ),
                child: Center(
                  child: initials.isEmpty
                      ? const Icon(Icons.person_outline_rounded,
                          size: 17, color: MgColors.ink)
                      : Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MgColors.ink,
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

  // 2. Tarjeta Meta de Ahorro (.card)
  Widget _buildSavingsGoalCard(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal? goal,
    bool hidden,
  ) {
    if (goal == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Material(
          color: MgColors.card,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showGoalSheet(context, ref, null),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MgColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.savings_outlined, size: 18, color: MgColors.up),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Define tu meta de ahorro',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
                  ),
                  Icon(Icons.add_rounded, size: 18, color: MgColors.ink2),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final pct = goal.target > 0
        ? (goal.current / goal.target).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();
    final remaining = (goal.target - goal.current).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Material(
       color: MgColors.card,
       borderRadius: BorderRadius.circular(20),
       child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showGoalSheet(context, ref, goal),
        child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MgColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Alcancía verde + Meta de Ahorro + Porcentaje
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x222FD98A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.savings_outlined,
                      size: 15,
                      color: MgColors.up,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MgColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Toca para editar',
                        style: TextStyle(
                          fontSize: 11,
                          color: MgColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$pctInt%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MgColors.up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ProgressBar 6px
            ProgressBar(
              percent: pct,
              height: 6,
              color: MgColors.up,
            ),
            const SizedBox(height: 9),
            // Montos: S/ 12,000.00 / S/ 18,000.00
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hidden ? '••••' : formatSoles(goal.current),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: MgColors.up,
                    letterSpacing: -0.4,
                    fontFeatures: AppText.tabular,
                  ),
                ),
                Text(
                  ' / ${formatSoles(goal.target)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: MgColors.ink2,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              remaining > 0
                  ? 'Faltan ${formatSoles(remaining)}'
                  : '¡Meta cumplida!',
              style: const TextStyle(
                fontSize: 11.5,
                color: MgColors.ink3,
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  /// Hoja para crear o editar la meta de ahorro.
  Future<void> _showGoalSheet(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal? goal,
  ) async {
    String fmt(double v) => v == 0 ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    final title = TextEditingController(text: goal?.title ?? '');
    final target = TextEditingController(text: fmt(goal?.target ?? 0));
    final current = TextEditingController(text: fmt(goal?.current ?? 0));

    // Misma hoja que el resto de la app (MgSheet), por encima de la barra de pestañas.
    final saved = await MgSheet.show<bool>(
      context: context,
      child: Builder(
        builder: (ctx) {
          InputDecoration deco(String label) => InputDecoration(labelText: label);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 14),
                const Text(
                  'Meta de ahorro',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: title, decoration: deco('Nombre (ej. Viaje)')),
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: deco('Monto objetivo (S/)'),
                ),
                TextField(
                  controller: current,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: deco('Ahorrado hasta hoy (S/)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (goal != null)
                      TextButton(
                        onPressed: () {
                          ref.read(savingsGoalProvider.notifier).clear();
                          Navigator.pop(ctx, false);
                        },
                        child: const Text('Quitar meta'),
                      ),
                    const Spacer(),
                    FilledButton(
                      // El tema pide ancho infinito; dentro de una fila hay que acotarlo.
                      style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );

    if (saved == true) {
      final t = double.tryParse(target.text.replaceAll(',', '.')) ?? 0;
      final c = double.tryParse(current.text.replaceAll(',', '.')) ?? 0;
      if (t > 0) {
        ref.read(savingsGoalProvider.notifier).set(SavingsGoal(
              title: title.text.trim().isEmpty ? 'Meta de ahorro' : title.text.trim(),
              current: c < 0 ? 0 : c,
              target: t,
            ));
      }
    }
    // La hoja sigue animando su cierre: los controladores se liberan después.
    disposeControllersLater([title, target, current]);
  }

  // 3. Tarjeta de límite por categoría (.card .lim)
  Widget _buildCategoryLimitCard(
    BuildContext context,
    CategoryLimitItem limitItem,
    List<Movimiento> currentMonthExpenses,
    bool hidden,
  ) {
    final cat = limitItem.category;
    final catColor = CategoryIcon.colorForCategory(cat);
    final iconData = CategoryIcon.iconForCategory(cat);

    final spent = currentMonthExpenses
        .where((m) => m.category == cat)
        .fold(0.0, (sum, m) => sum + m.amount);

    final limitVal = limitItem.limit;
    final pct = limitVal > 0 ? (spent / limitVal).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).round();
    final isHigh = pct >= 0.8;
    final remains = limitVal - spent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Material(
        color: MgColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/category/${cat.name}'),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MgColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado: Squircle categoría + Nombre + %
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 15,
                          color: catColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                categoryLabel(cat),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MgColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Límite de gasto · ${toBeginningOfSentenceCase(DateFormat("MMMM 'de' yyyy", 'es').format(DateTime.now()))}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: MgColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$pctInt%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isHigh ? MgColors.warn : MgColors.up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ProgressBar
                ProgressBar(
                  percent: pct,
                  height: 6,
                  color: isHigh ? MgColors.warn : catColor,
                ),
                const SizedBox(height: 9),
                // Montos: S/ 1,200.00 / S/ 1,600.00
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hidden ? '••••' : formatSoles(spent),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MgColors.ink,
                        letterSpacing: -0.4,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    Text(
                      ' / ${formatSoles(limitVal)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: MgColors.ink2,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (remains >= 0)
                  Text(
                    'Te quedan ${formatSoles(remains)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: MgColors.ink3,
                    ),
                  )
                else
                  Text(
                    'Te pasas ${formatSoles(remains.abs())}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: MgColors.down,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. Botón Agregar un límite (.card .add-lim)
  Widget _buildAddLimitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/limit/new'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MgColors.line,
                width: 1.4,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: MgColors.ink2,
                ),
                SizedBox(width: 8),
                Text(
                  'Agregar un límite',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
