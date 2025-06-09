// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zonix/features/utils/user_provider.dart';

// class OnboardingPage5 extends StatelessWidget {
//   const OnboardingPage5({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF2E86AB), // Azul océano
//               Color(0xFFA23B72), // Rosa púrpura
//               Color(0xFFF18F01), // Naranja vibrante
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.08,
//                   vertical: screenHeight * 0.02,
//                 ),
//                 child: FutureBuilder<Map<String, dynamic>>(
//                   future: userProvider.getUserDetails(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                         ),
//                       );
//                     } else if (snapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'Error: ${snapshot.error}',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       );
//                     } else if (!snapshot.hasData) {
//                       return const Center(
//                         child: Text(
//                           'No se encontraron datos.',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       );
//                     }

//                     // Mantenemos EXACTAMENTE el mismo contenido del Código 2
//                     return Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(height: screenHeight * 0.02),
                        
//                         // Celebración con confeti
//                         Container(
//                           height: screenHeight * 0.25,
//                           width: screenHeight * 0.25,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(screenHeight * 0.125),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.3),
//                               width: 3,
//                             ),
//                           ),
//                           child: Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               // Confeti decorativo
//                               Positioned(
//                                 top: screenHeight * 0.025,
//                                 left: screenWidth * 0.08,
//                                 child: Container(
//                                   width: screenWidth * 0.02,
//                                   height: screenWidth * 0.02,
//                                   decoration: BoxDecoration(
//                                     color: Colors.yellow.shade300,
//                                     borderRadius: BorderRadius.circular(screenWidth * 0.01),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 top: screenHeight * 0.05,
//                                 right: screenWidth * 0.065,
//                                 child: Container(
//                                   width: screenWidth * 0.015,
//                                   height: screenWidth * 0.015,
//                                   decoration: BoxDecoration(
//                                     color: Colors.pink.shade300,
//                                     borderRadius: BorderRadius.circular(screenWidth * 0.0075),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 bottom: screenHeight * 0.04,
//                                 left: screenWidth * 0.1,
//                                 child: Container(
//                                   width: screenWidth * 0.025,
//                                   height: screenWidth * 0.025,
//                                   decoration: BoxDecoration(
//                                     color: Colors.green.shade300,
//                                     borderRadius: BorderRadius.circular(screenWidth * 0.0125),
//                                   ),
//                                 ),
//                               ),
                              
//                               // Icono principal
//                               Container(
//                                 padding: EdgeInsets.all(screenWidth * 0.06),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.3),
//                                   borderRadius: BorderRadius.circular(50),
//                                 ),
//                                 child: Icon(
//                                   Icons.celebration,
//                                   size: screenWidth * 0.2,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         SizedBox(height: screenHeight * 0.04),
                        
//                         Text(
//                           '¡Todo Listo!',
//                           style: TextStyle(
//                             fontSize: screenWidth * 0.08,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             shadows: [
//                               Shadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 offset: const Offset(0, 2),
//                                 blurRadius: 4,
//                               ),
//                             ],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
                        
//                         SizedBox(height: screenHeight * 0.025),
                        
//                         Container(
//                           padding: EdgeInsets.all(screenWidth * 0.06),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               Text(
//                                 'Bienvenido a FoodZone, donde la mejor comida te espera. Estás a un toque de distancia de disfrutar sabores increíbles.',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: screenWidth * 0.04,
//                                   height: 1.5,
//                                 ),
//                               ),
                              
//                               SizedBox(height: screenHeight * 0.03),
                              
//                               // Beneficios finales
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   _buildFinalBenefit(
//                                     Icons.restaurant_menu,
//                                     'Miles de\nRestaurantes',
//                                     screenWidth,
//                                     screenHeight,
//                                   ),
//                                   _buildFinalBenefit(
//                                     Icons.local_offer,
//                                     'Ofertas\nEspeciales',
//                                     screenWidth,
//                                     screenHeight,
//                                   ),
//                                   _buildFinalBenefit(
//                                     Icons.support_agent,
//                                     'Soporte\n24/7',
//                                     screenWidth,
//                                     screenHeight,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         SizedBox(height: screenHeight * 0.04),
                        
//                         // Call to action especial
//                         Container(
//                           padding: EdgeInsets.all(screenWidth * 0.05),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(15),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.local_fire_department,
//                                 color: Colors.orange.shade300,
//                                 size: screenWidth * 0.06,
//                               ),
//                               SizedBox(width: screenWidth * 0.025),
//                               Flexible(
//                                 child: Text(
//                                   'Obtén 20% de descuento en tu primer pedido',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: screenWidth * 0.035,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         SizedBox(height: screenHeight * 0.02),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFinalBenefit(
//     IconData icon,
//     String text,
//     double screenWidth,
//     double screenHeight,
//   ) {
//     return Flexible(
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(screenWidth * 0.04),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.25),
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.4),
//                 width: 1,
//               ),
//             ),
//             child: Icon(
//               icon,
//               color: Colors.white,
//               size: screenWidth * 0.07,
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.01),
//           Text(
//             text,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: screenWidth * 0.03,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:zonix/features/utils/user_provider.dart';

