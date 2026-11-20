import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/theme.dart';
import 'firebase_options.dart';
import 'core/navigation/navigation.dart';
import 'data/services/nlp_classifier_service.dart';
import 'presentation/lock/lock_gate.dart';
import 'presentation/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await LiquidGlassWidgets.initialize();
  } catch (_) {}
  
  // Sin conexión o sin configuración la app sigue funcionando como invitado.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  // Initialize local Spanish formatting
  await initializeDateFormatting('es', null);
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    LiquidGlassWidgets.wrap(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final ThemeData? themeOverride;
  const MyApp({super.key, this.themeOverride});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final db = ref.read(localDatabaseProvider);
    await NlpClassifierService.loadFromAsset();
    await db.init();
    ref.read(expensesStateProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MiGasto',
      debugShowCheckedModeBanner: false,
      // Claro u oscuro según el sistema.
      theme: widget.themeOverride ?? AppTheme.lightTheme,
      darkTheme: widget.themeOverride ?? AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return LockGate(child: child ?? const SizedBox());
      },
    );
  }
}
