import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/setup_issues.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/profile_avatar_button.dart';
import '../../domain/balance_projection.dart';
import '../../domain/balance_summary.dart';
import '../expenses/expense_detail_dialog.dart';
import '../plan/plan_providers.dart';
import 'dashboard_side_cards.dart';
import '../providers.dart';
import '../../core/layout/landscape_pane.dart';
import '../../core/layout/adaptive.dart';

/// Pantalla 1: Inicio (s-home en prototipo HTML y Sección 4.4 del prompt).
/// - Cabecera: mark de 34, selector de espacio ("Personal ›") con mes debajo,
///   botón de ojo (modo privado) y avatar con iniciales ("MD").
/// - Tarjeta de balance: degradado violeta, radio 24, "Balance disponible ›",
///   monto en 33/800, "Saldo de octubre", "Disponible XX %" con barra blanca,
///   y dos cápsulas de vidrio con Ingresos y Gastos.
/// - Seguro para gastar: monto en verde, "S/ XX / día · XX días restantes" y
///   toggle "Ver menos" / "Ver más".
/// - Avisos de permisos y movimientos pendientes (si existen).
/// - Movimientos: encabezado con contador del mes y búsqueda; lista agrupada por día
///   con totales por día, deslizamiento para borrar (`SwipeToDelete`), menú contextual
///   (`LongPressMenu`), íconos a color y montos tabulares.
/// - Botón flotante (`MgFab`) que despliega la hoja de registro (`RegisterSheet`).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _safeOpen = true;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesStateProvider);
    final budget = ref.watch(budgetProvider);
    final issues = ref.watch(setupIssuesProvider);
    final hidden = ref.watch(balanceHiddenProvider);

    final now = DateTime.now();
    bool isThisMonth(Movimiento m) =>
        m.date.year == now.year && m.date.month == now.month;

    final confirmedMonth =
        expenses.where((m) => m.isConfirmed && isThisMonth(m)).toList();
    // Saldo que arrastra del mes anterior y cifras del mes: solo con datos reales.
    final summary = computeBalanceSummary(expenses, now);
    final spent = summary.spent;
    final income = summary.income;
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevBalance = summary.prevBalance;

    final balance = summary.balance;
    final totalDispon = prevBalance + income;
    final dispPercent = totalDispon > 0
        ? ((balance / totalDispon) * 100).clamp(0, 100).round()
        : (spent == 0 ? 100 : 0);

    // Seguro para gastar: lo que falta por gastar del presupuesto del mes, sin
    // pasar del saldo disponible. Sin presupuesto definido no se inventa un
    // número: la tarjeta pide definirlo.
    final hasBudget = budget > 0;
    final safeToSpend = hasBudget
        ? (budget - spent).clamp(0.0, balance > 0 ? balance : 0.0).toDouble()
        : 0.0;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day).clamp(1, 31);
    final safePerDay = safeToSpend / remainingDays;

    final pending = expenses
        .where((m) => m.estado == EstadoMovimiento.pendiente)
        .toList();

    // Piezas compartidas por el diseño vertical y el horizontal.
    final header = _HomeHeader(
      now: now,
      hidden: hidden,
      onEyeTap: () => ref.read(balanceHiddenProvider.notifier).toggle(),
    );
    final prevMonthName = toBeginningOfSentenceCase(
      DateFormat('MMMM', 'es').format(prevMonthDate),
    );
    final balanceCard = _BalanceCard(
      balance: balance,
      prevBalance: prevBalance,
      prevMonthName: prevMonthName,
      dispPercent: dispPercent,
      income: income,
      spent: spent,
      hidden: hidden,
      onTap: () => _showBalanceDetail(
        context,
        prevMonthName: prevMonthName,
        prevBalance: prevBalance,
        income: income,
        spent: spent,
        balance: balance,
        hidden: hidden,
      ),
    );
    final safeCard = _SafeToSpendCard(
      hasBudget: hasBudget,
      onDefineBudget: () => context.push('/settings'),
      safeToSpend: safeToSpend,
      safePerDay: safePerDay,
      remainingDays: remainingDays,
      isOpen: _safeOpen,
      hidden: hidden,
      onToggle: () => setState(() => _safeOpen = !_safeOpen),
    );
    final banners = <Widget>[
      // Avisos de permisos y lectura (si existen)
      if (issues.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: _SetupBanner(issue: issues.first),
        ),
      // Avisos de pendientes por confirmar (si existen)
      if (pending.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: _PendingBanner(pending: pending, hidden: hidden),
        ),
    ];
    final movementsHeader = _MovementsSectionHeader(
      count: confirmedMonth.length,
      onSearchTap: () => context.go('/expenses?focus=1'),
    );
    final movementsList = _MovementsGroupedList(
      movements: confirmedMonth,
      hidden: hidden,
    );

    // Teléfono girado: tres columnas con scroll propio.
    if (context.isLandscapePhone) {
      final monthExpenses = confirmedMonth.where((m) => m.esGasto).toList();
      final limits = ref.watch(categoryLimitsProvider);
      final projection = projectBalance(
        movements: expenses,
        currentBalance: balance,
        now: now,
      );
      final bottom = context.tabBarClearance(130);
      Widget column(List<Widget> children, {EdgeInsets padding = EdgeInsets.zero}) =>
          LandscapePane(
            padding: padding.copyWith(bottom: bottom),
            children: children,
          );
      return Scaffold(
        backgroundColor: MgColors.bg,
        body: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              column([header, balanceCard, safeCard, ...banners]),
              column([movementsHeader, movementsList]),
              column(
                [
                  LimitsOverviewCard(
                    limits: limits,
                    monthExpenses: monthExpenses,
                    hidden: hidden,
                  ),
                  CategoryDonutCard(monthExpenses: monthExpenses, hidden: hidden),
                  BalanceForecastCard(
                    projection: projection,
                    history: balanceHistory(
                      movements: expenses,
                      currentBalance: balance,
                      now: now,
                    ),
                    currentBalance: balance,
                    hidden: hidden,
                  ),
                ],
                padding: const EdgeInsets.fromLTRB(6, 14, 18, 0),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.only(bottom: context.tabBarClearance(130)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  balanceCard,
                  safeCard,
                  ...banners,
                  movementsHeader,
                  movementsList,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Detalle del balance: de dónde sale la cifra (todo con datos reales).
  void _showBalanceDetail(
    BuildContext context, {
    required String prevMonthName,
    required double prevBalance,
    required double income,
    required double spent,
    required double balance,
    required bool hidden,
  }) {
    String money(double v) => hidden ? 'S/ ••••' : formatSoles(v);
    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: bold ? MgColors.ink : MgColors.ink2,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color ?? MgColors.ink,
                  )),
            ],
          ),
        );

    showModalBottomSheet<void>(
      context: context,
      // Por encima de la barra de pestañas flotante.
      useRootNavigator: true,
      backgroundColor: MgColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Balance disponible',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: MgColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              row('Saldo de ${prevMonthName.toLowerCase()}', money(prevBalance)),
              row('Ingresos del mes', '+${money(income)}', color: MgColors.up),
              row('Gastos del mes', '−${money(spent)}', color: MgColors.down),
              const Divider(color: MgColors.line, height: 18),
              row('Balance disponible', money(balance), bold: true),
            ],
          ),
        ),
      ),
    );
  }

}

