import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/mg_busy_overlay.dart';
import '../../core/widgets/mg_sheet.dart';
import '../../core/widgets/mg_toast.dart';
import '../../data/services/auth_service.dart';
import '../providers.dart';

/// Deja la app asociada a [account]: pasa de invitado a cuenta y completa el perfil.
/// Los movimientos no se copian ni se mueven: ya viven en el teléfono y siguen ahí.
Future<void> applyAccount(WidgetRef ref, AuthAccount account) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('auth_uid', account.uid);
  await prefs.setBool('is_logged_in', true);
  await ref.read(authModeProvider.notifier).set('account');
  // Lo que se completa desde la cuenta se recuerda, para quitarlo al cerrar sesión
  // y que el siguiente invitado no vea los datos de otra persona.
  if (ref.read(profileEmailProvider).trim().isEmpty && (account.email ?? '').isNotEmpty) {
    await ref.read(profileEmailProvider.notifier).updateValue(account.email!);
    await prefs.setBool(profileEmailFromAccountKey, true);
  }
  if (ref.read(profileNameProvider).trim().isEmpty && (account.name ?? '').isNotEmpty) {
    await ref.read(profileNameProvider.notifier).updateValue(account.name!);
    await prefs.setBool(profileNameFromAccountKey, true);
  }
}

const profileEmailFromAccountKey = 'profile_email_from_account';
const profileNameFromAccountKey = 'profile_name_from_account';

/// El usuario editó su perfil a mano: ya es suyo y no se borra al cerrar sesión.
Future<void> markProfileAsOwn(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.remove(profileEmailFromAccountKey);
  await prefs.remove(profileNameFromAccountKey);
}

/// Cierra la sesión de la cuenta y vuelve a modo invitado. Los movimientos se
/// quedan en el teléfono; solo se quitan los datos de perfil que vinieron de la cuenta.
Future<void> signOutAccount(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final service = ref.read(authServiceProvider);
  final current = service.current;
  try {
    await service.signOut();
  } catch (e) {
    debugPrint('No se pudo cerrar la sesión en el servidor: $e');
  }
  // También se quita lo que coincide con los datos de la cuenta (sesiones de antes de las marcas).
  final sameEmail = (current?.email ?? '').isNotEmpty &&
      ref.read(profileEmailProvider).trim().toLowerCase() == current!.email!.toLowerCase();
  final sameName = (current?.name ?? '').isNotEmpty &&
      ref.read(profileNameProvider).trim() == current!.name!.trim();
  if (sameEmail || (prefs.getBool(profileEmailFromAccountKey) ?? false)) {
    await ref.read(profileEmailProvider.notifier).updateValue('');
  }
  if (sameName || (prefs.getBool(profileNameFromAccountKey) ?? false)) {
    await ref.read(profileNameProvider.notifier).updateValue('');
  }
  await markProfileAsOwn(ref);
  await prefs.remove('auth_uid');
  await ref.read(authModeProvider.notifier).set('guest');
}

/// Resultado de un intento de iniciar sesión, crear o vincular una cuenta.
/// Si [account] es nulo y [error] también, el usuario canceló la ventana del proveedor.
class AuthOutcome {
  const AuthOutcome({this.account, this.error});
  final AuthAccount? account;
  final String? error;
  bool get ok => account != null;
}

/// Corre [action] sin dejar escapar ningún error: devuelve la cuenta ya aplicada
/// a la app o un mensaje listo para mostrar. Tiene tiempo límite para que una
/// conexión colgada no deje la pantalla esperando para siempre.
Future<AuthOutcome> attemptAuth(
  WidgetRef ref,
  Future<AuthAccount> Function() action,
) async {
  try {
    final account = await action().timeout(const Duration(minutes: 2));
    await applyAccount(ref, account);
    return AuthOutcome(account: account);
  } on AuthException catch (e) {
    return AuthOutcome(error: e.cancelled ? null : e.message);
  } on TimeoutException {
    return const AuthOutcome(error: 'Tardó demasiado. Revisa tu conexión e intenta de nuevo.');
  } catch (e) {
    debugPrint('Fallo de autenticación: $e');
    return const AuthOutcome(error: 'No se pudo completar. Intenta de nuevo.');
  }
}

