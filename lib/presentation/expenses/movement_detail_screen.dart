import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/config/env.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/custom_icons.dart';
import '../providers.dart';
import 'alias_dialog.dart';
import 'movement_comparison_sheet.dart';
import 'new_category_sheet.dart';
import '../../shared/dispose_later.dart';
import '../../shared/widgets/merchant_icon.dart';

/// Abre el detalle de un movimiento.
void showExpenseDetailSheet(BuildContext context, WidgetRef ref, Movimiento movimiento) {
  context.push('/movement/${movimiento.id}');
}

/// Pantalla 3: Detalle del movimiento (`#s-mov` en prototipo HTML y Sección 4.11 del prompt).
/// - Barra superior (.nav): botón atrás, título "Detalle" y botón editar.
/// - Hero (.mv-hero): ícono de categoría grande (56×56, radio 19), monto en 36/800
///   (verde si es ingreso, ink si es gasto) y nombre del comercio o persona.
/// - Tarjeta de propiedades (.card + .kv): Categoría, Fecha, Espacio, Recurrente,
///   Origen de pago, Registrado, Nota y Etiquetas.
/// - Tarjeta de límite de categoría (si tiene límite configurado).
/// - Ubicación en mapa interactivo (si se capturó).
/// - Texto original de la notificación bancaria.
/// - Barra fija inferior (.mv-dock): botones "Comparar" y "Editar".
/// - Acción de eliminar destructiva con confirmación modal (`ConfirmSheet`).
class MovementDetailScreen extends ConsumerStatefulWidget {
  const MovementDetailScreen({super.key, required this.id, this.onClose});

  final String id;

  /// Si el detalle se muestra incrustado (p. ej. como panel sobre Inicio en
  /// horizontal), esto lo cierra en lugar de salir de la pantalla.
  final VoidCallback? onClose;

  @override
  ConsumerState<MovementDetailScreen> createState() => _MovementDetailScreenState();
}

class _MovementDetailScreenState extends ConsumerState<MovementDetailScreen> {
  bool _locating = false;

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(expensesStateProvider).where((e) => e.id == widget.id).firstOrNull;
    final aliases = ref.watch(aliasesProvider);
    final hidden = ref.watch(balanceHiddenProvider);