// =============================================================================
// CABECERA COMÚN (.top)
// =============================================================================
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.now,
    required this.hidden,
    required this.onEyeTap,
  });

  final DateTime now;
  final bool hidden;
  final VoidCallback onEyeTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = toBeginningOfSentenceCase(
      DateFormat("MMMM 'de' yyyy", 'es').format(now),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
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
          const SizedBox(width: 11),

          // Espacio (por ahora solo existe «Personal»)
          Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal',
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.02 * 16,
                        color: MgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 11.5,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón del ojo (.rnd)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEyeTap,
              borderRadius: BorderRadius.circular(19),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hidden ? MgColors.accSoft : MgColors.soft,
                ),
                child: Center(
                  child: Icon(
                    hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: hidden ? MgColors.acc2 : MgColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Perfil (avatar con iniciales)
          const ProfileAvatarButton(size: 38),
        ],
      ),
    );
  }
}

// =============================================================================
// TARJETA DE BALANCE (.bal)
// =============================================================================
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.prevBalance,
    required this.prevMonthName,
    required this.dispPercent,
    required this.income,
    required this.spent,
    required this.hidden,
    required this.onTap,
  });

  final VoidCallback onTap;
  final double balance;
  final double prevBalance;
  final String prevMonthName;
  final int dispPercent;
  final double income;
  final double spent;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E73FF), Color(0xFF6A46F5), Color(0xFF5A36E8)],
          stops: [0.0, 0.58, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFF).withValues(alpha: 0.38),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Resplandor radial tenue superior derecho
            Positioned(
              top: -70,
              right: -50,
              width: 200,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.68],
                  ),
                ),
              ),
            ),

            // Contenido de la tarjeta
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera: Balance disponible ›
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Balance disponible',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Monto grande (33/800)
                  if (hidden)
                    Text(
                      'S/ ••••••',
                      style: AppText.money(
                        size: 33,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ).copyWith(letterSpacing: 2.0),
                    )
                  else
                    MoneyText(
                      amount: balance,
                      showSign: false,
                      color: Colors.white,
                      style: AppText.money(
                        size: 33,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Saldo del mes anterior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        'SALDO DE $prevMonthName'.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppText.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.9,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      )),
                      Text(
                        hidden
                            ? '•••'
                            : (prevBalance >= 0
                                ? '+${formatSoles(prevBalance)}'
                                : '−${formatSoles(prevBalance.abs())}'),
                        style: const TextStyle(
                          fontFamily: AppText.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),

                  // Disponible XX %
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        'DISPONIBLE',
                        style: TextStyle(
                          fontFamily: AppText.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.9,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      )),
                      Text(
                        '$dispPercent%',
                        style: const TextStyle(
                          fontFamily: AppText.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Pista blanca (.track)
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (dispPercent / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dos cápsulas de vidrio (.two): mismo ancho, mismo alto y la
                  // misma tipografía; en columnas estrechas las dos bajan juntas.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final capsuleWidth = (constraints.maxWidth - 9) / 2;
                      final amountSize = capsuleWidth < 125 ? 13.0 : 15.5;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ingresos
                            Expanded(
                              child: _GlassCapsule(
                                icon: Icons.arrow_upward_rounded,
                                label: 'INGRESOS',
                                amount: '+${formatSoles(income)}',
                                amountSize: amountSize,
                                hidden: hidden,
                              ),
                            ),
                            const SizedBox(width: 9),
                            // Gastos
                            Expanded(
                              child: _GlassCapsule(
                                icon: Icons.arrow_downward_rounded,
                                label: 'GASTOS',
                                amount: '−${formatSoles(spent)}',
                                amountSize: amountSize,
                                hidden: hidden,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({
    required this.icon,
    required this.label,
    required this.amount,
    required this.hidden,
    this.amountSize = 15.5,
  });

  final double amountSize;
  final IconData icon;
  final String label;
  final String amount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 5),
              Flexible(child: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                label,
                style: TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: 0.80),
                ),
              )),
            ],
          ),
          const SizedBox(height: 3),
          // Una sola línea: si la cifra no cabe (columna estrecha), se achica.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hidden ? '•••••' : amount,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: amountSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02 * amountSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TARJETA SEGURO PARA GASTAR (.card)
