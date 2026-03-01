import 'package:flutter/material.dart';

class OnboardingPage4 extends StatelessWidget {
  const OnboardingPage4({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
             Color(0xFF1B365D),
             Color(0xFF2E86C1),
             Color(0xFF5DADE2),
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

                  // Imagen de delivery
                    SizedBox(
                      height: screenHeight * 0.28,
                      width: double.infinity,
                      child: Center(
                        child: Image.asset(
                          'assets/onboarding/onboarding_eats2.png',
                          width: screenWidth * 0.8,  // Ajusta el ancho según necesites
                          fit: BoxFit.contain,       // Mantiene la relación de aspecto
                        ),
                      ),
                    ),

                    // // Ilustración animada de delivery
                    // Container(
                    //   height: screenHeight * 0.28,
                    //   width: double.infinity,
                    //   child: Stack(
                    //     alignment: Alignment.center,
                    //     children: [
                    //       // Círculos de fondo animados
                    //       Positioned(
                    //         top: screenHeight * 0.04,
                    //         left: screenWidth * 0.08,
                    //         child: Container(
                    //           width: screenWidth * 0.15,
                    //           height: screenWidth * 0.15,
                    //           decoration: BoxDecoration(
                    //             color: Colors.white.withValues(alpha: 0.2),
                    //             borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    //           ),
                    //         ),
                    //       ),
                    //       Positioned(
                    //         bottom: screenHeight * 0.05,
                    //         right: screenWidth * 0.1,
                    //         child: Container(
                    //           width: screenWidth * 0.1,
                    //           height: screenWidth * 0.1,
                    //           decoration: BoxDecoration(
                    //             color: Colors.white.withValues(alpha: 0.15),
                    //             borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    //           ),
                    //         ),
                    //       ),
                          
                    //       // Delivery rider
                    //       Container(
                    //         padding: EdgeInsets.all(screenWidth * 0.08),
                    //         decoration: BoxDecoration(
                    //           color: Colors.white.withValues(alpha: 0.2),
                    //           borderRadius: BorderRadius.circular(100),
                    //           border: Border.all(
                    //             color: Colors.white.withValues(alpha: 0.3),
                    //             width: 2,
                    //           ),
                    //         ),
                    //         child: Column(
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             Icon(
                    //               Icons.two_wheeler,
                    //               size: screenWidth * 0.2,
                    //               color: Colors.white,
                    //             ),
                    //             SizedBox(height: screenHeight * 0.01),
                    //             Container(
                    //               padding: EdgeInsets.symmetric(
                    //                 horizontal: screenWidth * 0.03,
                    //                 vertical: screenHeight * 0.008,
                    //               ),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(15),
                    //                 boxShadow: [
                    //                   BoxShadow(
                    //                     color: Colors.black.withValues(alpha: 0.1),
                    //                     blurRadius: 5,
                    //                     offset: const Offset(0, 2),
                    //                   ),
                    //                 ],
                    //               ),
                    //               child: Row(
                    //                 mainAxisSize: MainAxisSize.min,
                    //                 children: [
                    //                   Icon(
                    //                     Icons.timer,
                    //                     size: screenWidth * 0.04,
                    //                     color: const Color(0xFFFF6B6B),
                    //                   ),
                    //                   SizedBox(width: screenWidth * 0.01),
                    //                   Text(
                    //                     '15-30 min',
                    //                     style: TextStyle(
                    //                       color: const Color(0xFFFF6B6B),
                    //                       fontSize: screenWidth * 0.03,
                    //                       fontWeight: FontWeight.bold,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    Text(
                      'Entrega Super Rápida',
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Tu comida llegará fresca y caliente en tiempo récord. Rastrea tu pedido en tiempo real y disfruta sin esperas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Características de entrega
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDeliveryFeature(
                                Icons.flash_on,
                                'Rápido',
                                '15-30 min',
                                screenWidth,
                                screenHeight,
                              ),
                              _buildDeliveryFeature(
                                Icons.location_on,
                                'Seguimiento',
                                'En tiempo real',
                                screenWidth,
                                screenHeight,
                              ),
                              _buildDeliveryFeature(
                                Icons.shield_outlined,
                                'Seguro',
                                'Garantizado',
                                screenWidth,
                                screenHeight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Rating stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                            child: Icon(
                              Icons.star,
                              color: Colors.yellow.shade300,
                              size: screenWidth * 0.05,
                            ),
                          );
                        }),
                        SizedBox(width: screenWidth * 0.025),
                        Text(
                          '4.9/5 en entregas',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildDeliveryFeature(
    IconData icon,
    String title,
    String subtitle,
    double screenWidth,
    double screenHeight,
  ) {
    return Flexible(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: screenWidth * 0.025,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}