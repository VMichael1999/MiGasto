import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/adaptive.dart';
import '../../core/theme/mg_colors.dart';
import '../../data/services/auth_service.dart';
import '../auth/account_link.dart';
import '../providers.dart';

/// Pantalla «Crea tu cuenta»: nombre, correo y contraseña, o Google/Apple.
/// Los movimientos que ya haya en el teléfono se quedan y pasan a la cuenta.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _submitted = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_submitted) return null;
    final e = _email.text.trim();
    return (e.contains('@') && e.contains('.')) ? null : 'Escribe un correo válido.';
  }

  String? get _passwordError {
    if (!_submitted) return null;
    return _password.text.length >= 6 ? null : 'Usa 6 o más caracteres.';
  }

  String? get _repeatError {
    if (!_submitted) return null;
    return _repeat.text == _password.text ? null : 'Las contraseñas no coinciden.';
  }

  Future<void> _run(Future<AuthAccount> Function(AuthService) action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      final account = await action(ref.read(authServiceProvider));
      await applyAccount(ref, account);
      // Si escribió su nombre y la cuenta no lo trae, se guarda en el perfil.
      if (ref.read(profileNameProvider).trim().isEmpty && _name.text.trim().isNotEmpty) {
        await ref.read(profileNameProvider.notifier).updateValue(_name.text.trim());
      }
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      if (mounted && !e.cancelled) setState(() => _serverError = e.message);
    } catch (_) {
      if (mounted) setState(() => _serverError = 'No se pudo completar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _create() {
    setState(() => _submitted = true);
    if (_emailError != null || _passwordError != null || _repeatError != null) return;
    _run((a) => a.createWithEmail(_email.text.trim(), _password.text, name: _name.text));
  }

  void _backToLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    final header = <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: _backToLogin,
          tooltip: 'Volver',
          style: IconButton.styleFrom(backgroundColor: MgColors.soft),
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: MgColors.ink),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Crea tu cuenta',
        style: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          color: MgColors.ink,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Tus movimientos siguen contigo: lo que ya registraste pasa a tu cuenta.',
        style: TextStyle(fontSize: 14, color: MgColors.ink2, height: 1.4),
      ),
      const SizedBox(height: 24),
    ];
    final form = <Widget>[
      _field('Nombre (opcional)', Icons.person_outline_rounded, _name,
          capitalization: TextCapitalization.words),
      const SizedBox(height: 14),
      _field('Correo', Icons.mail_outline_rounded, _email,
          keyboard: TextInputType.emailAddress, error: _emailError),
      const SizedBox(height: 14),
      _field('Contraseña', Icons.lock_outline_rounded, _password,
          obscure: _obscure, error: _passwordError, suffix: _eye()),
      const SizedBox(height: 14),
      _field('Repite la contraseña', Icons.lock_outline_rounded, _repeat,
          obscure: _obscure, error: _repeatError, onSubmitted: (_) => _create()),
      if (_serverError != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_serverError!,
              style: const TextStyle(fontSize: 12.5, color: MgColors.down)),
        ),
      const SizedBox(height: 20),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _busy ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: MgColors.acc,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Crear cuenta'),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('o regístrate con', style: TextStyle(fontSize: 12, color: MgColors.ink3)),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          if (Platform.isIOS) ...[
            Expanded(
              child: _oauth(
                Image.asset('assets/icons/apple_logo.png', width: 17, height: 17),
                'Apple',
                () => _run((a) => a.signInWithApple()),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _oauth(
              Image.asset('assets/icons/google_logo.png', width: 18, height: 18),
              'Google',
              () => _run((a) => a.signInWithGoogle()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text('¿Ya tienes cuenta? ',
              style: TextStyle(fontSize: 13, color: MgColors.ink2)),
          GestureDetector(
            onTap: _backToLogin,
            child: const Text('Inicia sesión',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: MgColors.acc2)),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: context.isLandscapePhone
            ? Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: header,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 32, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: form,
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...header, ...form],
                ),
              ),
      ),
    );
  }

  Widget _eye() => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _obscure = !_obscure),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: MgColors.ink3,
          ),
        ),
      );

  Widget _field(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    String? error,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w500, color: MgColors.ink2)),
        const SizedBox(height: 7),
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: MgColors.soft,
            borderRadius: BorderRadius.circular(16),
            border: error == null ? null : Border.all(color: MgColors.down.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: MgColors.ink3),
              const SizedBox(width: 11),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboard,
                  textCapitalization: capitalization,
                  onSubmitted: onSubmitted,
                  onChanged: (_) {
                    if (_submitted) setState(() {});
                  },
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w500, color: MgColors.ink),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(error, style: const TextStyle(fontSize: 11.5, color: MgColors.down)),
          ),
      ],
    );
  }

  Widget _oauth(Widget leading, String label, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: MgColors.soft,
          foregroundColor: MgColors.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [leading, const SizedBox(width: 8), Text(label)],
        ),
      ),
    );
  }
}
