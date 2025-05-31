import 'package:flutter/material.dart';

class OnboardingPage5 extends StatelessWidget {
  const OnboardingPage5({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E86AB), // Azul océano
              Color(0xFFA23B72), // Rosa púrpura
              Color(0xFFF18F01), // Naranja vibrante
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Celebración con confeti
                    Container(
                      height: screenHeight * 0.25,
                      width: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenHeight * 0.125),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Confeti decorativo
                          Positioned(
                            top: screenHeight * 0.025,
                            left: screenWidth * 0.08,
                            child: Container(
                              width: screenWidth * 0.02,
                              height: screenWidth * 0.02,
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade300,
                                borderRadius: BorderRadius.circular(screenWidth * 0.01),
                              ),
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 0.05,
                            right: screenWidth * 0.065,
                            child: Container(
                              width: screenWidth * 0.015,
                              height: screenWidth * 0.015,
                              decoration: BoxDecoration(
                                color: Colors.pink.shade300,
                                borderRadius: BorderRadius.circular(screenWidth * 0.0075),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: screenHeight * 0.04,
                            left: screenWidth * 0.1,
                            child: Container(
                              width: screenWidth * 0.025,
                              height: screenWidth * 0.025,
                              decoration: BoxDecoration(
                                color: Colors.green.shade300,
                                borderRadius: BorderRadius.circular(screenWidth * 0.0125),
                              ),
                            ),
                          ),
                          
                          // Icono principal
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.06),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.celebration,
                              size: screenWidth * 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    Text(
                      '¡Todo Listo!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: screenHeight * 0.025),
                    
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Bienvenido a FoodZone, donde la mejor comida te espera. Estás a un toque de distancia de disfrutar sabores increíbles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Beneficios finales
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFinalBenefit(
                                Icons.restaurant_menu,
                                'Miles de\nRestaurantes',
                                screenWidth,
                                screenHeight,
                              ),
                              _buildFinalBenefit(
                                Icons.local_offer,
                                'Ofertas\nEspeciales',
                                screenWidth,
                                screenHeight,
                              ),
                              _buildFinalBenefit(
                                Icons.support_agent,
                                'Soporte\n24/7',
                                screenWidth,
                                screenHeight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Call to action especial
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange.shade300,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Flexible(
                            child: Text(
                              'Obtén 20% de descuento en tu primer pedido',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalBenefit(
    IconData icon,
    String text,
    double screenWidth,
    double screenHeight,
  ) {
    return Flexible(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}