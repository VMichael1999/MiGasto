import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../../data/services/nlp_classifier_service.dart';

/// Splash Screen profesional y minimalista de MiGasto con estética premium dark fintech:
/// Icono 3D de cristal líquido flotante, auroras ambientales aterciopeladas
/// y tipografía limpia de alta gama (sin barras de progreso ni ondas ruidosas).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Secuencia de entrada y salida
  late final AnimationController _mainAnim;
  
  // Levitación sutil y respiración orgánica de luz
  late final AnimationController _floatAnim;

  // Curvas de animación (principios Apple / Emil Kowalski)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _exitFade;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _mainAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _floatAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // Entrada del logo: desaceleración fluida tipo Apple (de 0.92 a 1.0)
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnim,
        curve: const Interval(0.0, 0.42, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _mainAnim,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );

    // Entrada de tipografía con sutil desplazamiento vertical
    _contentFade = CurvedAnimation(
      parent: _mainAnim,
      curve: const Interval(0.24, 0.58, curve: Curves.easeOut),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainAnim,
        curve: const Interval(0.24, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // Transición suave de salida
    _exitFade = CurvedAnimation(
      parent: _mainAnim,
      curve: const Interval(0.88, 1.0, curve: Curves.easeInOutCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Inicializar base de datos y modelo NLP en segundo plano durante el splash
    final dbInit = () async {
      try {
        final db = ref.read(localDatabaseProvider);
        await NlpClassifierService.loadFromAsset();
        await db.init();
        ref.read(expensesStateProvider.notifier);
      } catch (_) {}
    }();

    await _mainAnim.forward();
    await dbInit;

    _navigateNext();
  }

  void _navigateNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final prefs = ref.read(sharedPreferencesProvider);
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!onboardingComplete) {
      context.go('/onboarding');
    } else if (!isLoggedIn) {
      context.go('/login');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _mainAnim.dispose();
    _floatAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060A),
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateNext,
          child: AnimatedBuilder(
            animation: _exitFade,
            builder: (context, child) {
              final exitOpacity = (1.0 - _exitFade.value).clamp(0.0, 1.0);
              return Opacity(
                opacity: exitOpacity,
                child: child,
              );
            },
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // 1. Auroras ambientales de fondo aterciopeladas
                _buildAtmosphericBackdrop(),

                // 2. Núcleo de Marca: Icono 3D puro flotante + Tipografía refinada
                Center(
                  child: _buildBrandHero(),
                ),

                // 3. Pie minimalista y discreto
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 44,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: _buildMinimalFooter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fondo con iluminación atmosférica difusa y elegante (obsidiana con halos violeta y cian)
  Widget _buildAtmosphericBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, _) {
              final f = _floatAnim.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Luz ambiental superior violeta
                  Positioned(
                    left: -40 + (f * 25),
                    top: -60 - (f * 20),
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x507C5CFF),
                            Color(0x007C5CFF),
                          ],
                          stops: [0.0, 0.70],
                        ),
                      ),
                    ),
                  ),
                  // Luz ambiental inferior cian sutil
                  Positioned(
                    right: -50 - (f * 25),
                    bottom: -50 + (f * 25),
                    child: Container(
                      width: 360,
                      height: 360,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x3022D3EE),
                            Color(0x0022D3EE),
                          ],
                          stops: [0.0, 0.70],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Núcleo heroico: Icono 3D de cristal líquido con física de levitación y tipografía limpia
  Widget _buildBrandHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnim, _floatAnim]),
      builder: (context, _) {
        // Desplazamiento sinusoidal suave de levitación (±4 px)
        final floatOffset = math.sin(_floatAnim.value * math.pi) * 4.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono 3D de cristal líquido flotante con resplandor óptico trasero
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Resplandor difuso suave detrás del ticket (sin bordes)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                        blurRadius: 70,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
                        blurRadius: 50,
                        spreadRadius: 6,
                        offset: const Offset(10, 10),
                      ),
                    ],
                  ),
                ),

                // Icono 3D puro flotando con desaceleración elástica elegante
                Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: SizedBox(
                        width: 176,
                        height: 176,
                        child: Image.asset(
                          'assets/brand/logo_3d.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 72,
                              color: Color(0xFF7C5CFF),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Tipografía de marca (estilo Apple / Linear)
            SlideTransition(
              position: _contentSlide,
              child: Opacity(
                opacity: _contentFade.value,
                child: Column(
                  children: const [
                    Text(
                      'MiGasto',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1.1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Finanzas personales inteligentes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0x99FFFFFF),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Pie de página ultra-minimalista y refinado
  Widget _buildMinimalFooter() {
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2FD98A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '100% privado y en tu dispositivo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
