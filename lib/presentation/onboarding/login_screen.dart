import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/adaptive.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/widgets/mg_toast.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      await ref.read(profileEmailProvider.notifier).updateValue(email);
    }
    await ref.read(sharedPreferencesProvider).setBool('is_logged_in', true);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _loginOAuth(String provider) async {
    await ref.read(sharedPreferencesProvider).setBool('is_logged_in', true);
    if (mounted) {
      MgToast.show(context, message: 'Sesión iniciada con $provider.');
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = <Widget>[
              const SizedBox(height: 10),
              // Mark Logo (54×54 con el icono 3D oficial de MiGasto)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/brand/logo_3d.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 24,
                      color: Color(0xFF7C5CFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Título "Hola de nuevo"
              const Text(
                'Hola de nuevo',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: MgColors.ink,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),

              // Subtítulo
              const Text(
                'Entra y sigue tus gastos donde los dejaste.',
                style: TextStyle(
                  fontSize: 14,
                  color: MgColors.ink2,
                ),
              ),
              const SizedBox(height: 28),

    ];
    final form = <Widget>[
              // Campo 1: Correo
              _buildInputBox(
                label: 'Correo',
                icon: Icons.account_balance_outlined,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: MgColors.ink,
                  ),
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
              const SizedBox(height: 16),

              // Campo 2: Contraseña
              _buildInputBox(
                label: 'Contraseña',
                icon: Icons.shield_outlined,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: MgColors.ink,
                  ),
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
                    hintText: 'Tu contraseña',
                    hintStyle: TextStyle(color: MgColors.ink3),
                  ),
                ),
                suffix: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: MgColors.ink3,
                    ),
                  ),
                ),
              ),

              // Enlace "¿Olvidaste tu contraseña?"
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () {
                      MgToast.show(context, message: 'Te enviaríamos un correo para cambiarla.');
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: MgColors.acc2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Botón primario: Ingresar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MgColors.acc,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Ingresar'),
                ),
              ),
              const SizedBox(height: 22),

              // Separador "o entra con"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o entra con',
                      style: TextStyle(
                        fontSize: 12,
                        color: MgColors.ink3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botones OAuth: Apple y Google con logos oficiales
              Row(
                children: [
                  Expanded(
                    child: _buildOAuthButton(
                      leading: Image.asset(
                        'assets/icons/apple_logo.png',
                        width: 17,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                      label: 'Apple',
                      onTap: () => _loginOAuth('Apple'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildOAuthButton(
                      leading: Image.asset(
                        'assets/icons/google_logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                      label: 'Google',
                      onTap: () => _loginOAuth('Google'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Pie de página: "¿Primera vez? Crea tu cuenta"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Primera vez? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: MgColors.ink2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      MgToast.show(context, message: 'Crearías tu cuenta.');
                    },
                    child: const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MgColors.acc2,
                      ),
                    ),
                  ),
                ],
              ),
    ];
    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: context.isLandscapePhone
            // Horizontal: bienvenida a la izquierda y formulario a la derecha.
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
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...header, ...form],
                ),
              ),
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required IconData icon,
    required Widget child,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: MgColors.ink2,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: MgColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: MgColors.ink3),
              const SizedBox(width: 11),
              Expanded(child: child),
              if (suffix != null) suffix,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOAuthButton({
    Widget? leading,
    IconData? icon,
    required String label,
    double iconSize = 18,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: MgColors.soft,
          foregroundColor: MgColors.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null)
              leading
            else if (icon != null)
              Icon(icon, size: iconSize, color: MgColors.ink),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
