import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';

/// Estado de permisos del lector de notificaciones y probador de textos.
/// El rediseño no lo muestra en Resumen; se reubica en Ajustes.
void showNotificationStatusDialog(BuildContext context, WidgetRef ref) {
  final permissions = ref.read(permissionsCheckerProvider);
  final testerController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<List<bool>>(
            future: Future.wait([
              permissions.isAccessibilityEnabled(),
              permissions.isOverlayGranted(),
            ]),
            builder: (context, snapshot) {
              final isAccess = snapshot.data?[0] ?? false;
              final isOverlay = snapshot.data?[1] ?? false;

              return AlertDialog(
                backgroundColor: AppTheme.cardBg,
                title: const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppTheme.neonGreen),
                    SizedBox(width: 10),
                    Text(
                      'Lector de Notificaciones',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1B26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isAccess ? Icons.check_circle : Icons.error,
                                  color: isAccess ? Colors.greenAccent : Colors.orangeAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAccess ? 'Servicio de Accesibilidad activo' : 'Servicio de Accesibilidad inactivo',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  isOverlay ? Icons.check_circle : Icons.error,
                                  color: isOverlay ? Colors.greenAccent : Colors.orangeAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isOverlay ? 'Permiso de Superposición concedido' : 'Permiso de Superposición pendiente',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isAccess)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await permissions.openAccessibilitySettings();
                            Future.delayed(const Duration(seconds: 1), () {
                              if (context.mounted) setDialogState(() {});
                            });
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Activar Accesibilidad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      if (!isOverlay) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await permissions.requestOverlayPermission();
                            Future.delayed(const Duration(seconds: 1), () {
                              if (context.mounted) setDialogState(() {});
                            });
                          },
                          icon: const Icon(Icons.layers_outlined),
                          label: const Text('Conceder Superposición'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Simular Entrada de Notificación',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: testerController,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Juan te yapeó S/ 15.00',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E2B3B))),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final text = testerController.text.trim();
                          if (text.isNotEmpty) {
                            permissions.simulateNotification(text);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Probar Lector', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
