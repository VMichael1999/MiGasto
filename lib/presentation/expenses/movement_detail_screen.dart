import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/services/location_service.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/big_amount.dart';
import '../../shared/widgets/category_icon.dart';
import '../providers.dart';
import 'alias_dialog.dart';

/// Abre el detalle de un movimiento.
void showExpenseDetailSheet(BuildContext context, WidgetRef ref, Movimiento movimiento) {
  context.push('/movement/${movimiento.id}');
}

class MovementDetailScreen extends ConsumerStatefulWidget {
  const MovementDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MovementDetailScreen> createState() => _MovementDetailScreenState();
}

class _MovementDetailScreenState extends ConsumerState<MovementDetailScreen> {
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(expensesStateProvider).where((e) => e.id == widget.id).firstOrNull;
    final theme = Theme.of(context);
    final aliases = ref.watch(aliasesProvider);

    if (m == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _backButton(context),
                const SizedBox(height: 24),
                Text('Este movimiento ya no existe.', style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      );
    }

    final colors = context.appColors;
    final isPending = m.estado == EstadoMovimiento.pendiente;
    final kind = m.esIngreso ? 'Ingreso' : 'Gasto';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _backButton(context),
                  Text(kind, style: theme.textTheme.bodySmall),
                  TextButton(onPressed: () => _edit(context, m), child: const Text('Editar')),
                ],
              ),
              const SizedBox(height: 14),
              _Boleta(
                children: [
                  Text(displayName(m.merchant, aliases), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  BigAmount(
                    m.amount,
                    size: 40,
                    prefix: m.esIngreso ? '+ S/' : 'S/',
                    color: m.esIngreso ? colors.income : null,
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.pendingReviewSoft,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          'Por confirmar',
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: colors.pendingReview,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _Dash(color: theme.colorScheme.outline),
                  _kv(context, 'Fecha', Text(_dateText(m.date))),
                  _kv(
                    context,
                    m.esIngreso ? 'De' : 'Para',
                    InkWell(
                      onTap: () => showAliasDialog(context, ref, m.merchant),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: AppSizes.minTouch - 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                displayName(m.merchant, aliases),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppIcon(AppIcons.chevron,
                                size: AppIconSize.small,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _kv(
                    context,
                    m.esIngreso ? 'Recibido por' : 'Pagado con',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.sourceColor(m.source.name),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            [sourceLabel(m.source), ?m.tarjeta].join(' · '),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _kv(
                    context,
                    'Categoría',
                    InkWell(
                      onTap: () => _pickCategory(context, m),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: AppSizes.minTouch - 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(categoryIcon(m.category),
                                size: AppIconSize.small, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 6),
                            Text(categoryLabel(m.category)),
                            AppIcon(AppIcons.chevron,
                                size: AppIconSize.small,
                                color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _kv(context, 'Registrado', Text(_channelText(m))),
                  if (m.notes.isNotEmpty && m.notes != 'Registro manual')
                    _kv(context, 'Nota', Text(m.notes, textAlign: TextAlign.right)),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(expensesStateProvider.notifier).confirmMovimiento(m.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text(m.esIngreso ? 'Ingreso guardado' : 'Gasto guardado')),
                    );
                  },
                  style: m.esIngreso
                      ? FilledButton.styleFrom(
                          backgroundColor: colors.income,
                          foregroundColor: theme.scaffoldBackgroundColor,
                        )
                      : null,
                  child: Text(m.esIngreso ? 'Guardar ingreso' : 'Guardar gasto'),
                ),
              ],
              const SizedBox(height: 16),
              if (m.tieneUbicacion) ...[
                _MapCard(movimiento: m),
                TextButton(
                  onPressed: () => ref.read(expensesStateProvider.notifier).removeLocation(m.id),
                  child: Text('Quitar la ubicación de este ${kind.toLowerCase()}'),
                ),
              ] else
                _addLocationRow(context, m),
              if (m.textoOriginal.isNotEmpty) ...[
                const SizedBox(height: 8),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('Texto original', style: theme.textTheme.titleSmall),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SelectableText(m.textoOriginal, style: theme.textTheme.bodySmall),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _confirmDelete(context, m),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(AppIcons.trash, size: AppIconSize.small, color: colors.budgetOver),
                      const SizedBox(width: 8),
                      Text(
                        'Eliminar ${kind.toLowerCase()}',
                        style: theme.textTheme.titleSmall!.copyWith(color: colors.budgetOver),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Volver',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.field),
          onTap: () => context.pop(),
          child: SizedBox(
            width: AppSizes.iconButton,
            height: AppSizes.iconButton,
            child: Center(child: AppIcon(AppIcons.back, color: scheme.onSurface)),
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String label, Widget value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium!
                  .copyWith(fontSize: 13.5, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Flexible(
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium!
                  .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  String _dateText(DateTime d) {
    final text = DateFormat("EEE d MMM, HH:mm", 'es').format(d);
    return text.replaceAll('.', '');
  }

  String _channelText(Movimiento m) {
    switch (m.canal) {
      case CanalMovimiento.notificacion:
        return m.source == PaymentSource.googlePay
            ? 'Automático, desde Google Wallet'
            : 'Automático, desde la notificación';
      case CanalMovimiento.wallet:
        return 'Automático, desde Wallet';
      case CanalMovimiento.captura:
        return 'Desde una captura';
      case CanalMovimiento.manual:
        return 'Manual';
    }
  }

  // ---------------------------------------------------------------- ubicación

  Widget _addLocationRow(BuildContext context, Movimiento m) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Agregar ubicación. Usa tu ubicación actual, solo ahora.',
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: _locating ? null : () => _addLocation(context, m),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  AppIcon(AppIcons.pin, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agregar ubicación', style: theme.textTheme.titleSmall),
                        Text(
                          'Usa tu ubicación actual, solo ahora.',
                          style: theme.textTheme.bodySmall!.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_locating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    AppIcon(AppIcons.chevron,
                        size: AppIconSize.small, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addLocation(BuildContext context, Movimiento m) async {
    final messenger = ScaffoldMessenger.of(context);
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        action: result.failure == LocationFailure.deniedForever
            ? SnackBarAction(label: 'Abrir ajustes', onPressed: service.openAppSettings)
            : null,
      ),
    );
  }

  // ------------------------------------------------------------------ acciones

  void _pickCategory(BuildContext context, Movimiento m) {
    var remember = m.esGasto;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                  child: Text('Categoría', style: Theme.of(context).textTheme.titleLarge),
                ),
                if (m.esGasto)
                  CheckboxListTile(
                    value: remember,
                    onChanged: (v) => setSheet(() => remember = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Aplicar a todos los pagos a ${displayName(m.merchant, ref.read(aliasesProvider))}'),
                  ),
                for (final cat in Categoria.paraTipo(m.tipo))
                  ListTile(
                    minTileHeight: AppSizes.minTouch,
                    leading: AppIcon(categoryIcon(cat),
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    title: Text(categoryLabel(cat)),
                    selected: cat == m.category,
                    onTap: () {
                      ref
                          .read(expensesStateProvider.notifier)
                          .changeCategory(m.id, cat, remember: remember);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 8),
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
            Text('Editar ${m.esIngreso ? 'ingreso' : 'gasto'}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: merchant,
              decoration: InputDecoration(labelText: m.esIngreso ? 'De quién' : 'Comercio'),
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
    ).whenComplete(() {
      merchant.dispose();
      amount.dispose();
      notes.dispose();
    });
  }

  Future<void> _confirmDelete(BuildContext context, Movimiento m) async {
    final kind = m.esIngreso ? 'ingreso' : 'gasto';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar $kind'),
        content: Text('¿Eliminar "${displayName(m.merchant, ref.read(aliasesProvider))}" por ${formatSoles(m.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.appColors.budgetOver),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final notifier = ref.read(expensesStateProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await notifier.deleteExpense(m.id);
    if (!context.mounted) return;
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${kind[0].toUpperCase()}${kind.substring(1)} de "${displayName(m.merchant, ref.read(aliasesProvider))}" eliminado'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Deshacer', onPressed: () => notifier.restoreExpense(m)),
      ),
    );
  }
}

/// Tarjeta tipo boleta, con bordes dentados arriba y abajo.
class _Boleta extends StatelessWidget {
  const _Boleta({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -9,
            height: 10,
            child: CustomPaint(painter: _ScallopPainter(surface, top: true)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -9,
            height: 10,
            child: CustomPaint(painter: _ScallopPainter(surface, top: false)),
          ),
        ],
      ),
    );
  }
}

class _ScallopPainter extends CustomPainter {
  _ScallopPainter(this.color, {required this.top});

  final Color color;
  final bool top;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 12.0;
    final y = top ? size.height : 0.0;
    for (var x = step / 2; x <= size.width - step / 2; x += step) {
      canvas.drawCircle(Offset(x, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(_ScallopPainter old) => old.color != color || old.top != top;
}

class _Dash extends StatelessWidget {
  const _Dash({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DashPainter(color),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 1), Offset(x + 4, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Mapa pequeño con la dirección y la precisión.
class _MapCard extends StatelessWidget {
  const _MapCard({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = movimiento;
    final point = LatLng(m.latitud!, m.longitud!);
    final address = m.lugar ?? '${m.latitud!.toStringAsFixed(5)}, ${m.longitud!.toStringAsFixed(5)}';
    final precision = m.precision == null ? '' : ' · precisión ±${m.precision!.round()} m';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.box - 2),
      child: Container(
        color: scheme.surface,
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AppIcon(AppIcons.pin, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address, style: theme.textTheme.titleSmall!.copyWith(fontSize: 14)),
                        Text(
                          'Ubicación del teléfono$precision',
                          style: theme.textTheme.bodySmall!.copyWith(fontSize: 12),
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
