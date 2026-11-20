import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/mg_colors.dart';
import '../../core/layout/adaptive.dart';
import '../../core/widgets/charts.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final _slides = const [
    _OnbData(
      titleLine1: 'Mira a dónde',
      titleAccent: 'se va tu plata',
      subtitle: 'Cada gasto en su categoría y el mes entero en una sola pantalla.',
      artType: 'dona',
    ),
    _OnbData(
      titleLine1: 'Ponle un límite',
      titleAccent: 'a cada cosa',
      subtitle: 'Te avisamos cuánto te queda antes de que registres el gasto, no después.',
      artType: 'barras',
    ),
    _OnbData(
      titleLine1: 'Pregúntale',
      titleAccent: 'a MiGastoIA',
      subtitle: '«¿En qué gasto de más?» y te responde con tus propios números.',
      artType: 'chat',
    ),
  ];

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  /// Las láminas terminan en el paso de privacidad y permisos; la bienvenida
  /// se da por completa recién allí.
  void _finish() => context.go('/permisos');

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08070C),
      body: Stack(
        children: [
          // Auroras difusas de fondo
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Stack(
              children: [
                Positioned(
                  left: -80,
                  top: 70,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xD87C5CFF),
                          Color(0x007C5CFF),
                        ],
                        stops: [0.0, 0.68],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -100,
                  bottom: 150,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x5522D3EE),
                          Color(0x0022D3EE),
                        ],
                        stops: [0.0, 0.68],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón Saltar en la parte superior derecha
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 18),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.5),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Saltar'),
                ),
              ),
            ),
          ),

          // PageView con el arte y los textos
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final texts = <Widget>[
                      // Título con acento violeta
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.9,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: '${slide.titleLine1}\n'),
                            TextSpan(
                              text: slide.titleAccent,
                              style: const TextStyle(
                                color: MgColors.acc2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Párrafo descriptivo
                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
              ];
              if (context.isLandscapePhone) {
                // Horizontal: el arte a la izquierda y los textos a la derecha.
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 320,
                              height: 300,
                              child: Center(child: _buildArt(slide.artType)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            // Deja libre el pie con los puntos y el botón.
                            padding: const EdgeInsets.only(bottom: 90),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: texts,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      // Arte central (300px)
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: _buildArt(slide.artType),
                        ),
                      ),
                      const SizedBox(height: 30),

                      ...texts,
                    ],
                  ),
                ),
              );
            },
          ),

          // Pie de página fijo: Indicadores de puntos y Botón Siguiente / Comenzar
          SafeArea(
            child: Align(
              alignment: context.isLandscapePhone
                  ? Alignment.bottomRight
                  : Alignment.bottomCenter,
              child: Padding(
                padding: context.isLandscapePhone
                    ? EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width * 0.5 + 12, 0, 28, 16)
                    : const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicadores (.dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final isActive = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: isActive ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive
                                ? MgColors.acc2
                                : Colors.white.withValues(alpha: 0.22),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Botón Siguiente / Comenzar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MgColors.acc,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          _currentIndex == _slides.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el widget de arte correspondiente al slide
  Widget _buildArt(String type) {
    switch (type) {
      case 'dona':
        // Slide 1: DonutChart de 230×230 con total al centro
        return DonutChart(
          size: 230,
          strokeWidth: 22,
          segments: const [
            DonutSegment(label: 'Mercado', value: 1600, color: Color(0xFFFF5C8A)),
            DonutSegment(label: 'Comida', value: 900, color: Color(0xFFF5A524)),
            DonutSegment(label: 'Transporte', value: 400, color: Color(0xFF22D3EE)),
            DonutSegment(label: 'Servicios', value: 368.8, color: Color(0xFF7C5CFF)),
            DonutSegment(label: 'Suscripciones', value: 149.7, color: Color(0xFFFF8A3D)),
          ],
          centerWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'S/ 3.418,50',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'este mes',
                style: TextStyle(
                  fontSize: 11,
                  color: MgColors.ink2,
                ),
              ),
            ],
          ),
        );

      case 'barras':
        // Slide 2: 4 barras de límites de categorías
        final limits = [
          ('Mercado', Icons.shopping_cart_outlined, const Color(0xFFFF5C8A), 0.75, 'S/ 400,00'),
          ('Restaurantes', Icons.restaurant_outlined, const Color(0xFFF5A524), 0.60, 'S/ 360,00'),
          ('Transporte', Icons.directions_bus_outlined, const Color(0xFF22D3EE), 0.40, 'S/ 240,00'),
          ('Gasto hormiga', Icons.bug_report_outlined, const Color(0xFF60A5FA), 0.85, 'S/ 45,00'),
        ];
        return SizedBox(
          width: 270,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in limits) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: item.$3.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Icon(item.$2, size: 14, color: item.$3),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            item.$5,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: item.$4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: item.$3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'chat':
        // Slide 3: Simulación de MiGastoIA
        return SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: MgColors.acc,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '¿En qué gasto de más?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: MgColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: MgColors.ink,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Tus '),
                        TextSpan(
                          text: 'suscripciones',
                          style: TextStyle(
                            color: MgColors.acc2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' suman S/ 149,70 al mes y subieron 38 % desde agosto.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: MgColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Text(
                    'Netflix y Claude Pro son las dos más caras.',
                    style: TextStyle(
                      fontSize: 13,
                      color: MgColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _OnbData {
  const _OnbData({
    required this.titleLine1,
    required this.titleAccent,
    required this.subtitle,
    required this.artType,
  });

  final String titleLine1;
  final String titleAccent;
  final String subtitle;
  final String artType;
}
