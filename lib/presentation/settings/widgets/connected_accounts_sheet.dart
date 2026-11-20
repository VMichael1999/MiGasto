import 'package:flutter/material.dart';
import '../../../core/theme/mg_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/mg_toast.dart';

class BankAccountItem {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  bool isConnected;
  final bool isManualOnly;

  BankAccountItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isConnected = true,
    this.isManualOnly = false,
  });
}

class ConnectedAccountsSheet extends StatefulWidget {
  const ConnectedAccountsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ConnectedAccountsSheet(),
    );
  }

  @override
  State<ConnectedAccountsSheet> createState() => _ConnectedAccountsSheetState();
}

class _ConnectedAccountsSheetState extends State<ConnectedAccountsSheet> {
  final List<BankAccountItem> _accounts = [
    BankAccountItem(
      id: 'bcp',
      name: 'BCP (Banco de Crédito)',
      subtitle: 'Lectura de notificaciones activa',
      icon: Icons.account_balance_rounded,
      iconBg: const Color(0x22002A8F),
      iconColor: const Color(0xFF3370FF),
      isConnected: true,
    ),
    BankAccountItem(
      id: 'interbank',
      name: 'Interbank',
      subtitle: 'Lectura de notificaciones activa',
      icon: Icons.credit_card_rounded,
      iconBg: const Color(0x22009B3A),
      iconColor: const Color(0xFF05C46B),
      isConnected: true,
    ),
    BankAccountItem(
      id: 'bbva',
      name: 'BBVA Continental',
      subtitle: 'Lectura de notificaciones activa',
      icon: Icons.account_balance_rounded,
      iconBg: const Color(0x22004481),
      iconColor: const Color(0xFF1E88E5),
      isConnected: true,
    ),
    BankAccountItem(
      id: 'yape',
      name: 'Yape',
      subtitle: 'Captura de comprobantes activa',
      icon: Icons.bolt_rounded,
      iconBg: const Color(0x22742284),
      iconColor: const Color(0xFFB538FA),
      isConnected: true,
    ),
    BankAccountItem(
      id: 'plin',
      name: 'Plin',
      subtitle: 'Captura de pagos por QR activa',
      icon: Icons.qr_code_2_rounded,
      iconBg: const Color(0x2200B4D8),
      iconColor: const Color(0xFF00C7F2),
      isConnected: true,
    ),
    BankAccountItem(
      id: 'scotiabank',
      name: 'Scotiabank',
      subtitle: 'Sincronización pausada',
      icon: Icons.account_balance_rounded,
      iconBg: const Color(0x22ED1C24),
      iconColor: const Color(0xFFFF5252),
      isConnected: false,
    ),
    BankAccountItem(
      id: 'cash',
      name: 'Billetera Efectivo',
      subtitle: 'Registro manual',
      icon: Icons.payments_outlined,
      iconBg: const Color(0x2200C48C),
      iconColor: const Color(0xFF00C48C),
      isConnected: true,
      isManualOnly: true,
    ),
  ];

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

            // Título y descripción
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
                      Icons.account_balance_outlined,
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
                        'Cuentas conectadas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MgColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bancos y billeteras monitoreados',
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

            // Aviso de privacidad y seguridad local
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MgColors.soft,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 18,
                    color: MgColors.up,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MiGasto no almacena claves ni números completos. Las operaciones se detectan leyendo notificaciones oficiales en tu teléfono.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MgColors.ink2,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Lista desplazable de cuentas
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _accounts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final acc = _accounts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: MgColors.soft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: acc.isConnected
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.02),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Icono representativo
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: acc.iconBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            acc.icon,
                            size: 19,
                            color: acc.iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nombre y estado
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: acc.isConnected ? MgColors.ink : MgColors.ink3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                acc.subtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: acc.isConnected ? MgColors.ink2 : MgColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Control interactivo
                        if (acc.isManualOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Manual',
                              style: TextStyle(
                                fontSize: 11,
                                color: MgColors.ink3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          Switch(
                            value: acc.isConnected,
                            activeTrackColor: MgColors.acc,
                            activeThumbColor: Colors.white,
                            onChanged: (val) {
                              setState(() {
                                acc.isConnected = val;
                              });
                              MgToast.show(
                                context,
                                message: val
                                    ? '${acc.name} conectada para lectura automática.'
                                    : 'Sincronización pausada para ${acc.name}.',
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Botón Agregar nueva cuenta
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                MgToast.show(
                  context,
                  message: 'Próximamente: vinculación con BanBif y Caja Piura.',
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
                'Vincular otra cuenta o banco',
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