/// Hoja «Vincular cuenta» del perfil: Google, Apple (solo iPhone) o correo.
/// Devuelve `true` si el usuario quedó vinculado.
Future<bool> showLinkAccountSheet(BuildContext context) async {
  final linked = await MgSheet.show<bool>(
    context: context,
    child: const _LinkAccountSheet(),
  );
  return linked == true;
}

class _LinkAccountSheet extends ConsumerStatefulWidget {
  const _LinkAccountSheet();

  @override
  ConsumerState<_LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends ConsumerState<_LinkAccountSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailMode = false;
  bool _creating = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AuthAccount> Function(AuthService) action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(authServiceProvider);
    final outcome = await attemptAuth(ref, () => action(service));
    if (!mounted) return;
    if (outcome.ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.hideCurrentSnackBar();
      MgToast.show(context, message: 'Cuenta vinculada. Tus datos siguen contigo.');
    } else {
      setState(() {
        _busy = false;
        _error = outcome.error;
      });
    }
  }

  void _submitEmail() {
    final email = _email.text.trim();
    final pass = _password.text;
    if (!email.contains('@') || pass.length < 6) {
      setState(() => _error = 'Escribe un correo válido y una contraseña de 6 o más caracteres.');
      return;
    }
    _run((a) => _creating ? a.createWithEmail(email, pass) : a.signInWithEmail(email, pass));
  }

  @override
  Widget build(BuildContext context) {
    final showApple = kAppleSignInEnabled && Platform.isIOS;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vincular cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MgColors.ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Todo lo que ya registraste se queda contigo y pasa a tu cuenta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: MgColors.ink2, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (!_emailMode) ...[
            _Option(
              leading: Image.asset('assets/icons/google_logo.png', width: 22, height: 22, fit: BoxFit.contain),
              label: 'Continuar con Google',
              onTap: _busy ? null : () => _run((a) => a.signInWithGoogle()),
            ),
            if (showApple) ...[
              const SizedBox(height: 10),
              _Option(
                leading: Image.asset('assets/icons/apple_logo.png', width: 20, height: 20, fit: BoxFit.contain),
                label: 'Continuar con Apple',
                onTap: _busy ? null : () => _run((a) => a.signInWithApple()),
              ),
            ],
            const SizedBox(height: 10),
            _Option(
              leading: const Icon(Icons.mail_outline_rounded, size: 22, color: MgColors.ink),
              label: 'Usar correo y contraseña',
              onTap: _busy ? null : () => setState(() => _emailMode = true),
            ),
          ] else ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: MgColors.ink),
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: MgColors.ink),
              decoration: const InputDecoration(labelText: 'Contraseña'),
              onSubmitted: (_) => _submitEmail(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _busy ? null : _submitEmail,
                style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                child: Text(_creating ? 'Crear cuenta y vincular' : 'Entrar y vincular'),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _creating = !_creating),
                  child: Text(_creating ? 'Ya tengo cuenta' : 'Crear una cuenta nueva'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _emailMode = false),
                  child: const Text('Otras opciones'),
                ),
              ],
            ),
          ],
          if (_error != null) _ErrorNote(_error!),
        ],
      ),
    );
    return MgBusyOverlay(
      busy: _busy,
      message: _creating && _emailMode ? 'Creando tu cuenta…' : 'Vinculando tu cuenta…',
      child: content,
    );
  }
}

/// Aviso de error dentro de un formulario: visible, con icono y a todo el ancho.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MgColors.down.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MgColors.down.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 17, color: MgColors.down),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, height: 1.35, color: MgColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.leading, required this.label, required this.onTap});
  final Widget leading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MgColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MgColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 24, child: Center(child: leading)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: MgColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
