import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/movimiento.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _budgetController = TextEditingController();
  final _simTextController = TextEditingController();
  
  bool _isAccessibilityEnabled = false;
  bool _isOverlayGranted = false;

  @override
  void initState() {
    super.initState();
    _budgetController.text = ref.read(budgetProvider).toStringAsFixed(0);
    _checkNativePermissions();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _simTextController.dispose();
    super.dispose();
  }

  Future<void> _checkNativePermissions() async {
    final access = await ref.read(permissionsCheckerProvider).isAccessibilityEnabled();
    final overlay = await ref.read(permissionsCheckerProvider).isOverlayGranted();
    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = access;
        _isOverlayGranted = overlay;
      });
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentEmail) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isNotEmpty && email.isNotEmpty) {
                  ref.read(profileNameProvider.notifier).updateValue(name);
                  ref.read(profileEmailProvider.notifier).updateValue(email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado')),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    final repo = ref.read(expenseRepositoryProvider);
    final overrides = repo.getAllCategoryOverrides();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final list = overrides.entries.toList();
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              title: const Text('Categorías Aprendidas (IA)', style: TextStyle(color: Colors.white)),
              content: list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Aún no hay comercios aprendidos por la IA.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFF25232F)),
                        itemBuilder: (context, index) {
                          final entry = list[index];
                          final merchant = entry.key;
                          final categoryStr = entry.value;
                          final cat = Categoria.values.firstWhere((c) => c.name == categoryStr, orElse: () => Categoria.otros);
                          final catColor = AppTheme.getCategoryColor(cat);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              merchant.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              AppTheme.getCategoryNameEs(cat),
                              style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                await repo.deleteCategoryOverride(merchant);
                                setDialogState(() {
                                  overrides.remove(merchant);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Clasificación para "$merchant" eliminada')),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
              actions: [
                if (list.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await repo.clearAllCategoryOverrides();
                      setDialogState(() {
                        overrides.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todas las clasificaciones aprendidas han sido eliminadas')),
                      );
                    },
                    child: const Text('Limpiar Todo', style: TextStyle(color: Colors.redAccent)),
                  ),
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
  }

  void _showSourcesDialog(BuildContext context) {
    final expenses = ref.read(expensesStateProvider).where((e) => e.isConfirmed && e.esGasto).toList();
    
    final sourceCounts = <PaymentSource, int>{};
    final sourceTotals = <PaymentSource, double>{};
    for (final exp in expenses) {
      sourceCounts[exp.source] = (sourceCounts[exp.source] ?? 0) + 1;
      sourceTotals[exp.source] = (sourceTotals[exp.source] ?? 0.0) + exp.amount;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Cuentas y Fuentes', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: PaymentSource.values.map((src) {
                final count = sourceCounts[src] ?? 0;
                final total = sourceTotals[src] ?? 0.0;
                
                Color color;
                String name;
                switch (src) {
                  case PaymentSource.yape:
                    color = AppTheme.yapePurple;
                    name = 'Yape';
                    break;
                  case PaymentSource.plin:
                    color = AppTheme.plinTeal;
                    name = 'Plin';
                    break;
                  case PaymentSource.googlePay:
                    color = AppTheme.googlePayBlue;
                    name = 'Google Pay';
                    break;
                  default:
                    color = AppTheme.manualGray;
                    name = 'Registro Manual';
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color,
                    radius: 14,
                    child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('$count transacciones', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: Text('S/ ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                );
              }).toList(),
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
  }

  void _showBackupDialog(BuildContext context) {
    final expenses = ref.read(expensesStateProvider).where((e) => e.isConfirmed && e.esGasto).toList();
    
    // Generate CSV
    final csvBuf = StringBuffer();
    csvBuf.writeln('ID,Fecha,Establecimiento,Monto,Categoria,Fuente,Notas');
    for (final exp in expenses) {
      csvBuf.writeln(
        '${exp.id},'
        '${exp.date.toIso8601String()},'
        '"${exp.merchant.replaceAll('"', '""')}",'
        '${exp.amount.toStringAsFixed(2)},'
        '${exp.category.name},'
        '${exp.source.name},'
        '"${exp.notes.replaceAll('"', '""')}"'
      );
    }
    final csvText = csvBuf.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Respaldo y Sincronización', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hemos generado un respaldo en formato CSV con tus ${expenses.length} transacciones confirmadas.',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131219),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvText.isEmpty ? 'Sin transacciones para respaldar.' : csvText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.greenAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (expenses.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: csvText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Respaldo CSV copiado al portapapeles')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16, color: AppTheme.neonGreen),
                label: const Text('Copiar CSV', style: TextStyle(color: AppTheme.neonGreen)),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respaldo exportado al portapapeles')),
                );
              },
              child: const Text('Sincronizar ahora', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(providersEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final profileName = ref.watch(profileNameProvider);
    final profileEmail = ref.watch(profileEmailProvider);
    final passcodeEnabled = ref.watch(passcodeEnabledProvider);

    // Dynamic initials
    final initials = profileName.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
    final initialsToShow = initials.length > 2 ? initials.substring(0, 2) : initials;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // PROFILE HEADER CARD (Screen 6 Mockup)
          Card(
            color: AppTheme.cardBg,
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.neonGreen,
                child: Text(
                  initialsToShow.isNotEmpty ? initialsToShow : 'U',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                profileName.isNotEmpty ? profileName : 'Configurar Nombre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: profileName.isNotEmpty ? Colors.white : Colors.grey[500],
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                profileEmail.isNotEmpty ? profileEmail : 'correo@ejemplo.com',
                style: TextStyle(
                  color: profileEmail.isNotEmpty ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
              onTap: () => _showEditProfileDialog(context, profileName, profileEmail),
            ),
          ),
          const SizedBox(height: 16),

          // BUDGET ADJUSTER
          Card(
            color: AppTheme.cardBg,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Presupuesto mensual',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: 'S/ ',
                            labelText: 'Límite',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final newLimit = double.tryParse(_budgetController.text) ?? 1200.0;
                          ref.read(expensesStateProvider.notifier).updateBudget(newLimit);
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Presupuesto actualizado')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Guardar'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DETECCIÓN AUTOMÁTICA CARD (Screen 6 Mockup)
          Card(
            color: AppTheme.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Detección automática',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: Colors.white),
                  title: const Text('Notificaciones', style: TextStyle(fontSize: 14, color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAccessibilityEnabled ? 'Activado' : 'Configurar',
                        style: TextStyle(
                          color: _isAccessibilityEnabled ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(permissionsCheckerProvider).openAccessibilitySettings();
                    Future.delayed(const Duration(seconds: 2), _checkNativePermissions);
                  },
                ),
                const Divider(height: 1, color: Color(0xFF25232F)),
                ListTile(
                  leading: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
                  title: const Text('Accesibilidad (OCR)', style: TextStyle(fontSize: 14, color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOverlayGranted ? 'Activado' : 'Permitir',
                        style: TextStyle(
                          color: _isOverlayGranted ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(permissionsCheckerProvider).requestOverlayPermission();
                    Future.delayed(const Duration(seconds: 2), _checkNativePermissions);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PROVIDER TOGGLES
          Card(
            color: AppTheme.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Aplicaciones Activas',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                ),
                SwitchListTile(
                  value: providers['yape'] ?? false,
                  title: const Text('Yape', style: TextStyle(fontSize: 14)),
                  activeColor: AppTheme.yapePurple,
                  onChanged: (_) {
                    ref.read(providersEnabledProvider.notifier).toggleProvider('yape');
                  },
                ),
                const Divider(height: 1, color: Color(0xFF25232F)),
                SwitchListTile(
                  value: providers['plin'] ?? false,
                  title: const Text('Plin', style: TextStyle(fontSize: 14)),
                  activeColor: AppTheme.plinTeal,
                  onChanged: (_) {
                    ref.read(providersEnabledProvider.notifier).toggleProvider('plin');
                  },
                ),
                const Divider(height: 1, color: Color(0xFF25232F)),
                SwitchListTile(
                  value: providers['googlePay'] ?? false,
                  title: const Text('Google Pay', style: TextStyle(fontSize: 14)),
                  activeColor: AppTheme.googlePayBlue,
                  onChanged: (_) {
                    ref.read(providersEnabledProvider.notifier).toggleProvider('googlePay');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PERSONALIZACIÓN CARD (Screen 6 Mockup)
          Card(
            color: AppTheme.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Personalización',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.style_outlined, color: Colors.white),
                  title: const Text('Categorías', style: TextStyle(fontSize: 14, color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  onTap: () => _showCategoriesDialog(context),
                ),
                const Divider(height: 1, color: Color(0xFF25232F)),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                  title: const Text('Cuentas y fuentes', style: TextStyle(fontSize: 14, color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  onTap: () => _showSourcesDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GENERAL CARD (Screen 6 Mockup)
          Card(
            color: AppTheme.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'General',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sync_outlined, color: Colors.white),
                  title: const Text('Respaldo y sincronización', style: TextStyle(fontSize: 14, color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  onTap: () => _showBackupDialog(context),
                ),
                const Divider(height: 1, color: Color(0xFF25232F)),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline, color: Colors.white),
                  title: const Text('Bloqueo de PIN (Simulado)', style: TextStyle(fontSize: 14, color: Colors.white)),
                  subtitle: const Text('(Próximamente)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: passcodeEnabled,
                  activeColor: AppTheme.neonGreen,
                  onChanged: (_) {
                    ref.read(passcodeEnabledProvider.notifier).toggle();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bloqueo PIN ${!passcodeEnabled ? "activado" : "desactivado"}')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SANDBOX SIMULATOR AREA
          if (kDebugMode) Card(
            color: colorScheme.primary.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report_outlined, color: AppTheme.neonGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Simulador OCR / Notificaciones',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simula un mensaje para ver en tiempo real la categorización por IA y activar el panel flotante.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  
                  // Examples chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickSimChip('☕ Starbucks S/ 18.50', 'Yapeaste S/ 18.50 a Starbucks Coffee'),
                      _buildQuickSimChip('🚕 Uber S/ 15.00', 'Plin: Recibiste S/ 15.00 de Pedro Uber'),
                      _buildQuickSimChip('🛒 Metro S/ 89.20', 'Compra Google Pay de S/ 89.20 en Metro Limatambo'),
                      _buildQuickSimChip('🍿 Netflix S/ 44.90', 'Cargo Google Pay S/ 44.90 a Netflix Peru'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _simTextController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje de Notificación',
                      hintText: 'Ej: Yape S/ 25.50 a Tambo',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text = _simTextController.text.trim();
                      if (text.isEmpty) return;

                      // Parse amount
                      final amtReg = RegExp(r's/\.?\s*(\d+(?:\.\d{2})?)', caseSensitive: false);
                      final amtMatch = amtReg.firstMatch(text);
                      final amount = amtMatch != null ? double.tryParse(amtMatch.group(1) ?? '0.0') : null;

                      // Parse merchant
                      final merchantReg = RegExp(r'(?:a|de|en)\s+([a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+)', caseSensitive: false);
                      final merchantMatch = merchantReg.firstMatch(text);
                      var merchant = merchantMatch != null ? merchantMatch.group(1)?.trim() : 'Negocio Desconocido';
                      merchant = merchant?.replaceAll(RegExp(r'\s+por.*$'), '');

                      // Provider
                      var provider = 'manual';
                      if (text.toLowerCase().contains('yape')) {
                        provider = 'yape';
                      } else if (text.toLowerCase().contains('plin')) {
                        provider = 'plin';
                      } else if (text.toLowerCase().contains('google pay') || text.toLowerCase().contains('gpay')) {
                        provider = 'googlePay';
                      }

                      if (amount != null && amount > 0) {
                        ref.read(expensesStateProvider.notifier).triggerIncomingPayment(
                              amount: amount,
                              merchant: merchant ?? 'Establecimiento',
                              providerStr: provider,
                              rawText: text,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulación activada en fondo')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Incluye un monto ej: S/ 15.00'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Procesar y Simular'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickSimChip(String label, String text) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: const Color(0xFF131219),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onPressed: () {
        setState(() {
          _simTextController.text = text;
        });
      },
    );
  }
}