// =============================================================================
class _SafeToSpendCard extends StatelessWidget {
  const _SafeToSpendCard({
    required this.hasBudget,
    required this.onDefineBudget,
    required this.safeToSpend,
    required this.safePerDay,
    required this.remainingDays,
    required this.isOpen,
    required this.hidden,
    required this.onToggle,
  });

  final bool hasBudget;
  final VoidCallback onDefineBudget;
  final double safeToSpend;
  final double safePerDay;
  final int remainingDays;
  final bool isOpen;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MgCard(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: ícono de escudo + Seguro para gastar + botón (i)
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: MgColors.accSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: MgColors.acc2,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Flexible(flex: 100, child: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'Seguro para gastar',
                style: TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MgColors.ink,
                ),
              )),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    MgToast.show(
                      context,
                      message: 'Es lo que te queda por gastar de tu presupuesto del mes, sin pasar de tu saldo.',
                    );
                  },
                  borderRadius: BorderRadius.circular(13),
                  child: const SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: MgColors.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Monto en verde (.safe), o aviso si aún no hay presupuesto
          if (!hasBudget)
            InkWell(
              onTap: onDefineBudget,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Define tu presupuesto en Ajustes para verlo ›',
                  style: TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 13,
                    color: MgColors.ink2,
                  ),
                ),
              ),
            )
          else
            Text(
              hidden ? '••••••' : formatSoles(safeToSpend),
              style: AppText.money(
                size: 24,
                weight: FontWeight.w800,
                color: MgColors.up,
              ),
            ),

          // Detalle diario colapsable
          if (isOpen && hasBudget) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: MgColors.ink2,
                ),
                const SizedBox(width: 7),
                Text(
                  hidden
                      ? '•••• / día · $remainingDays días restantes'
                      : '${formatSoles(safePerDay)} / día · $remainingDays días restantes',
                  style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 11.5,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 7),

          // Botón Ver menos / Ver más
          if (hasBudget)
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOpen ? 'Ver menos' : 'Ver más',
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: MgColors.ink3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 13,
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
}