    if (m == null) {
      return Scaffold(
        backgroundColor: MgColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(context),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Este movimiento ya no existe.',
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 16,
                      color: MgColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final kind = m.entreMisCuentas ? 'Entre mis cuentas' : (m.esIngreso ? 'Ingreso' : 'Gasto');
    final isPending = m.estado == EstadoMovimiento.pendiente;
    final catColor = CategoryIcon.colorForCategory(m.category);
    final catLabel = categoryLabel(m.category);

    // Cálculos de categoría para límite
    final all = ref.watch(expensesStateProvider);
    final now = DateTime.now();
    final spentInCat = all
        .where((e) =>
            e.category == m.category &&
            e.esGastoReal &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra superior (.nav)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  _buildBackButton(context),
                  const Expanded(
                    child: Text(
                      'Detalle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.025 * 17,
                        color: MgColors.ink,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _edit(context, m),
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
                            Icons.edit_outlined,
                            size: 19,
                            color: MgColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                // Incrustado como panel, el contenido llega hasta abajo y pasa por
                // detrás de la barra flotante; este margen deja el final a la vista.
                padding: EdgeInsets.fromLTRB(18, 0, 18, widget.onClose != null ? 24 + 64 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Hero (.mv-hero)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                      child: Column(
                        children: [
                          // Ícono grande (56×56, radio 19)
                          MerchantIcon(
                            merchant: m.merchant,
                            category: m.category,
                            size: 56,
                            radius: 19,
                            iconSize: 26,
                          ),
                          const SizedBox(height: 14),

                          // Monto en 36/800 (.mv-amt)
                          if (hidden)
                            Text(
                              'S/ ••••••',
                              style: AppText.money(
                                size: 36,
                                weight: FontWeight.w800,
                                color: m.esIngresoReal ? MgColors.up : MgColors.ink,
                              ).copyWith(letterSpacing: 2.0),
                            )
                          else
                            MoneyText(
                              amount: m.amount,
                              isIncome: m.esIngresoReal,
                              isExpense: m.esGastoReal,
                              style: AppText.money(
                                size: 36,
                                weight: FontWeight.w800,
                                color: m.esIngresoReal ? MgColors.up : MgColors.ink,
                              ),
                            ),
                          const SizedBox(height: 6),

                          // Nombre / Comercio
                          InkWell(
                            onTap: () => showAliasDialog(context, ref, m.merchant),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName(m.merchant, aliases),
                                    style: const TextStyle(
                                      fontFamily: AppText.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: MgColors.ink2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_note_rounded,
                                    size: 16,
                                    color: MgColors.ink3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Aviso si está pendiente
                    if (isPending) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: MgColors.accSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: MgColors.accLine, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: MgColors.acc2,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Este movimiento está pendiente de confirmación.',
                                style: TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  fontSize: 12.5,
                                  color: MgColors.ink,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(expensesStateProvider.notifier)
                                    .confirmMovimiento(m.id);
                                if (context.mounted) {
                                  MgToast.show(
                                    context,
                                    message: m.esIngreso
                                        ? 'Ingreso confirmado'
                                        : 'Gasto confirmado',
                                  );
                                }
                              },
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 3. Tarjeta de información (.card + .kv)
                    MgCard(
                      margin: const EdgeInsets.only(top: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          _buildKvRow(
                            icon: Icons.label_outline_rounded,
                            label: 'Categoría',
                            value: catLabel,
                            onTap: () => _pickCategory(context, m),
                          ),
                          _buildKvRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha',
                            value: _formatDetailDate(m.date),
                          ),
                          _buildKvRow(
                            icon: Icons.credit_card_outlined,
                            label: m.esIngreso ? 'Recibido por' : 'Pagado con',
                            value: [sourceLabel(m.source), if (m.tarjeta != null) m.tarjeta!].join(' · '),
                          ),
                          if (m.esEnOtraMoneda)
                            _buildKvRow(
                              icon: Icons.currency_exchange_rounded,
                              label: 'En dólares',
                              value: hidden
                                  ? hiddenAmount
                                  : m.tipoCambio == null
                                      ? '${formatMoneda(m.moneda!, m.montoOriginal!)} · falta el tipo de cambio'
                                      : '${formatMoneda(m.moneda!, m.montoOriginal!)} · cambio ${m.tipoCambio!.toStringAsFixed(3)}',
                            ),
                          _buildKvRow(
                            icon: Icons.history_rounded,
                            label: 'Registrado',
                            value: _channelText(m),
                          ),
                          _buildOwnTransferRow(m),
                          if (m.notes.isNotEmpty && m.notes != 'Registro manual')
                            _buildKvRow(
                              icon: Icons.sticky_note_2_outlined,
                              label: 'Nota',
                              value: m.notes,
                            ),
                        ],
                      ),
                    ),

                    // 4. Tarjeta de límite de categoría (si aplica)
                    if (m.esGasto && spentInCat > 0) ...[
                      const SizedBox(height: 12),
                      MgCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      CategoryIcon.iconForCategory(m.category),
                                      size: 15,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Gasto en ${catLabel.toLowerCase()}',
                                  style: const TextStyle(
                                    fontFamily: AppText.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: MgColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ProgressBar(
                              percent: (spentInCat / (spentInCat + 300)).clamp(0.0, 1.0),
                              color: catColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Llevas ${formatSoles(spentInCat)} gastados este mes',
                              style: const TextStyle(
                                fontFamily: AppText.fontFamily,
                                fontSize: 11.5,
                                color: MgColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 5. Ubicación en mapa
                    const SizedBox(height: 12),
                    if (m.tieneUbicacion) ...[
                      _MapCard(movimiento: m),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ref
                              .read(expensesStateProvider.notifier)
                              .removeLocation(m.id),
                          child: Text(
                            'Quitar ubicación de este ${kind.toLowerCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MgColors.down,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      _addLocationRow(context, m),

                    // 6. Texto original de notificación
                    if (m.textoOriginal.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text(
                            'Texto original detectado',
                            style: TextStyle(
                              fontFamily: AppText.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MgColors.ink2,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: MgColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MgColors.borderTenue,
                                  width: 1,
                                ),
                              ),
                              child: SelectableText(
                                m.textoOriginal,
                                style: const TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  fontSize: 12,
                                  color: MgColors.ink3,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 7. Botones inferiores (.mv-dock)
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => showMovementComparison(context, m),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: MgColors.soft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.compare_arrows_rounded,
                                      size: 18,
                                      color: MgColors.ink,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Comparar',
                                      style: TextStyle(
                                        fontFamily: AppText.fontFamily,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: MgColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _edit(context, m),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: MgColors.acc,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: MgColors.acc.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Editar',
                                      style: TextStyle(
                                        fontFamily: AppText.fontFamily,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Botón Eliminar
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(context, m),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: MgColors.down,
                        ),
                        label: Text(
                          'Eliminar $kind',
                          style: const TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MgColors.down,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _close,
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
              Icons.arrow_back_rounded,
              size: 19,
              color: MgColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  /// «Entre mis cuentas»: una transferencia a otra cuenta tuya no suma a gastos ni ingresos.
  Widget _buildOwnTransferRow(Movimiento m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, size: 17, color: MgColors.ink3),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entre mis cuentas',
                  style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 12.5, color: MgColors.ink2),
                ),
                SizedBox(height: 2),
                Text(
                  'No suma a gastos ni ingresos',
                  style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 11, color: MgColors.ink3),
                ),
              ],
            ),
          ),
          Switch(
            value: m.entreMisCuentas,
            onChanged: (v) => ref
                .read(expensesStateProvider.notifier)
                .updateExpense(m.copyWith(entreMisCuentas: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildKvRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 17, color: MgColors.ink3),
            const SizedBox(width: 11),
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 12.5,
                  color: MgColors.ink2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: MgColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: MgColors.ink3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDetailDate(DateTime d) {
    final text = DateFormat("EEEE d 'de' MMMM, HH:mm", 'es').format(d);
    return toBeginningOfSentenceCase(text)!;
  }

  String _channelText(Movimiento m) {
    switch (m.canal) {
      case CanalMovimiento.notificacion:
        return m.source == PaymentSource.googlePay
            ? 'Automático (Google Wallet)'
            : 'Automático (Notificación)';
      case CanalMovimiento.wallet:
        return 'Automático (Apple Wallet)';
      case CanalMovimiento.captura:
        return 'Desde captura';
      case CanalMovimiento.manual:
        return 'Manual';
    }
  }

  Widget _addLocationRow(BuildContext context, Movimiento m) {
    return MgCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: _locating ? null : () => _addLocation(context, m),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20, color: MgColors.ink2),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar ubicación',
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: MgColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Usa tu ubicación actual solo para este pago',
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 11.5,
                      color: MgColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            if (_locating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 18, color: MgColors.ink3),
          ],
        ),
      ),
    );
  }

  Future<void> _addLocation(BuildContext context, Movimiento m) async {
    final service = ref.read(locationServiceProvider);
    final notifier = ref.read(expensesStateProvider.notifier);
    setState(() => _locating = true);
    final result = await service.captureCurrent();
    if (!mounted) return;
    setState(() => _locating = false);

    final location = result.location;
    if (location != null) {
      await notifier.setLocation(m.id, location);
      return;
    }
    if (context.mounted) {
      MgToast.show(context, message: result.message);
    }
  }

  void _pickCategory(BuildContext context, Movimiento m) {
    var remember = m.esGasto;
    final propias = ref.read(customCategoriesProvider).where((c) => c.tipo == m.tipo).toList();

    showAdaptiveSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => MgSheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Cambiar categoría',
                  style: TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                  ),
                ),
                if (m.esGasto)
                  CheckboxListTile(
                    value: remember,
                    onChanged: (v) => setSheet(() => remember = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: MgColors.acc,
                    title: Text(
                      'Aplicar a todos los pagos de «${displayName(m.merchant, ref.read(aliasesProvider))}»',
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 12.5,
                        color: MgColors.ink2,
                      ),
                    ),
                  ),
                for (final cat in Categoria.paraTipo(m.tipo))
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CategoryIcon(category: cat, size: 34),
                    title: Text(
                      categoryLabel(cat),
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 14,
                        color: MgColors.ink,
                      ),
                    ),
                    trailing: m.categoriaPropia == null && cat == m.category
                        ? const Icon(Icons.check_rounded, color: MgColors.acc, size: 20)
                        : null,
                    onTap: () {
                      ref
                          .read(expensesStateProvider.notifier)
                          .changeCategory(m.id, cat, remember: remember);
                      Navigator.pop(context);
                    },
                  ),
                for (final p in propias)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Icon(customIconFor(p.icono), color: MgColors.acc2),
                    title: Text(
                      p.nombre,
                      style: const TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 14,
                        color: MgColors.ink,
                      ),
                    ),
                    trailing: m.categoriaPropia == p.id
                        ? const Icon(Icons.check_rounded, color: MgColors.acc, size: 20)
                        : null,
                    onTap: () {
                      ref
                          .read(expensesStateProvider.notifier)
                          .changeCategory(m.id, p.base, remember: remember, propia: p.id);
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.add_circle_outline_rounded, color: MgColors.acc),
                  title: const Text(
                    'Nueva categoría',
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MgColors.acc2,
                    ),
                  ),
                  onTap: () async {
                    final created = await showNewCategorySheet(context, ref, m.tipo);
                    if (created == null) return;
                    ref
                        .read(expensesStateProvider.notifier)
                        .changeCategory(m.id, created.base, remember: remember, propia: created.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _edit(BuildContext context, Movimiento m) {
    final merchant = TextEditingController(text: m.merchant);
    final amount = TextEditingController(text: m.amount.toStringAsFixed(2));
    final notes = TextEditingController(
        text: m.notes == 'Registro manual' ? '' : m.notes);

    showAdaptiveSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MgSheet(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar ${m.esIngreso ? 'ingreso' : 'gasto'}',
                style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MgColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              MgField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hintText: 'S/ 0.00',
                labelText: 'Monto',
              ),
              const SizedBox(height: 10),
              MgField(
                controller: merchant,
                labelText: m.esIngreso ? 'De quién' : 'Comercio',
              ),
              const SizedBox(height: 10),
              MgField(
                controller: notes,
                labelText: 'Nota (opcional)',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MgColors.acc,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final value = double.tryParse(amount.text.replaceAll(',', '.'));
                  if (value == null || value <= 0 || merchant.text.trim().isEmpty) return;
                  ref.read(expensesStateProvider.notifier).updateExpense(m.copyWith(
                        amount: value,
                        merchant: merchant.text.trim(),
                        notes: notes.text.trim(),
                      ));
                  Navigator.pop(context);
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => disposeControllersLater([merchant, amount, notes]));
  }

  Future<void> _confirmDelete(BuildContext context, Movimiento m) async {
    final kind = m.esIngreso ? 'ingreso' : 'gasto';
    final aliases = ref.read(aliasesProvider);

    final ok = await ConfirmSheet.show(
      context,
      title: '¿Eliminar $kind?',
      message:
          'Se borrará «${displayName(m.merchant, aliases)}» por ${formatSoles(m.amount)} de tu historial.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (ok != true || !context.mounted) return;

    final notifier = ref.read(expensesStateProvider.notifier);
    await notifier.deleteExpense(m.id);
    if (!context.mounted) return;
    _close();
    MgToast.show(
      context,
      message: '${kind[0].toUpperCase()}${kind.substring(1)} eliminado',
      actionLabel: 'Deshacer',
      onAction: () => notifier.restoreExpense(m),
    );
  }
}

/// Tarjeta pequeña con mapa, dirección y precisión.
class _MapCard extends StatelessWidget {
  const _MapCard({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final point = LatLng(m.latitud!, m.longitud!);
    final address = m.lugar ?? '${m.latitud!.toStringAsFixed(5)}, ${m.longitud!.toStringAsFixed(5)}';
    final precision = m.precision == null ? '' : ' · precisión ±${m.precision!.round()} m';

    return MgCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Env.hasMapsKey)
              SizedBox(
                height: 120,
                child: IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: point, zoom: 16),
                    markers: {Marker(markerId: const MarkerId('pago'), position: point)},
                    liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: MgColors.ink2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address,
                          style: const TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: MgColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ubicación del teléfono$precision',
                          style: const TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 11.5,
                            color: MgColors.ink2,
                          ),
                        ),
                      ],
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
