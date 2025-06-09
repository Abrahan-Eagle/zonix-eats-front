import 'package:flutter/material.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 64.0 : (isSmallPhone ? 16.0 : 20.0),
                    vertical: isTablet ? 32.0 : 16.0,
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                // Header con logo
                                // _buildHeader(isTablet, isSmallPhone),
                                
                                // Espaciador flexible
                                // const Flexible(flex: 1, child: SizedBox()),
                                
                                // Ilustración principal
                                _buildMainIllustration(size, isTablet, isSmallPhone),
                                
                                // Espaciador
                                SizedBox(height: isTablet ? 32 : (isSmallPhone ? 16 : 24)),
                                
                                // Contenido principal
                                _buildMainContent(isTablet, isSmallPhone),
                                
                                // Espaciador
                                SizedBox(height: isTablet ? 32 : (isSmallPhone ? 20 : 24)),
                                
                                // Características destacadas
                                _buildFeatures(isTablet, isSmallPhone),
                                
                                // Espaciador flexible
                                const Flexible(flex: 1, child: SizedBox()),
                                
                                // Espacio para la navegación flotante
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget _buildHeader(bool isTablet, bool isSmallPhone) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : (isSmallPhone ? 12 : 16)),
  //     child: Text(
  //       'FoodZone',
  //       textAlign: TextAlign.center,
  //       style: TextStyle(
  //         fontSize: isTablet ? 32 : (isSmallPhone ? 22 : 26),
  //         fontWeight: FontWeight.bold,
  //         color: const Color(0xFFE74C3C),
  //         letterSpacing: 1.2,
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildMainIllustration(Size size, bool isTablet, bool isSmallPhone) {
  //   final illustrationSize = isTablet 
  //       ? size.width * 0.35 
  //       : isSmallPhone 
  //           ? size.width * 0.6 
  //           : size.width * 0.65;
    
  //   return Container(
  //     width: illustrationSize,
  //     height: illustrationSize,
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFE74C3C),
  //       borderRadius: BorderRadius.circular(illustrationSize * 0.5),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFFE74C3C).withOpacity(0.25),
  //           blurRadius: 30,
  //           offset: const Offset(0, 15),
  //           spreadRadius: 5,
  //         ),
  //       ],
  //     ),
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         // Elementos decorativos
  //         Positioned(
  //           top: illustrationSize * 0.15,
  //           right: illustrationSize * 0.15,
  //           child: Container(
  //             width: isSmallPhone ? 8 : 12,
  //             height: isSmallPhone ? 8 : 12,
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               shape: BoxShape.circle,
  //             ),
  //           ),
  //         ),
  //         Positioned(
  //           bottom: illustrationSize * 0.25,
  //           left: illustrationSize * 0.12,
  //           child: Container(
  //             width: isSmallPhone ? 6 : 8,
  //             height: isSmallPhone ? 6 : 8,
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               shape: BoxShape.circle,
  //             ),
  //           ),
  //         ),
          
  //         // Icono principal
  //         Container(
  //           padding: EdgeInsets.all(isTablet ? 40 : (isSmallPhone ? 25 : 30)),
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.2),
  //             borderRadius: BorderRadius.circular(illustrationSize * 0.25),
  //           ),
  //           child: Icon(
  //             Icons.restaurant_menu,
  //             size: isTablet ? 100 : (isSmallPhone ? 60 : 75),
  //             color: Colors.white,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Widget _buildMainIllustration(Size size, bool isTablet, bool isSmallPhone) {
  final imageSize = isTablet
      ? size.width * 0.35
      : isSmallPhone
          ? size.width * 0.6
          : size.width * 0.65;

  return Image.asset(
    'assets/onboarding/onboarding_eats.png',
    width: imageSize,
    height: imageSize,
    fit: BoxFit.contain, // Ajusta la imagen sin deformarla
  );
}

  Widget _buildMainContent(bool isTablet, bool isSmallPhone) {
    return Column(
      children: [
        Text(
          '¡Bienvenido a Zonix Eats!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 36 : (isSmallPhone ? 24 : 28),
            fontWeight: FontWeight.bold,
            color: Colors.white, 
            height: 1.2,
          ),
        ),
        
        SizedBox(height: isTablet ? 20 : (isSmallPhone ? 12 : 16)),
        
            Container(
          padding: EdgeInsets.all(isTablet ? 24 : (isSmallPhone ? 16 : 20)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Fondo semitransparente
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Tu comida favorita a un toque de distancia. Descubre sabores increíbles, entrega rápida y la mejor experiencia culinaria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, // Texto blanco
              fontSize: isTablet ? 18 : (isSmallPhone ? 13 : 15),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildFeatures(bool isTablet, bool isSmallPhone) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: [
  //       Flexible(
  //         child: _buildFeatureIcon(
  //           Icons.flash_on,
  //           'Rápido',
  //           const Color(0xFFF39C12),
  //           isTablet,
  //           isSmallPhone,
  //         ),
  //       ),
  //       SizedBox(width: isSmallPhone ? 8 : 16),
  //       Flexible(
  //         child: _buildFeatureIcon(
  //           Icons.favorite,
  //           'Delicioso',
  //           const Color(0xFFE74C3C),
  //           isTablet,
  //           isSmallPhone,
  //         ),
  //       ),
  //       SizedBox(width: isSmallPhone ? 8 : 16),
  //       Flexible(
  //         child: _buildFeatureIcon(
  //           Icons.shield_outlined,
  //           'Seguro',
  //           const Color(0xFF27AE60),
  //           isTablet,
  //           isSmallPhone,
  //         ),
  //       ),
  //     ],
  //   );
  // }

Widget _buildFeatures(bool isTablet, bool isSmallPhone) {
    return Wrap(
      spacing: isTablet ? 32 : (isSmallPhone ? 24 : 28), // Aumenté el espacio horizontal
      runSpacing: isTablet ? 24 : (isSmallPhone ? 16 : 20), // Aumenté el espacio vertical
      alignment: WrapAlignment.center,
      children: [
        _buildFeatureIcon(
          Icons.flash_on,
          'Rápido',
          Colors.white,
          isTablet,
          isSmallPhone,
        ),
        _buildFeatureIcon(
          Icons.favorite,
          'Delicioso',
          Colors.white,
          isTablet,
          isSmallPhone,
        ),
        _buildFeatureIcon(
          Icons.shield_outlined,
          'Seguro',
          Colors.white,
          isTablet,
          isSmallPhone,
        ),
      ],
    );
  }



  Widget _buildFeatureIcon(IconData icon, String label, Color color, bool isTablet, bool isSmallPhone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 16 : (isSmallPhone ? 10 : 12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: isTablet ? 28 : (isSmallPhone ? 20 : 24),
          ),
        ),
        SizedBox(height: isTablet ? 12 : (isSmallPhone ? 6 : 8)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white, 
            fontSize: isTablet ? 14 : (isSmallPhone ? 10 : 12),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}