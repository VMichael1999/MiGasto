import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mg_colors.dart';
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
  if (ref.read(profileEmailProvider).trim().isEmpty && (account.email ?? '').isNotEmpty) {
    await ref.read(profileEmailProvider.notifier).updateValue(account.email!);
  }
  if (ref.read(profileNameProvider).trim().isEmpty && (account.name ?? '').isNotEmpty) {
    await ref.read(profileNameProvider.notifier).updateValue(account.name!);
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = await action(ref.read(authServiceProvider));
      await applyAccount(ref, account);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.hideCurrentSnackBar();
      MgToast.show(context, message: 'Cuenta vinculada. Tus datos siguen contigo.');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.cancelled ? null : e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo completar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
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
    final showApple = Platform.isIOS;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vincular cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MgColors.ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Todo lo que ya registraste se queda contigo y pasa a tu cuenta.',
            style: TextStyle(fontSize: 13, color: MgColors.ink2, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (!_emailMode) ...[
            _Option(
              icon: Icons.g_mobiledata_rounded,
              label: 'Continuar con Google',
              onTap: _busy ? null : () => _run((a) => a.signInWithGoogle()),
            ),
            if (showApple) ...[
              const SizedBox(height: 10),
              _Option(
                icon: Icons.apple_rounded,
                label: 'Continuar con Apple',
                onTap: _busy ? null : () => _run((a) => a.signInWithApple()),
              ),
            ],
            const SizedBox(height: 10),
            _Option(
              icon: Icons.mail_outline_rounded,
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MgColors.down)),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap});
  final IconData icon;
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
            children: [
              Icon(icon, size: 24, color: MgColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
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