// // class OnboardingPage5 extends StatelessWidget {
// //   const OnboardingPage5({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final userProvider = Provider.of<UserProvider>(context);
// //     final screenHeight = MediaQuery.of(context).size.height;
// //     final screenWidth = MediaQuery.of(context).size.width;

// //     return Scaffold(
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //             colors: [
// //               Color(0xFF2E86AB), // Azul océano
// //               Color(0xFFA23B72), // Rosa púrpura
// //               Color(0xFFF18F01), // Naranja vibrante
// //             ],
// //           ),
// //         ),
// //         child: SafeArea(
// //           child: SingleChildScrollView(
// //             child: ConstrainedBox(
// //               constraints: BoxConstraints(
// //                 minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
// //               ),
// //               child: Padding(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: screenWidth * 0.08,
// //                   vertical: screenHeight * 0.02,
// //                 ),
// //                 child: FutureBuilder<Map<String, dynamic>>(
// //                   future: userProvider.getUserDetails(),
// //                   builder: (context, snapshot) {
// //                     if (snapshot.connectionState == ConnectionState.waiting) {
// //                       return const Center(
// //                         child: CircularProgressIndicator(
// //                           color: Colors.white,
// //                         ),
// //                       );
// //                     } else if (snapshot.hasError) {
// //                       return Center(
// //                         child: Text(
// //                           'Error: ${snapshot.error}',
// //                           style: const TextStyle(color: Colors.white),
// //                         ),
// //                       );
// //                     } else if (!snapshot.hasData) {
// //                       return const Center(
// //                         child: Text(
// //                           'No se encontraron datos.',
// //                           style: TextStyle(color: Colors.white),
// //                         ),
// //                       );
// //                     }

// //                     final userDetails = snapshot.data!;
// //                     final userId = userDetails['userId'];

// //                     return Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         SizedBox(height: screenHeight * 0.02),
                        
// //                         // Contenedor circular con ilustración
// //                         Container(
// //                           height: screenHeight * 0.25,
// //                           width: screenHeight * 0.25,
// //                           decoration: BoxDecoration(
// //                             color: Colors.white.withOpacity(0.2),
// //                             borderRadius: BorderRadius.circular(screenHeight * 0.125),
// //                             border: Border.all(
// //                               color: Colors.white.withOpacity(0.3),
// //                               width: 3,
// //                             ),
// //                           ),
// //                           child: Stack(
// //                             alignment: Alignment.center,
// //                             children: [
// //                               // Decoraciones
// //                               Positioned(
// //                                 top: screenHeight * 0.025,
// //                                 left: screenWidth * 0.08,
// //                                 child: Container(
// //                                   width: screenWidth * 0.02,
// //                                   height: screenWidth * 0.02,
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.yellow.shade300,
// //                                     borderRadius: BorderRadius.circular(screenWidth * 0.01),
// //                                   ),
// //                                 ),
// //                               ),
// //                               Positioned(
// //                                 top: screenHeight * 0.05,
// //                                 right: screenWidth * 0.065,
// //                                 child: Container(
// //                                   width: screenWidth * 0.015,
// //                                   height: screenWidth * 0.015,
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.pink.shade300,
// //                                     borderRadius: BorderRadius.circular(screenWidth * 0.0075),
// //                                   ),
// //                                 ),
// //                               ),
// //                               Positioned(
// //                                 bottom: screenHeight * 0.04,
// //                                 left: screenWidth * 0.1,
// //                                 child: Container(
// //                                   width: screenWidth * 0.025,
// //                                   height: screenWidth * 0.025,
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.green.shade300,
// //                                     borderRadius: BorderRadius.circular(screenWidth * 0.0125),
// //                                   ),
// //                                 ),
// //                               ),
                              
// //                               // Imagen principal
// //                               Container(
// //                                 padding: EdgeInsets.all(screenWidth * 0.06),
// //                                 child: Image.asset(
// //                                   'assets/onboarding/storefront-illustration-2.png',
// //                                   fit: BoxFit.contain,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
                        
