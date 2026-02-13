import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores del template Stitch (Onboarding 2 - Pedidos fáciles)
const Color _kBackgroundDark = Color(0xFF0F1923);
const Color _kPrimary = Color(0xFF3399FF);

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _spinController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        SafeArea(
          child: Column(
            children: [
              // Ilustración central
              Expanded(
                flex: 2,
                child: _buildIllustration(context),
              ),
              // Textos
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = MediaQuery.of(context).size.width;
                  final isSmall = w < 360;
                  final titleSize = isSmall ? 24.0 : (w < 400 ? 26.0 : 28.0);
                  final bodySize = isSmall ? 14.0 : 16.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 24 : 32,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // Título: "Pide en un" + "par de clics" con subrayado curvo (como HTML)
                        Column(
                          children: [
                            Text(
                              'Pide en un',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'par de clics',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: _kPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  height: 8,
                                  child: CustomPaint(
                                    painter: _CurvedUnderlinePainter(color: _kPrimary.withOpacity(0.3)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Elige tu antojo, confirma tu ubicación y espera a que aterrice en tu puerta.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: bodySize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Espacio para barra de navegación del padre
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: _kBackgroundDark,
      child: Stack(
        children: [
          // space-bg: radial top center
          Positioned(
            top: 0,
            left: size.width * 0.5 - size.width * 0.6,
            child: Container(
              width: size.width * 1.2,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    _kPrimary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          // space-bg: radial bottom right
          Positioned(
            right: -size.width * 0.4,
            bottom: -size.height * 0.2,
            child: Container(
              width: size.width,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360 || size.height < 600;
    final scale = isSmallScreen ? 0.8 : (size.width / 400).clamp(0.9, 1.05);
    // HTML: glow 64, ring 72, dashed 22rem(352), center 64, planet 32
    final glowSize = 256.0 * scale;
    final ringSize = 288.0 * scale;
    final dashedSize = 352.0 * scale;
    final centerSize = 128.0 * scale;
    final orbSizes = [64.0 * scale, 56.0 * scale, 48.0 * scale]; // burger, pizza, taco

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow (w-64 h-64 = 256, blur)
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final pulse = 0.5 + 0.15 * math.sin(_floatController.value * math.pi);
            return Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kPrimary.withOpacity(0.2 * pulse),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            );
          },
        ),
        // Anillo sólido (w-72 h-72)
        Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary.withOpacity(0.1)),
          ),
        ),
        // Anillo dashed (22rem) con rotación
        AnimatedBuilder(
          animation: _spinController,
          builder: (context, _) {
            return Transform.rotate(
              angle: _spinController.value * 2 * math.pi,
              child: SizedBox(
                width: dashedSize,
                height: dashedSize,
                child: CustomPaint(
                  painter: _DashedCirclePainter(color: _kPrimary.withOpacity(0.2)),
                ),
              ),
            );
          },
        ),
        // Composición central (w-64 h-64)
        SizedBox(
          width: 256 * scale,
          height: 256 * scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Planeta/portal central (w-32 h-32)
              Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kPrimary, const Color(0xFF1E3A5F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.rocket_launch,
                  size: centerSize * 0.5,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              // Burger: -top-4 right-4, rotate-12 (HTML)
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  final float = 10 * math.sin(_floatController.value * math.pi);
                  return Positioned(
                    top: -16 * scale + float,
                    right: 16 * scale,
                    child: Transform.rotate(
                      angle: 12 * math.pi / 180,
                      child: _buildFoodOrb('🍔', orbSizes[0]),
                    ),
                  );
                },
              ),
              // Pizza: bottom-0 -left-2, -rotate-12
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  final float = 8 * math.sin(_floatController.value * math.pi + 1);
                  return Positioned(
                    bottom: float,
                    left: -8 * scale,
                    child: Transform.rotate(
                      angle: -12 * math.pi / 180,
                      child: _buildFoodOrb('🍕', orbSizes[1]),
                    ),
                  );
                },
              ),
              // Taco: bottom-8 -right-6, rotate-6
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  final float = 6 * math.sin(_floatController.value * math.pi + 2);
                  return Positioned(
                    bottom: 32 * scale - float,
                    right: -24 * scale,
                    child: Transform.rotate(
                      angle: 6 * math.pi / 180,
                      child: _buildFoodOrb('🌮', orbSizes[2]),
                    ),
                  );
                },
              ),
              // Partículas (HTML positions)
              Positioned(top: 0, left: 40 * scale, child: _particle(8 * scale, 0.6)),
              Positioned(bottom: 40 * scale, right: 80 * scale, child: _particle(6 * scale, 0.4)),
              Positioned(top: 120 * scale, right: -32 * scale, child: _particle(4 * scale, 0.8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodOrb(String emoji, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _kBackgroundDark,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _particle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pinta un círculo punteado para el anillo orbital
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dashLength = 8.0;
    const gapLength = 6.0;
    final radius = size.width / 2 - 0.5;
    final center = Offset(size.width / 2, size.height / 2);
    var angle = 0.0;
    while (angle < 2 * math.pi) {
      final startAngle = angle;
      angle += dashLength / radius;
      final sweepAngle = (dashLength / radius).clamp(0.0, 2 * math.pi - startAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      angle += gapLength / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subrayado curvo como en HTML (path M0 5 Q 50 10 100 5)
class _CurvedUnderlinePainter extends CustomPainter {
  final Color color;

  _CurvedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

