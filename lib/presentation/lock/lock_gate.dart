import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../providers.dart';

/// Autenticación del teléfono (huella, rostro o PIN). Se reemplaza en pruebas.
final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

/// Segundos en segundo plano antes de volver a pedir el desbloqueo.
const lockGracePeriod = Duration(seconds: 30);

/// Cubre la app con una pantalla de bloqueo cuando el usuario activó el bloqueo.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool _locked = ref.read(passcodeEnabledProvider);
  bool _authenticating = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El aviso del sistema también pausa la app: se ignora mientras dura.
    if (_authenticating) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (ref.read(passcodeEnabledProvider) && away >= lockGracePeriod) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    var ok = false;
    try {
      ok = await ref.read(localAuthProvider).authenticate(
            localizedReason: 'Desbloquea MiGasto para ver tus movimientos',
          );
    } catch (_) {
      ok = false;
    }
    _authenticating = false;
    if (mounted && ok) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(passcodeEnabledProvider);
    final showLock = _locked && enabled;
    final theme = Theme.of(context);

    return Stack(
      children: [
        widget.child,
        if (showLock)
          Positioned.fill(
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 40, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('MiGasto está bloqueado', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Usa tu huella, rostro o el PIN del teléfono para entrar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(onPressed: _unlock, child: const Text('Desbloquear')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
