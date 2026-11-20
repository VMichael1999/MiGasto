import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MigastoAvatarState {
  idle,
  thinking,
  speaking,
}

/// Avatar de MiGastoIA basado en las especificaciones de Bible Strong Avatar Lab.
///
/// Implementa:
/// - Geometría 3D de cápsula/esfera con shader de luz esférico y brillo especular.
/// - Oídos de sensor en lila neón (#9B82FF) y antena de gema cian (#00F0FF).
/// - Estado `idle`: Respiración suave, parpadeo periódico natural cada ~3.5 s.
/// - Estado `thinking`: Inclinación reflexiva de la cabeza (~7° estilo `Idle_B`),
///   mirada hacia arriba a un lado (`upward-side-glance`), y ondas de partículas/puntos
///   de pensamiento pulsantes con halo neón interactivo.
class MigastoAvatar extends StatefulWidget {
  final double size;
  final MigastoAvatarState state;
  final bool animate;
  final VoidCallback? onTap;

  const MigastoAvatar({
    super.key,
    this.size = 40,
    this.state = MigastoAvatarState.idle,
    this.animate = true,
    this.onTap,
  });

  @override
  State<MigastoAvatar> createState() => _MigastoAvatarState();
}

class _MigastoAvatarState extends State<MigastoAvatar>
    with TickerProviderStateMixin {
  late AnimationController _idleAnim;
  late AnimationController _blinkAnim;
  late AnimationController _thinkingAnim;

  @override
  void initState() {
    super.initState();
    // 1. Respiración y flotación suave (periodo 3 s)
    _idleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 2. Parpadeo orgánico (cada ~3.8 s parpadea rápidamente)
    _blinkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scheduleNextBlink();

    // 3. Onda de pensamiento y pulso activo
    _thinkingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  void _scheduleNextBlink() {
    if (!mounted) return;
    final delay = 2800 + (math.Random().nextInt(1400));
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _blinkAnim.forward(from: 0.0).then((_) {
        if (!mounted) return;
        _blinkAnim.reverse().then((_) {
          _scheduleNextBlink();
        });
      });
    });
  }

  @override
  void dispose() {
    _idleAnim.dispose();
    _blinkAnim.dispose();
    _thinkingAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleAnim, _blinkAnim, _thinkingAnim]),
        builder: (context, child) {
          final isThinking = widget.state == MigastoAvatarState.thinking;

          // En thinking: inclinación de la cabeza de ~7 grados, como el clip Idle_B de Avatar Lab
          final headTilt = isThinking
              ? -0.12 + 0.03 * math.sin(_thinkingAnim.value * 2 * math.pi)
              : 0.02 * math.sin(_idleAnim.value * 2 * math.pi);

          // Respiración vertical
          final breathY = isThinking
              ? 1.5 * math.sin(_thinkingAnim.value * 2 * math.pi)
              : 2.2 * math.sin(_idleAnim.value * 2 * math.pi);

          // Cierre del párpado (0 = abierto, 1 = cerrado)
          final lidProgress = _blinkAnim.value;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Halo de energía en estado thinking
                if (isThinking)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFF).withValues(
                              alpha: 0.25 + 0.15 * math.sin(_thinkingAnim.value * 2 * math.pi),
                            ),
                            blurRadius: widget.size * 0.45,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(
                              alpha: 0.20 + 0.10 * math.cos(_thinkingAnim.value * 2 * math.pi),
                            ),
                            blurRadius: widget.size * 0.35,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Avatar renderizado en Canvas personalizado 3D
                Transform.translate(
                  offset: Offset(0, breathY),
                  child: Transform.rotate(
                    angle: headTilt,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _MigastoAvatarPainter(
                        isThinking: isThinking,
                        lidProgress: lidProgress,
                        thinkingProgress: _thinkingAnim.value,
                      ),
                    ),
                  ),
                ),

                // Partículas / Puntos de pensamiento flotantes arriba a la derecha (estilo Avatar Lab 'dots' spinner)
                if (isThinking)
                  Positioned(
                    top: -widget.size * 0.18,
                    right: -widget.size * 0.12,
                    child: _ThinkingDotsBubble(
                      progress: _thinkingAnim.value,
                      avatarSize: widget.size,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja los 3 puntos de pensamiento en órbita/ola suave
class _ThinkingDotsBubble extends StatelessWidget {
  final double progress;
  final double avatarSize;

  const _ThinkingDotsBubble({
    required this.progress,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final dotBase = avatarSize * 0.10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (progress + (i * 0.25)) % 1.0;
        final scale = 0.65 + 0.5 * math.sin(phase * math.pi);
        final opacity = 0.4 + 0.6 * math.sin(phase * math.pi);
        final color = i == 2
            ? const Color(0xFF00F0FF) // Cian brillante
            : i == 1
                ? const Color(0xFFB8A4FF) // Violeta claro
                : const Color(0xFF7C5CFF); // Púrpura MiGasto

        return Container(
          margin: EdgeInsets.only(
            left: 2,
            right: 2,
            bottom: 4 * math.sin(phase * math.pi),
          ),
          width: dotBase * scale,
          height: dotBase * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Pintor customizado para renderizar el personaje con iluminación 3D,
/// gradientes holográficos, ojos de cristal y sensores.
class _MigastoAvatarPainter extends CustomPainter {
  final bool isThinking;
  final double lidProgress;
  final double thinkingProgress;

  _MigastoAvatarPainter({
    required this.isThinking,
    required this.lidProgress,
    required this.thinkingProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Sensores laterales (Oídos esféricos / auriculares #9B82FF)
    final earRadius = w * 0.15;
    final leftEarCenter = Offset(w * 0.14, h * 0.50);
    final rightEarCenter = Offset(w * 0.86, h * 0.50);

    final earPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFB8A4FF), Color(0xFF9B82FF), Color(0xFF5B3DE0)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: leftEarCenter, radius: earRadius));

    final earStroke = Paint()
      ..color = const Color(0xFF1E1B2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);

    // Oído izquierdo
    canvas.drawCircle(leftEarCenter, earRadius, earPaint);
    canvas.drawCircle(leftEarCenter, earRadius, earStroke);

    // Oído derecho
    earPaint.shader = const RadialGradient(
      colors: [Color(0xFFB8A4FF), Color(0xFF9B82FF), Color(0xFF5B3DE0)],
      stops: [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: rightEarCenter, radius: earRadius));
    canvas.drawCircle(rightEarCenter, earRadius, earPaint);
    canvas.drawCircle(rightEarCenter, earRadius, earStroke);

    // Anillos de luz cian en los oídos
    final earRingPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: isThinking ? 0.9 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.025);
    canvas.drawCircle(leftEarCenter, earRadius * 0.55, earRingPaint);
    canvas.drawCircle(rightEarCenter, earRadius * 0.55, earRingPaint);

    // 2. Antena / Gema superior (Antenna Gem #00F0FF)
    final antennaCenter = Offset(w / 2, h * 0.08);
    final antennaRadius = w * 0.09;
    final antennaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFF00F0FF),
          const Color(0xFF0091FF),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: antennaCenter, radius: antennaRadius));

    canvas.drawCircle(antennaCenter, antennaRadius, antennaPaint);
    canvas.drawCircle(antennaCenter, antennaRadius, earStroke);

    // Conector de la antena
    final connectorPath = Path()
      ..moveTo(w / 2 - w * 0.04, h * 0.14)
      ..lineTo(w / 2 + w * 0.04, h * 0.14)
      ..lineTo(w / 2 + w * 0.025, h * 0.22)
      ..lineTo(w / 2 - w * 0.025, h * 0.22)
      ..close();
    canvas.drawPath(
      connectorPath,
      Paint()..color = const Color(0xFF7C5CFF),
    );
    canvas.drawPath(connectorPath, earStroke);

    // 3. Cuerpo principal (Cápsula esférica 3D)
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + h * 0.04),
      width: w * 0.70,
      height: h * 0.76,
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.35),
    );

    // Gradiente 3D con luz superior izquierda simulando volumen
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF9E86FF), // Brillo superior
          Color(0xFF7C5CFF), // Violeta MiGasto
          Color(0xFF5B3DE0), // Sombra inferior
          Color(0xFF351C9E), // Oclusión profunda
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(bodyRect);

    // Sombra proyectada del cuerpo
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(bodyRRect.shift(Offset(0, h * 0.04)), shadowPaint);

    // Dibuja el cuerpo
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Brillo especular superior del casco (Glossy 3D rim)
    final highlightRect = Rect.fromCenter(
      center: Offset(center.dx - w * 0.06, center.dy - h * 0.15),
      width: w * 0.42,
      height: h * 0.22,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(highlightRect);
    canvas.drawOval(highlightRect, highlightPaint);

    // Contorno exterior estilizado del cuerpo
    final bodyOutlinePaint = Paint()
      ..color = const Color(0xFF1E1B2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.04);
    canvas.drawRRect(bodyRRect, bodyOutlinePaint);

    // 4. Ojos expresivos (Face / Eyes)
    // En thinking: la mirada se desplaza arriba y a la derecha (upward-side-glance)
    final eyeOffsetX = isThinking ? w * 0.04 : 0.0;
    final eyeOffsetY = isThinking ? -h * 0.05 : 0.0;

    final eyeWidth = w * 0.11;
    final baseEyeHeight = isThinking ? h * 0.15 : h * 0.19;
    // Efecto de parpadeo (interpola la altura del ojo hacia 0)
    final effectiveHeight = math.max(1.5, baseEyeHeight * (1.0 - lidProgress));

    final eyeSpacing = w * 0.14;
    final leftEyeCenter = Offset(
      center.dx - eyeSpacing + eyeOffsetX,
      center.dy + eyeOffsetY + h * 0.02,
    );
    final rightEyeCenter = Offset(
      center.dx + eyeSpacing + eyeOffsetX,
      center.dy + eyeOffsetY + h * 0.02,
    );

    // Shader de los ojos: Cian neón brillante con reflejo holográfico
    final eyeShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE0FFFF), // Brillo blanco cian
        Color(0xFF00F0FF), // Cian turquesa intenso
        Color(0xFF00A3FF), // Profundidad
      ],
      stops: [0.0, 0.45, 1.0],
    );

    final leftEyeRect = Rect.fromCenter(
      center: leftEyeCenter,
      width: eyeWidth,
      height: effectiveHeight,
    );
    final rightEyeRect = Rect.fromCenter(
      center: rightEyeCenter,
      width: eyeWidth,
      height: effectiveHeight,
    );

    final eyePaint = Paint()
      ..shader = eyeShader.createShader(leftEyeRect);

    // Resplandor de los ojos (Eye Glow)
    final eyeGlowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(RRect.fromRectAndRadius(leftEyeRect, Radius.circular(eyeWidth / 2)), eyeGlowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightEyeRect, Radius.circular(eyeWidth / 2)), eyeGlowPaint);

    // Dibujar ojos
    final eyeRRectLeft = RRect.fromRectAndRadius(leftEyeRect, Radius.circular(eyeWidth / 2));
    final eyeRRectRight = RRect.fromRectAndRadius(rightEyeRect, Radius.circular(eyeWidth / 2));
    canvas.drawRRect(eyeRRectLeft, eyePaint);
    canvas.drawRRect(eyeRRectRight, eyePaint);

    // Reflejo blanco especular en cada ojo (si los ojos están abiertos)
    if (lidProgress < 0.6) {
      final specPaint = Paint()..color = Colors.white;
      final specRadius = eyeWidth * 0.22;
      canvas.drawCircle(
        Offset(leftEyeCenter.dx + eyeWidth * 0.15, leftEyeCenter.dy - effectiveHeight * 0.22),
        specRadius,
        specPaint,
      );
      canvas.drawCircle(
        Offset(rightEyeCenter.dx + eyeWidth * 0.15, rightEyeCenter.dy - effectiveHeight * 0.22),
        specRadius,
        specPaint,
      );
    }

    // 5. Boca curva discreta
    if (lidProgress < 0.8) {
      final mouthY = center.dy + h * 0.18 + (isThinking ? -h * 0.02 : 0);
      final mouthWidth = isThinking ? w * 0.08 : w * 0.10;
      final mouthPath = Path();

      if (isThinking) {
        // En thinking: boquita reflexiva ligeramente ovalada / ladeada
        mouthPath.moveTo(center.dx - mouthWidth * 0.4, mouthY);
        mouthPath.quadraticBezierTo(
          center.dx + mouthWidth * 0.2,
          mouthY + h * 0.02,
          center.dx + mouthWidth * 0.6,
          mouthY - h * 0.005,
        );
      } else {
        // En normal: sonrisa sutil
        mouthPath.moveTo(center.dx - mouthWidth / 2, mouthY);
        mouthPath.quadraticBezierTo(
          center.dx,
          mouthY + h * 0.025,
          center.dx + mouthWidth / 2,
          mouthY,
        );
      }

      final mouthPaint = Paint()
        ..color = const Color(0xFF1E1B2E)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.2, w * 0.035);
      canvas.drawPath(mouthPath, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MigastoAvatarPainter oldDelegate) {
    return oldDelegate.isThinking != isThinking ||
        oldDelegate.lidProgress != lidProgress ||
        oldDelegate.thinkingProgress != thinkingProgress;
  }
}

/// Widget acompañante de onda sonora / pensamiento para la burbuja de chat
class ThinkingWaveDots extends StatefulWidget {
  const ThinkingWaveDots({super.key});

  @override
  State<ThinkingWaveDots> createState() => _ThinkingWaveDotsState();
}

class _ThinkingWaveDotsState extends State<ThinkingWaveDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + (index * 0.22)) % 1.0;
            // Curva sinusoidal suave
            final bounce = math.sin(phase * math.pi);
            final scale = 0.6 + 0.5 * bounce;
            final alpha = 0.4 + 0.6 * bounce;

            final color = index == 2
                ? const Color(0xFF00F0FF) // Cian
                : index == 1
                    ? const Color(0xFF9B82FF) // Lavanda
                    : const Color(0xFF7C5CFF); // Púrpura MiGasto

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5 * alpha),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
