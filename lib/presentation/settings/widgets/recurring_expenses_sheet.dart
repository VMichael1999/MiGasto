import 'package:flutter/material.dart';
import '../../../core/theme/mg_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/mg_toast.dart';
import '../../../shared/format.dart';

class RecurringItem {
  final String id;
  final String title;
  final String category;
  final String paymentMethod;
  final int billingDay;
  final double amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  bool isActive;

  RecurringItem({
    required this.id,
    required this.title,
    required this.category,
    required this.paymentMethod,
    required this.billingDay,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isActive = true,
  });
}

class RecurringExpensesSheet extends StatefulWidget {
  const RecurringExpensesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const RecurringExpensesSheet(),
    );
  }

  @override
  State<RecurringExpensesSheet> createState() => _RecurringExpensesSheetState();
}

class _RecurringExpensesSheetState extends State<RecurringExpensesSheet> {
  final List<RecurringItem> _items = [
    RecurringItem(
      id: 'netflix',
      title: 'Netflix Premium',
      category: 'Suscripciones',
      paymentMethod: 'Tarjeta Débito BCP',
      billingDay: 12,
      amount: 44.90,
      icon: Icons.movie_outlined,
      iconBg: const Color(0x22E50914),
      iconColor: const Color(0xFFFF4D4D),
    ),
    RecurringItem(
      id: 'spotify',
      title: 'Spotify Familiar',
      category: 'Suscripciones',
      paymentMethod: 'Interbank Visa',
      billingDay: 28,
      amount: 29.90,
      icon: Icons.music_note_rounded,
      iconBg: const Color(0x221DB954),
      iconColor: const Color(0xFF1ED760),
    ),
    RecurringItem(
      id: 'internet',
      title: 'Internet Movistar Fibra',
      category: 'Servicios',
      paymentMethod: 'BCP Débito',
      billingDay: 5,
      amount: 89.00,
      icon: Icons.wifi_rounded,
      iconBg: const Color(0x22019DF4),
      iconColor: const Color(0xFF29B6F6),
    ),
    RecurringItem(
      id: 'gym',
      title: 'SmartFit Plan Black',
      category: 'Salud & Deporte',
      paymentMethod: 'BBVA Continental',
      billingDay: 1,
      amount: 99.90,
      icon: Icons.fitness_center_rounded,
      iconBg: const Color(0x22FFB800),
      iconColor: const Color(0xFFFFC107),
    ),
    RecurringItem(
      id: 'gemini',
      title: 'Gemini Advanced AI',
      category: 'Tecnología',
      paymentMethod: 'BCP Débito',
      billingDay: 20,
      amount: 75.00,
      icon: Icons.auto_awesome_rounded,
      iconBg: const Color(0x227C5CFF),
      iconColor: const Color(0xFF9B82FF),
    ),
  ];

  double get _totalMonthly => _items
      .where((item) => item.isActive)
      .fold(0.0, (acc, item) => acc + item.amount);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: MgColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa de arrastre
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

            // Cabecera
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MgColors.acc.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.repeat_rounded,
                      size: 20,
                      color: MgColors.acc2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movimientos recurrentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MgColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Suscripciones y cobros fijos mensuales',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: MgColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Resumen de gasto mensual fijo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x337C5CFF), Color(0x117C5CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MgColors.acc.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL RECURRENTE DEL MES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: MgColors.acc2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatSoles(_totalMonthly),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_items.where((i) => i.isActive).length} activos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Lista de suscripciones
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: MgColors.soft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: item.isActive
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.02),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // Icono
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.iconBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            item.icon,
                            size: 19,
                            color: item.iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nombre y detalles
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: item.isActive ? MgColors.ink : MgColors.ink3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Día ${item.billingDay} • ${item.paymentMethod}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: item.isActive ? MgColors.ink2 : MgColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Monto y switch
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatSoles(item.amount),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: item.isActive ? MgColors.ink : MgColors.ink3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  item.isActive = !item.isActive;
                                });
                                MgToast.show(
                                  context,
                                  message: item.isActive
                                      ? '${item.title} reactivado.'
                                      : '${item.title} pausado.',
                                );
                              },
                              child: Text(
                                item.isActive ? 'Activo' : 'Pausado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: item.isActive ? MgColors.acc2 : MgColors.ink3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Botón Agregar
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                MgToast.show(
                  context,
                  message: 'Próximamente: añadir suscripción personalizada.',
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MgColors.acc.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.add_rounded, size: 18, color: MgColors.acc2),
              label: const Text(
                'Agregar suscripción o pago fijo',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: MgColors.acc2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
