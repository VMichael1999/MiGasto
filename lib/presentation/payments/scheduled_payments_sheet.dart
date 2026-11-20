import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/layout/adaptive.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/widgets/category_sheet.dart';
import '../../core/widgets/mg_sheet.dart';
import '../../core/widgets/mg_toast.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/scheduled_payment.dart';
import '../../shared/dispose_later.dart';
import '../../shared/format.dart';
import '../../shared/labels.dart';
import 'scheduled_payments_providers.dart';

/// «Vence · 14 de nov.», «Vence hoy», «Vencido · 14 de nov.», «Cobro · 30 de nov.»…
String dueLabel(ScheduledPayment p, DateTime now) {
  final today = dateOnly(now);
  final due = dateOnly(p.dueDate);
  final date = DateFormat("d 'de' MMM", 'es').format(due);
  final days = due.difference(today).inDays;
  if (days < 0) return p.esIngreso ? 'Por cobrar · $date' : 'Vencido · $date';
  if (days == 0) return p.esIngreso ? 'Cobro hoy' : 'Vence hoy';
  if (days == 1) return p.esIngreso ? 'Cobro mañana' : 'Vence mañana';
  return '${p.esIngreso ? 'Cobro' : 'Vence'} · $date';
}

/// Lista completa de pagos programados, con acciones para pagar, editar,
/// quitar y agregar.
class ScheduledPaymentsSheet extends ConsumerWidget {
  const ScheduledPaymentsSheet({super.key});

  static Future<void> show(BuildContext context) =>
      MgSheet.show<void>(context: context, child: const ScheduledPaymentsSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [...ref.watch(scheduledPaymentsProvider)]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final now = DateTime.now();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.isLandscapePhone
            ? MediaQuery.sizeOf(context).height - 70
            : MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Próximos pagos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MgColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => showScheduledPaymentForm(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (all.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aún no tienes pagos ni cobros programados. Agrega el alquiler, una suscripción o tu sueldo.',
                style: TextStyle(fontSize: 13, height: 1.4, color: MgColors.ink2),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: all.length,
                separatorBuilder: (_, _) => const Divider(color: MgColors.line, height: 1),
                itemBuilder: (context, i) {
                  final p = all[i];
                  final overdue = p.isOverdue(now) && !p.esIngreso;
                  return InkWell(
                    onTap: () => showScheduledPaymentForm(context, ref, existing: p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: MgColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dueLabel(p, now)}${p.monthly ? ' · cada mes' : ''}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: overdue ? MgColors.warn : MgColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${p.esIngreso ? '+' : '−'}${formatSoles(p.amount)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.esIngreso ? MgColors.up : MgColors.ink,
                            ),
                          ),
                          IconButton(
                            tooltip: p.esIngreso ? 'Marcar como cobrado' : 'Marcar como pagado',
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 22, color: MgColors.up),
                            onPressed: () async {
                              await settleScheduledPayment(ref, p);
                              if (context.mounted) {
                                MgToast.show(
                                  context,
                                  message: p.esIngreso
                                      ? 'Cobro registrado: ${p.name}'
                                      : 'Pago registrado: ${p.name}',
                                );
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Quitar',
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 21, color: MgColors.ink3),
                            onPressed: () =>
                                ref.read(scheduledPaymentsProvider.notifier).remove(p.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Formulario para crear o editar un pago programado.
Future<void> showScheduledPaymentForm(
  BuildContext context,
  WidgetRef ref, {
  ScheduledPayment? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final amount = TextEditingController(
    text: existing == null
        ? ''
        : existing.amount.toStringAsFixed(existing.amount % 1 == 0 ? 0 : 2),
  );
  var tipo = existing?.tipo ?? TipoMovimiento.gasto;
  var category = existing?.category ?? Categoria.servicios;
  var due = dateOnly(existing?.dueDate ?? DateTime.now().add(const Duration(days: 1)));
  var monthly = existing?.monthly ?? true;
  final notifier = ref.read(scheduledPaymentsProvider.notifier);

  final saved = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: MgColors.card,
        title: Text(
          existing == null ? 'Nuevo pago o cobro' : 'Editar',
          style: const TextStyle(color: MgColors.ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final t in TipoMovimiento.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t == TipoMovimiento.gasto ? 'Pago' : 'Cobro'),
                        selected: tipo == t,
                        onSelected: (_) => setState(() {
                          tipo = t;
                          category = t == TipoMovimiento.ingreso
                              ? Categoria.sueldo
                              : Categoria.servicios;
                        }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: MgColors.ink),
                decoration: const InputDecoration(labelText: 'Nombre (ej. Netflix, Alquiler)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: MgColors.ink),
                decoration: const InputDecoration(labelText: 'Monto', prefixText: 'S/ '),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Categoría', style: TextStyle(color: MgColors.ink2, fontSize: 13)),
                trailing: Text(categoryLabel(category),
                    style: const TextStyle(color: MgColors.ink, fontWeight: FontWeight.w600)),
                onTap: () async {
                  final picked = await CategorySheet.show(ctx, selected: category, tipo: tipo);
                  if (picked != null) setState(() => category = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha', style: TextStyle(color: MgColors.ink2, fontSize: 13)),
                trailing: Text(DateFormat("d 'de' MMM yyyy", 'es').format(due),
                    style: const TextStyle(color: MgColors.ink, fontWeight: FontWeight.w600)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: due,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) setState(() => due = dateOnly(picked));
                },
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text('Se repite cada mes',
                        style: TextStyle(color: MgColors.ink2, fontSize: 13)),
                  ),
                  Switch(
                    activeThumbColor: MgColors.acc,
                    value: monthly,
                    onChanged: (v) => setState(() => monthly = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(amount.text.replaceAll(',', '.'));
              if (name.text.trim().isEmpty || value == null || value <= 0) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  if (saved == true) {
    final value = double.parse(amount.text.replaceAll(',', '.'));
    notifier.upsert(ScheduledPayment(
      id: existing?.id ?? '',
      name: name.text.trim(),
      amount: value,
      tipo: tipo,
      category: category,
      dueDate: due,
      monthly: monthly,
    ));
  }
  disposeControllersLater([name, amount]);
}