// //                         SizedBox(height: screenHeight * 0.04),
                        
// //                         Text(
// //                           'Registra tu bombona de gas',
// //                           style: TextStyle(
// //                             fontSize: screenWidth * 0.08,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                             shadows: [
// //                               Shadow(
// //                                 color: Colors.black.withOpacity(0.3),
// //                                 offset: const Offset(0, 2),
// //                                 blurRadius: 4,
// //                               ),
// //                             ],
// //                           ),
// //                           textAlign: TextAlign.center,
// //                         ),
                        
// //                         SizedBox(height: screenHeight * 0.025),
                        
// //                         Container(
// //                           padding: EdgeInsets.all(screenWidth * 0.06),
// //                           decoration: BoxDecoration(
// //                             color: Colors.white.withOpacity(0.2),
// //                             borderRadius: BorderRadius.circular(20),
// //                             border: Border.all(
// //                               color: Colors.white.withOpacity(0.3),
// //                               width: 1,
// //                             ),
// //                           ),
// //                           child: Column(
// //                             children: [
// //                               Text(
// //                                 'Agrega detalles sobre tu bombona y programa una cita.',
// //                                 textAlign: TextAlign.center,
// //                                 style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: screenWidth * 0.04,
// //                                   height: 1.5,
// //                                 ),
// //                               ),
                              
// //                               SizedBox(height: screenHeight * 0.03),
                              
// //                               // Beneficios
// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                                 children: [
// //                                   _buildBenefit(
// //                                     Icons.gas_meter,
// //                                     'Registro\nSeguro',
// //                                     screenWidth,
// //                                     screenHeight,
// //                                   ),
// //                                   _buildBenefit(
// //                                     Icons.calendar_today,
// //                                     'Citas\nProgramadas',
// //                                     screenWidth,
// //                                     screenHeight,
// //                                   ),
// //                                   _buildBenefit(
// //                                     Icons.security,
// //                                     'Seguimiento\nConstante',
// //                                     screenWidth,
// //                                     screenHeight,
// //                                   ),
// //                                 ],
// //                               ),
// //                             ],
// //                           ),
// //                         ),
                        
// //                         SizedBox(height: screenHeight * 0.04),
                        
// //                         // Botón de acción
// //                         Container(
// //                           padding: EdgeInsets.all(screenWidth * 0.05),
// //                           decoration: BoxDecoration(
// //                             color: Colors.white.withOpacity(0.15),
// //                             borderRadius: BorderRadius.circular(15),
// //                             border: Border.all(
// //                               color: Colors.white.withOpacity(0.3),
// //                               width: 1,
// //                             ),
// //                           ),
// //                           child: Row(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               Icon(
// //                                 Icons.local_fire_department,
// //                                 color: Colors.orange.shade300,
// //                                 size: screenWidth * 0.06,
// //                               ),
// //                               SizedBox(width: screenWidth * 0.025),
// //                               Flexible(
// //                                 child: Text(
// //                                   'Completa tu registro para continuar',
// //                                   style: TextStyle(
// //                                     color: Colors.white,
// //                                     fontSize: screenWidth * 0.035,
// //                                     fontWeight: FontWeight.w600,
// //                                   ),
// //                                   textAlign: TextAlign.center,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
                        
