import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/adaptive.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/widgets/mg_busy_overlay.dart';
import '../../data/services/auth_service.dart';
import '../providers.dart';

/// Pantalla «Recupera tu contraseña»: se escribe el correo y se envía el enlace
/// para elegir una contraseña nueva. Por seguridad no se revela si el correo existe.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  /// Correo que el usuario ya había escrito en el login.
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _sent = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_submitted) return null;
    final e = _email.text.trim();
    return (e.contains('@') && e.contains('.')) ? null : 'Escribe un correo válido.';
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    if (_emailError != null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordReset(_email.text.trim())
          .timeout(const Duration(seconds: 45));
    } on AuthException catch (e) {
      error = e.message;
    } on TimeoutException {
      error = 'Tardó demasiado. Revisa tu conexión e intenta de nuevo.';
    } catch (e) {
      debugPrint('No se pudo enviar el correo de recuperación: $e');
      error = 'No se pudo enviar el correo. Intenta de nuevo.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
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
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0x227C5CFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x447C5CFF)),
        ),
        child: Icon(
          _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
          size: 26,
          color: MgColors.acc2,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        _sent ? 'Revisa tu correo' : 'Recupera tu contraseña',
        style: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: MgColors.ink,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _sent
            ? 'Si ${_email.text.trim()} tiene una cuenta, te enviamos un enlace para elegir una contraseña nueva. Revisa también la carpeta de spam.'
            : 'Escribe el correo de tu cuenta y te enviamos un enlace para elegir una contraseña nueva.',
        style: const TextStyle(fontSize: 14, color: MgColors.ink2, height: 1.45),
      ),
      const SizedBox(height: 24),
    ];

    final form = <Widget>[
      if (!_sent) ...[
        const Text('Correo',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: MgColors.ink2)),
        const SizedBox(height: 7),
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 14, right: 12),
          decoration: BoxDecoration(
            color: MgColors.soft,
            borderRadius: BorderRadius.circular(16),
            border: _emailError == null
                ? null
                : Border.all(color: MgColors.down.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 18, color: MgColors.ink3),
              const SizedBox(width: 11),
              Expanded(
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
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
                    hintText: 'tucorreo@correo.com',
                    hintStyle: TextStyle(color: MgColors.ink3),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(_emailError!, style: const TextStyle(fontSize: 11.5, color: MgColors.down)),
          ),
        if (_error != null)
          Container(
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
                  child: Text(_error!,
                      style: const TextStyle(fontSize: 12.5, height: 1.35, color: MgColors.ink)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _busy ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: MgColors.acc,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            child: const Text('Enviar enlace'),
          ),
        ),
      ] else ...[
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _backToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: MgColors.acc,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            child: const Text('Volver a iniciar sesión'),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _sent = false),
          style: TextButton.styleFrom(foregroundColor: MgColors.ink2),
          child: const Text('No me llegó, enviar de nuevo'),
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: MgColors.bg,
      body: MgBusyOverlay(
        busy: _busy,
        message: 'Enviando el enlace…',
        child: SafeArea(
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
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 32, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: form,
                          ),
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
      ),
    );
  }
}
