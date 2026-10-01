import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme.dart';
import 'core/navigation/navigation.dart';
import 'data/services/nlp_classifier_service.dart';
import 'presentation/lock/lock_gate.dart';
import 'presentation/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local Spanish formatting
  await initializeDateFormatting('es', null);
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
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
  bool _dbInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final db = ref.read(localDatabaseProvider);
    await NlpClassifierService.loadFromAsset();
    await db.init();
    
    // Se crea el estado de movimientos para que cargue lo guardado en la base.
    ref.read(expensesStateProvider.notifier);
    
    if (mounted) {
      setState(() {
        _dbInitialized = true;
      });
    }
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
        if (!_dbInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
              ),
            ),
          );
        }
        return LockGate(child: child ?? const SizedBox());
      },
    );
  }
}
