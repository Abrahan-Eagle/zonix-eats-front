import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  List<Widget> get onboardingPages {
    return const [
      WelcomePage(),
      OnboardingPage1(), // Intro 1 - beneficios
      OnboardingPage2(), // Intro 2 - pedidos fáciles
      OnboardingPage3(), // Selección de rol (users / commerce) y punto de bifurcación por rol
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

    return WillPopScope(
      onWillPop: () async => false,
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
                          // activeDotColor: theme.primaryColor,
                          // dotColor: theme.dividerColor,

                          activeDotColor: Colors.white, // Punto activo blanco
                        dotColor: Colors.white.withOpacity(0.5), // Puntos inactivos semitransparentes
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
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF0F172A), // Azul muy oscuro (espacio)
            Color(0xFF1E293B), // Azul oscuro
            Color(0xFF334155), // Azul medio
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espaciado superior flexible
              const Spacer(flex: 1),
              
              // Imagen de familia con efecto planetario
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.2), // Naranja suave
                      const Color(0xFF3B82F6).withOpacity(0.1), // Azul suave
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: Image.asset(
                    'assets/onboarding/onboarding_eats_familia.png',
                    height: size.height * 0.22,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Título con temática espacial
              Column(
                children: [
                  Text(
                    '🪐 Bienvenido al',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 22,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Universo ',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'ZONIX',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                            color: const Color(0xFFF59E0B), // Naranja del logo
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Badge espacial
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEF4444), // Rojo
                      Color(0xFFF59E0B), // Naranja
                      Color(0xFFFBBF24), // Amarillo
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  '🚀 ¡Comida a la velocidad de la luz!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Elementos de trust con temática espacial
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF334155).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTrustElement('🛸', 'Entrega\nUltra Rápida'),
                    _buildTrustElement('🌟', 'Experiencia\nEstelar'),
                    _buildTrustElement('🪐', 'Miles de\nSabores'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Descripción espacial
              Text(
                'Conecta con tu familia a través de la comida 👨‍👩‍👧‍👦\n¡Sabores que unen planetas! 🌍✨',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              // Espaciado inferior flexible
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrustElement(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}