// =============================================================================
// ENCABEZADO DE SECCIÓN (.sec)
// =============================================================================
class _MovementsSectionHeader extends StatelessWidget {
  const _MovementsSectionHeader({
    required this.count,
    required this.onSearchTap,
  });

  final int count;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
      child: Row(
        children: [
          const Flexible(
            // Casi todo el espacio libre para el título; el resto, al Spacer.
            flex: 100,
            child: Text(
              'Movimientos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025 * 17,
                color: MgColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: MgColors.soft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: MgColors.ink2,
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MgColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Separación mínima: en columnas estrechas la lupa no se pega a la cuenta.
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(19),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MgColors.soft,
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: MgColors.ink,
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

// =============================================================================
// LISTA DE MOVIMIENTOS AGRUPADA POR DÍA (.day + .mv + .swipe)
// =============================================================================
class _MovementsGroupedList extends ConsumerWidget {
  const _MovementsGroupedList({
    required this.movements,
    required this.hidden,
  });

  final List<Movimiento> movements;
  final bool hidden;

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

  bool _isRecurring(Movimiento m) {
    final note = m.notes.toLowerCase();
    return note.contains('recurrente') ||
        note.contains('subs') ||
        m.category == Categoria.entretenimiento;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (movements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Sin movimientos este mes',
          message: 'Tus gastos e ingresos aparecerán aquí agrupados por día.',
          actionLabel: 'Registrar movimiento',
          onAction: () {
            RegisterSheet.show(
              context: context,
              onSelectExpense: () => context.push('/new'),
              onSelectIncome: () => context.push('/new'),
            );
          },
        ),
      );
    }

    final now = DateTime.now();
    final aliases = ref.watch(aliasesProvider);

    // Agrupación por día (clave YYYY-MM-DD)
    final grouped = <String, List<Movimiento>>{};
    for (final m in movements) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in sortedKeys) ...[
          // Cabecera del día (.day)
          Builder(
            builder: (context) {
              final dayList = grouped[key]!;
              final dayDate = dayList.first.date;
              final dayTotal = dayList.fold(
                0.0,
                (sum, m) => sum + (m.esIngreso ? m.amount : -m.amount),
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      _formatDayLabel(dayDate, now),
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: MgColors.ink2,
                      ),
                    )),
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
              );
            },
          ),

          // Filas del día
          for (final m in grouped[key]!) ...[
            SwipeToDelete(
              itemKey: ValueKey(m.id),
              confirmTitle: '¿Eliminar movimiento?',
              confirmMessage:
                  'Se borrará «${displayName(m.merchant, aliases)}» de tu historial.',
              onDelete: () async {
                final deleted = m;
                await ref.read(expensesStateProvider.notifier).deleteExpense(m.id);
                if (context.mounted) {
                  MgToast.show(
                    context,
                    message: 'Movimiento eliminado',
                    actionLabel: 'Deshacer',
                    onAction: () {
                      ref.read(expensesStateProvider.notifier).restoreExpense(deleted);
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
                        message: 'Agregado a registros comunes',
                      );
                    case MgMenuAction.compare:
                      MgToast.show(
                        context,
                        message: 'Comparando con periodos anteriores',
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
                  onTap: () => showExpenseDetailSheet(context, ref, m),
                ),
              ),
            ),
          ],
        ],
      ],
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

// =============================================================================
// AVISOS FUNCIONALES (SetupBanner & PendingBanner)
// =============================================================================
class _SetupBanner extends ConsumerWidget {
  const _SetupBanner({required this.issue});

  final SetupIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(permissionsCheckerProvider);
    final off = issue == SetupIssue.lecturaApagada;

    final String title;
    final String body;
    final String action;
    switch (issue) {
      case SetupIssue.lecturaApagada:
        title = 'La lectura de pagos está apagada';
        body =
            'MiGasto no está viendo tus pagos de Yape, Plin ni Wallet. Actívala en Acceso a notificaciones.';
        action = 'Activar';
      case SetupIssue.avisosApagados:
        title = 'Activa los avisos de MiGasto';
        body =
            'Con la pantalla apagada o bloqueada, solo así sabrás qué pago se detectó.';
        action = 'Activar';
      case SetupIssue.bateriaRestringida:
        title = 'Evita que el teléfono cierre la lectura';
        body =
            'Entra a Batería y elige «No restringido». Si no, el teléfono puede dormir la app y se pierden pagos.';
        action = 'Ajustar';
    }

    Future<void> dismiss() async {
      final now = DateTime.now();
      final prefs = ref.read(sharedPreferencesProvider);
      if (issue == SetupIssue.avisosApagados) {
        await prefs.setString(keyAlertsBannerDismissed, now.toIso8601String());
        ref.read(alertsBannerDismissedProvider.notifier).state = now;
      } else {
        await prefs.setString(keyBatteryBannerDismissed, now.toIso8601String());
        ref.read(batteryBannerDismissedProvider.notifier).state = now;
      }
    }

    Future<void> act() async {
      switch (issue) {
        case SetupIssue.lecturaApagada:
          await permissions.openNotificationListenerSettings();
        case SetupIssue.avisosApagados:
          await permissions.requestPostNotifications();
        case SetupIssue.bateriaRestringida:
          await permissions.openBatterySettings();
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MgColors.warn.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: MgColors.warn),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 12,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!off)
                TextButton(
                  onPressed: dismiss,
                  child: const Text('Ahora no', style: TextStyle(color: MgColors.ink2)),
                ),
              TextButton(
                onPressed: act,
                child: Text(
                  action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: MgColors.acc2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.pending,
    required this.hidden,
  });

  final List<Movimiento> pending;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final count = pending.length;
    final allIncome = pending.every((m) => m.esIngreso);
    final noun = allIncome
        ? (count == 1 ? 'ingreso' : 'ingresos')
        : (count == 1 ? 'movimiento' : 'movimientos');
    final incomeTotal =
        pending.where((m) => m.esIngreso).fold(0.0, (s, m) => s + m.amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/expenses'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: MgColors.accSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MgColors.accLine, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: MgColors.acc2),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 13,
                      color: MgColors.ink,
                    ),
                    children: [
                      TextSpan(
                        text: '$count $noun',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' por confirmar'),
                    ],
                  ),
                ),
              ),
              if (incomeTotal > 0)
                Text(
                  hidden ? '+ S/ ••••' : '+ ${formatSoles(incomeTotal)}',
                  style: AppText.money(
                    size: 13,
                    weight: FontWeight.w600,
                    color: MgColors.acc2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
