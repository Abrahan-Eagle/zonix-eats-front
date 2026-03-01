import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';

// Colores del template Stitch (Onboarding)
const Color _kBackgroundDark = Color(0xFF0F1923);
const Color _kSpaceBlue = Color(0xFF1A2E46);
const Color _kPrimary = Color(0xFF3399FF);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final bool _isLoading = false;

  List<Widget> get onboardingPages {
    return [
      const WelcomePage(),
      const OnboardingPage1(), // Intro 1 - beneficios
      const OnboardingPage2(), // Intro 2 - pedidos fáciles
      const OnboardingPage3(), // Selección de rol (users / commerce) y punto de bifurcación por rol
    ];
  }

  void _handleNext() {
    if (_isLoading) return;

    if (_currentPage == onboardingPages.length - 1) {
      // Última página: el cierre visual del onboarding se maneja desde los
      // flujos específicos de rol (Cliente / Restaurante) en OnboardingPage3
      // y CommerceRegistrationPage. Aquí no marcamos el onboarding como
      // completado para asegurarnos de que el usuario haya creado su perfil
      // y dirección/comercio en las pantallas correspondientes.
      return;
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _handleBack() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Contenido principal
            PageView(
              controller: _controller,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: onboardingPages,
            ),

            // Barra de navegación inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Indicador de progreso
                      SmoothPageIndicator(
                        controller: _controller,
                        count: onboardingPages.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          activeDotColor: _kPrimary,
                          dotColor: _kPrimary.withValues(alpha: 0.2),
                          spacing: 8,
                          expansionFactor: 3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de navegación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      // Botón Atrás (sin opción de Saltar el onboarding completo)
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _handleBack,
                          child: const Text('Atrás'),
                        )
                      else
                        const SizedBox(width: 80),

                          // Botón Siguiente solo en las intros.
                          // En la última página (OnboardingPage3) el flujo
                          // continúa mediante el botón propio de selección de rol.
                          if (_currentPage < onboardingPages.length - 1)
                            FloatingActionButton(
                              heroTag: 'onboarding_next',
                              onPressed: _handleNext,
                              backgroundColor: theme.primaryColor,
                              elevation: 2,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                            )
                          else
                            const SizedBox(width: 56, height: 56),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo oscuro con gradiente y estrellas
        _buildBackground(context),
        // Contenido
        SafeArea(
          child: Column(
            children: [
              // Área central
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glow radial detrás del planeta
                      Expanded(
                        flex: 2,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow circular (blur)
                            Positioned(
                              top: 0,
                              child: IgnorePointer(
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 1.2,
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _kPrimary.withValues(alpha: 0.25),
                                        _kPrimary.withValues(alpha: 0),
                                      ],
                                      stops: const [0.0, 0.7],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Contenedor planeta (escala responsive)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final w = MediaQuery.of(context).size.width;
                                final scale = (w < 360 ? 0.8 : (w / 400).clamp(0.85, 1.1)).toDouble();
                                final outer = 288.0 * scale;
                                final mid = 256.0 * scale;
                                final inner = 224.0 * scale;
                                return SizedBox(
                                  width: outer,
                                  height: outer,
                                  child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Anillo exterior
                                  Container(
                                    width: outer,
                                    height: outer,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _kPrimary.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Anillo interior
                                  Container(
                                    width: mid,
                                    height: mid,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _kPrimary.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Círculo principal con imagen
                                  Container(
                                    width: inner,
                                    height: inner,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _kSpaceBlue,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kPrimary.withValues(alpha: 0.25),
                                          blurRadius: 50,
                                          offset: const Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            'assets/onboarding/onboarding_eats.png',
                                            fit: BoxFit.cover,
                                          ),
                                          // Overlay atmósfera
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _kBackgroundDark.withValues(alpha: 0.8),
                                                  Colors.transparent,
                                                  _kPrimary.withValues(alpha: 0.2),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Estrellas flotantes (dentro del área para evitar clipping)
                                  Positioned(top: 8, right: 48, child: _starWidget('★', 0.6)),
                                  Positioned(bottom: 24, left: 32, child: _starWidget('✦', 0.4)),
                                  Positioned(top: outer * 0.42, right: 16, child: _dotStar(0.5)),
                                ],
                              ),
                            );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width < 360 ? 24 : 40),
                      // Textos
                      Text.rich(
                        TextSpan(
                          text: '¡Tu viaje ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: MediaQuery.of(context).size.width < 360 ? 24.0 : (MediaQuery.of(context).size.width < 400 ? 26.0 : 28.0),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(
                              text: 'gastronómico',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: MediaQuery.of(context).size.width < 360 ? 24.0 : (MediaQuery.of(context).size.width < 400 ? 26.0 : 28.0),
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                                height: 1.25,
                              ),
                            ),
                            TextSpan(
                              text: ' comienza aquí!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: MediaQuery.of(context).size.width < 360 ? 24.0 : (MediaQuery.of(context).size.width < 400 ? 26.0 : 28.0),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Explora sabores de toda la galaxia sin salir de casa.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: MediaQuery.of(context).size.width < 360 ? 14.0 : 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: _kBackgroundDark,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kSpaceBlue.withValues(alpha: 0.5),
            _kBackgroundDark,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Estrellas distantes
          Positioned(top: size.height * 0.1, left: size.width * 0.15, child: _starDot(0.4, 4)),
          Positioned(top: size.height * 0.25, right: size.width * 0.1, child: _starDot(0.3, 2)),
          Positioned(bottom: size.height * 0.3, left: size.width * 0.05, child: _starDot(0.2, 4)),
          Positioned(top: size.height * 0.05, right: size.width * 0.35, child: _starDot(0.4, 2, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _starWidget(String char, double opacity) {
    return Text(
      char,
      style: TextStyle(
        color: _kPrimary.withValues(alpha: opacity),
        fontSize: 12,
      ),
    );
  }

  Widget _dotStar(double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _starDot(double opacity, double size, {Color? color}) {
    final c = color ?? Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}