// //                         SizedBox(height: screenHeight * 0.02),
// //                       ],
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildBenefit(
// //     IconData icon,
// //     String text,
// //     double screenWidth,
// //     double screenHeight,
// //   ) {
// //     return Flexible(
// //       child: Column(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(screenWidth * 0.04),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withOpacity(0.25),
// //               borderRadius: BorderRadius.circular(15),
// //               border: Border.all(
// //                 color: Colors.white.withOpacity(0.4),
// //                 width: 1,
// //               ),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: Colors.white,
// //               size: screenWidth * 0.07,
// //             ),
// //           ),
// //           SizedBox(height: screenHeight * 0.01),
// //           Text(
// //             text,
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: screenWidth * 0.03,
// //               fontWeight: FontWeight.w500,
// //             ),
// //             textAlign: TextAlign.center,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:zonix/features/utils/user_provider.dart';
// // // import 'package:zonix/features/DomainProfiles/GasCylinder/screens/create_gas_cylinder_screen.dart';

// // // class OnboardingPage5 extends StatelessWidget {
// // //   const OnboardingPage5({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final userProvider = Provider.of<UserProvider>(context);

// // //     return Scaffold(
// // //       body: Container(
// // //         color: const Color(0xfff44336),
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(32.0),
// // //           child: FutureBuilder<Map<String, dynamic>>(
// // //             future: userProvider.getUserDetails(),
// // //             builder: (context, snapshot) {
// // //               if (snapshot.connectionState == ConnectionState.waiting) {
// // //                 return const Center(child: CircularProgressIndicator());
// // //               } else if (snapshot.hasError) {
// // //                 return Center(child: Text('Error: ${snapshot.error}'));
// // //               } else if (!snapshot.hasData) {
// // //                 return const Center(child: Text('No se encontraron datos.'));
// // //               }

// // //               final userDetails = snapshot.data!;
// // //               final userId = userDetails['userId'];

// // //               return Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Image.asset('assets/onboarding/storefront-illustration-2.png'),
// // //                   const SizedBox(height: 24),
// // //                   Text(
// // //                     'Registra tu bombona de gas',
// // //                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                       fontWeight: FontWeight.bold,
// // //                       color: Colors.white,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 16),
// // //                   const Text(
// // //                     'Agrega detalles sobre tu bombona y programa una cita.',
// // //                     textAlign: TextAlign.center,
// // //                     style: TextStyle(color: Colors.white),
// // //                   ),
// // //                   const SizedBox(height: 32),
                 
// // //                 ],
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';

class OnboardingPage5 extends StatelessWidget {
  const OnboardingPage5({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Azul profundo Zonix
              Color(0xFF3B82F6), // Azul medio
              Color(0xFFF59E0B), // Naranja/Amarillo EATS
            ],
            stops: [0.0, 0.4, 1.0],
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
                child: FutureBuilder<Map<String, dynamic>>(
                  future: userProvider.getUserDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'No se encontraron datos.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Celebración con confeti - Mejorado
                        Container(
                          height: screenHeight * 0.28,
                          width: screenHeight * 0.28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(screenHeight * 0.14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Confeti decorativo mejorado
                              _buildConfetti(screenHeight * 0.03, screenWidth * 0.08, const Color(0xFFF59E0B)),
                              _buildConfetti(screenHeight * 0.05, screenWidth * 0.25, const Color(0xFF3B82F6)),
                              _buildConfetti(screenHeight * 0.18, screenWidth * 0.06, const Color(0xFFF59E0B)),
                              _buildConfetti(screenHeight * 0.16, screenWidth * 0.22, const Color(0xFF1E3A8A)),
                              _buildConfetti(screenHeight * 0.08, screenWidth * 0.18, Colors.white),
                              
                              // Icono principal mejorado
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.08),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF59E0B).withOpacity(0.3),
                                      Colors.white.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(
                                  Icons.celebration,
                                  size: screenWidth * 0.22,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.04),
                        
                        // Título con gradiente mejorado
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFF59E0B),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '¡Todo Listo! 🎉',
                            style: TextStyle(
                              fontSize: screenWidth * 0.09,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.015),
                        
                        // Subtítulo elegante
                        Text(
                          'Bienvenido a Zonix Eats',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF59E0B),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Contenedor principal mejorado
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.06),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Tu aventura culinaria comienza aquí. Miles de restaurantes, sabores únicos y ofertas especiales te esperan. ¡Prepárate para descubrir tu próxima comida favorita! 🚀',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.042,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              
                              SizedBox(height: screenHeight * 0.035),
                              
                              // Beneficios finales mejorados
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildFinalBenefit(
                                    Icons.restaurant_menu,
                                    'Miles de\nRestaurantes',
                                    screenWidth,
                                    screenHeight,
                                    const Color(0xFFF59E0B),
                                  ),
                                  _buildFinalBenefit(
                                    Icons.local_offer,
                                    'Ofertas\nEspeciales',
                                    screenWidth,
                                    screenHeight,
                                    const Color(0xFF3B82F6),
                                  ),
                                  _buildFinalBenefit(
                                    Icons.support_agent,
                                    'Soporte\n24/7',
                                    screenWidth,
                                    screenHeight,
                                    const Color(0xFF1E3A8A),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.04),
                        
                        // Call to action especial mejorado
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF59E0B).withOpacity(0.3),
                                const Color(0xFFF59E0B).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: screenWidth * 0.06,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Oferta Especial!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '20% OFF en tu primer pedido',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti(double top, double left, Color color) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalBenefit(
    IconData icon,
    String text,
    double screenWidth,
    double screenHeight,
    Color accentColor,
  ) {
    return Flexible(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.045),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.3),
                  accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.08,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.032,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}