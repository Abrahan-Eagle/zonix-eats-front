import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/main.dart';
import 'package:zonix/features/services/auth/google_sign_in_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();
final ApiService apiService = ApiService();
final logger = Logger();

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final GoogleSignInService googleSignInService = GoogleSignInService();
  bool isAuthenticated = false;
  GoogleSignInAccount? _currentUser;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthentication();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotateController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    isAuthenticated = await AuthUtils.isAuthenticated();
    if (isAuthenticated) {
      _currentUser = await GoogleSignInService.getCurrentUser();
      if (_currentUser != null) {
        logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
        await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
        logger.i('Nombre de usuario: ${_currentUser!.displayName}');
        await _storage.write(key: 'displayName', value: _currentUser!.displayName);
      }
    }
    setState(() {});
  }

  Future<void> _handleSignIn() async {
    try {
      await GoogleSignInService.signInWithGoogle();
      _currentUser = await GoogleSignInService.getCurrentUser();
      setState(() {});

      if (_currentUser != null) {
        await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
        await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
        await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

        String? savedName = await _storage.read(key: 'userName');
        String? savedEmail = await _storage.read(key: 'userEmail');
        String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
        String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

        logger.i('Nombre guardado: $savedName');
        logger.i('Correo guardado: $savedEmail');
        logger.i('Foto guardada: $savedPhotoUrl');
        logger.i('Onboarding guardada: $savedOnboardingString');

        bool onboardingCompleted = savedOnboardingString == '1';
        logger.i('Conversión de completedOnboarding: $onboardingCompleted');

        if (!mounted) return;

        if (!onboardingCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainRouter()),
          );
        }
      } else {
        logger.i('Inicio de sesión cancelado o fallido');
      }
    } catch (e) {
      logger.e('Error durante el manejo del inicio de sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con patrón geométrico
          _buildGeometricBackground(),
          
          // Contenido principal con SingleChildScrollView para evitar overflow
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isVerySmallScreen ? 8 : 16,
                    ),
                    child: Column(
                      children: [
                        // Header minimalista
                        _buildMinimalHeader(isSmallScreen),
                        
                        // Contenido central con Expanded
                        Expanded(
                          child: Column(
                            children: [
                              // Círculo central
                              Expanded(
                                flex: 3,
                                child: _buildCentralCircle(screenWidth, isSmallScreen, isLargeScreen, isVerySmallScreen),
                              ),
                              
                              // Contenido inferior
                              Expanded(
                                flex: 2,
                                child: _buildBottomContent(screenWidth, isSmallScreen, isLargeScreen, isVerySmallScreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeometricBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
      ),
      child: Stack(
        children: [
          // Círculos decorativos animados
          Positioned(
            top: -50,
            right: -50,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFC93C).withOpacity(0.08),
                ),
              ),
            ),
          ),
          // Patrón de puntos
          ...List.generate(20, (index) {
            return Positioned(
              top: ((index * 50.0) % 800).roundToDouble(),
              left: ((index * 80.0) % 400).roundToDouble(), 
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '16:24',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12, 
              vertical: isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC93C).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'FOOD APP',
              style: TextStyle(
                color: const Color(0xFFFFC93C),
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralCircle(double screenWidth, bool isSmallScreen, bool isLargeScreen, bool isVerySmallScreen) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Círculo principal animado
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: isSmallScreen 
                  ? screenWidth * (isVerySmallScreen ? 0.5 : 0.6)
                  : isLargeScreen 
                      ? screenWidth * 0.3 
                      : screenWidth * 0.5,
              height: isSmallScreen 
                  ? screenWidth * (isVerySmallScreen ? 0.5 : 0.6)
                  : isLargeScreen 
                      ? screenWidth * 0.3 
                      : screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo principal
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      size: isSmallScreen ? 28 : 36,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // Nombre de la app
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ZONI',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'X',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFC93C),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    'FOOD DELIVERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 8 : 16),
          
          // Texto de bienvenida
          Text(
            'Tu hambre, nuestra misión',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 4 : 6),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16, 
              vertical: isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC93C).withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              '🍕 🍔 🍟 🌮 🍗 🍜',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(double screenWidth, bool isSmallScreen, bool isLargeScreen, bool isVerySmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Mensaje motivacional
        Text(
          'Miles de restaurantes te esperan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        
        SizedBox(height: isVerySmallScreen ? 8 : 16),
        
        // Botón de Google con diseño futurista
        Container(
          width: isLargeScreen ? screenWidth * 0.6 : double.infinity,
          height: isSmallScreen ? 44 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFFFC93C),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC93C).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSignIn,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/images/google_logo.png',
                        height: isSmallScreen ? 16 : 20,
                        width: isSmallScreen ? 16 : 20,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.login,
                            size: isSmallScreen ? 16 : 20,
                            color: const Color(0xFF4285F4),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 10),
                    Text(
                      'EMPEZAR CON GOOGLE',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: isVerySmallScreen ? 8 : 12),
        
        // Indicadores de tiempo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeIndicator('⚡', '5 min', 'Registro', isSmallScreen),
            Container(
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10),
              width: isSmallScreen ? 15 : 25,
              height: 1,
              color: Colors.white30,
            ),
            _buildTimeIndicator('🍕', '30 min', 'Tu comida', isSmallScreen),
          ],
        ),
        
        SizedBox(height: isVerySmallScreen ? 6 : 10),
        
        // Términos minimalistas
        Text(
          'Al continuar aceptas términos y condiciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: isSmallScreen ? 9 : 10,
            height: 1.4,
          ),
        ),
        
        // Pequeño padding inferior para evitar que se pegue al borde
        SizedBox(height: isVerySmallScreen ? 4 : 8),
      ],
    );
  }

  Widget _buildTimeIndicator(String emoji, String time, String label, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            color: const Color(0xFFFFC93C),
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isSmallScreen ? 8 : 9,
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
// import 'package:zonix/features/services/auth/api_service.dart';
// import 'package:zonix/main.dart';
// import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:zonix/features/utils/auth_utils.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_button/sign_in_button.dart';
// import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// const FlutterSecureStorage _storage = FlutterSecureStorage();
// final ApiService apiService = ApiService();
// final logger = Logger();

// class SignInScreen extends StatefulWidget {
//   const SignInScreen({super.key});

//   @override
//   SignInScreenState createState() => SignInScreenState();
// }

// class SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
//   final GoogleSignInService googleSignInService = GoogleSignInService();
//   bool isAuthenticated = false;
//   GoogleSignInAccount? _currentUser;
//   late AnimationController _pulseController;
//   late AnimationController _rotateController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _rotateAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _checkAuthentication();
//   }

//   void _setupAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _rotateController = AnimationController(
//       duration: const Duration(seconds: 20),
//       vsync: this,
//     )..repeat();
    
//     _pulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
    
//     _rotateAnimation = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(_rotateController);
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _rotateController.dispose();
//     super.dispose();
//   }

//   Future<void> _checkAuthentication() async {
//     isAuthenticated = await AuthUtils.isAuthenticated();
//     if (isAuthenticated) {
//       _currentUser = await GoogleSignInService.getCurrentUser();
//       if (_currentUser != null) {
//         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
//         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
//         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
//         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _handleSignIn() async {
//     try {
//       await GoogleSignInService.signInWithGoogle();
//       _currentUser = await GoogleSignInService.getCurrentUser();
//       setState(() {});

//       if (_currentUser != null) {
//         await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
//         await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
//         await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

//         String? savedName = await _storage.read(key: 'userName');
//         String? savedEmail = await _storage.read(key: 'userEmail');
//         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
//         String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

//         logger.i('Nombre guardado: $savedName');
//         logger.i('Correo guardado: $savedEmail');
//         logger.i('Foto guardada: $savedPhotoUrl');
//         logger.i('Onboarding guardada: $savedOnboardingString');

//         bool onboardingCompleted = savedOnboardingString == '1';
//         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

//         if (!mounted) return;

//         if (!onboardingCompleted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const MainRouter()),
//           );
//         }
//       } else {
//         logger.i('Inicio de sesión cancelado o fallido');
//       }
//     } catch (e) {
//       logger.e('Error durante el manejo del inicio de sesión: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//     final isLargeScreen = screenWidth > 600;
//     final isVerySmallScreen = screenHeight < 600;
    
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Fondo con patrón geométrico
//           _buildGeometricBackground(),
          
//           // Contenido principal
//           SafeArea(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 return Container(
//                   height: constraints.maxHeight,
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isSmallScreen ? 16 : 24,
//                     vertical: isVerySmallScreen ? 8 : 16,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Header minimalista
//                       _buildMinimalHeader(isSmallScreen),
                      
//                       // Espacio flexible para el círculo central
//                       Flexible(
//                         fit: isVerySmallScreen ? FlexFit.loose : FlexFit.tight,
//                         child: _buildCentralCircle(screenWidth, isSmallScreen, isLargeScreen, isVerySmallScreen),
//                       ),
                      
//                       // Espacio flexible para el contenido inferior
//                       Flexible(
//                         fit: isVerySmallScreen ? FlexFit.loose : FlexFit.tight,
//                         child: _buildBottomContent(screenWidth, isSmallScreen, isLargeScreen, isVerySmallScreen),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGeometricBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A1A2E),
//       ),
//       child: Stack(
//         children: [
//           // Círculos decorativos animados
//           Positioned(
//             top: -50,
//             right: -50,
//             child: RotationTransition(
//               turns: _rotateAnimation,
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFFFF6B35).withOpacity(0.1),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -100,
//             left: -100,
//             child: RotationTransition(
//               turns: _rotateAnimation,
//               child: Container(
//                 width: 300,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFFFFC93C).withOpacity(0.08),
//                 ),
//               ),
//             ),
//           ),
//           // Patrón de puntos
//           // ...List.generate(20, (index) {
//           //   return Positioned(
//           //     top: (index * 50.0) % MediaQuery.of(context).size.height,
//           //     left: (index * 80.0) % MediaQuery.of(context).size.width,
//           //     child: Container(
//           //       width: 4,
//           //       height: 4,
//           //       decoration: BoxDecoration(
//           //         shape: BoxShape.circle,
//           //         color: Colors.white.withOpacity(0.1),
//           //       ),
//           //     ),
//           //   );
//           // }),
//           ...List.generate(20, (index) {
//             return Positioned(
//               // top: (index * 50.0) % MediaQuery.of(context).size.height,
//               // left: (index * 80.0) % MediaQuery.of(context).size.width,
//               top: ((index * 50.0) % MediaQuery.of(context).size.height).roundToDouble(),
//               left: ((index * 80.0) % MediaQuery.of(context).size.width).roundToDouble(), 
//               child: Container(
//                 width: 4,  // Asegúrate de que sea entero
//                 height: 4, // Asegúrate de que sea entero
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildMinimalHeader(bool isSmallScreen) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '16:24',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isSmallScreen ? 14 : 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: isSmallScreen ? 8 : 12, 
//               vertical: isSmallScreen ? 4 : 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFC93C).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               'FOOD APP',
//               style: TextStyle(
//                 color: const Color(0xFFFFC93C),
//                 fontSize: isSmallScreen ? 10 : 12,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 1,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCentralCircle(double screenWidth, bool isSmallScreen, bool isLargeScreen, bool isVerySmallScreen) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Círculo principal animado
//           ScaleTransition(
//             scale: _pulseAnimation,
//             child: Container(
//               width: isSmallScreen 
//                   ? screenWidth * (isVerySmallScreen ? 0.6 : 0.7)
//                   : isLargeScreen 
//                       ? screenWidth * 0.4 
//                       : screenWidth * 0.6,
//               height: isSmallScreen 
//                   ? screenWidth * (isVerySmallScreen ? 0.6 : 0.7)
//                   : isLargeScreen 
//                       ? screenWidth * 0.4 
//                       : screenWidth * 0.6,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: const Color(0xFFFF6B35),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFFFF6B35).withOpacity(0.4),
//                     blurRadius: 40,
//                     spreadRadius: 10,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo principal
//                   Container(
//                     padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
//                     ),
//                     child: Icon(
//                       Icons.fastfood,
//                       size: isSmallScreen ? 36 : 48,
//                       color: const Color(0xFFFF6B35),
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 12 : 20),
//                   // Nombre de la app
//                   RichText(
//                     text: TextSpan(
//                       children: [
//                         TextSpan(
//                           text: 'ZONI',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 22 : 28,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.white,
//                             letterSpacing: 2,
//                           ),
//                         ),
//                         TextSpan(
//                           text: 'X',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 22 : 28,
//                             fontWeight: FontWeight.w900,
//                             color: const Color(0xFFFFC93C),
//                             letterSpacing: 2,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: isSmallScreen ? 6 : 8),
//                   Text(
//                     'FOOD DELIVERY',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: isSmallScreen ? 10 : 12,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: 3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           SizedBox(height: isVerySmallScreen ? 12 : 20),
          
//           // Texto de bienvenida
//           Text(
//             'Tu hambre, nuestra misión',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isSmallScreen ? 16 : 20,
//               fontWeight: FontWeight.w300,
//               letterSpacing: 1,
//             ),
//           ),
          
//           SizedBox(height: isVerySmallScreen ? 6 : 8),
          
//           // Container(
//           //   padding: EdgeInsets.symmetric(
//           //     horizontal: isSmallScreen ? 12 : 16, 
//           //     vertical: isSmallScreen ? 4 : 6),
//           //   decoration: BoxDecoration(
//           //     color: const Color(0xFFFFC93C).withOpacity(0.2),
//           //     borderRadius: BorderRadius.circular(25),
//           //   ),
//           //   child: Text(
//           //     '🍕 🍔 🍟 🌮 🍗 🍜',
//           //     style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
//           //   ),
//           // ),


//            Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFC93C).withOpacity(0.2),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: const Text(
//               '🍕 🍔 🍟 🌮 🍗 🍜',
//               style: TextStyle(fontSize: 20),
//             ),
//           ),




          
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomContent(double screenWidth, bool isSmallScreen, bool isLargeScreen, bool isVerySmallScreen) {
//     return Container(
//       padding: EdgeInsets.only(top: isVerySmallScreen ? 8 : 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min, 
//       mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Mensaje motivacional
//           Text(
//             'Miles de restaurantes te esperan',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: isSmallScreen ? 14 : 16,
//               fontWeight: FontWeight.w400,
//               height: 1.4,
//             ),
//           ),
          
//           SizedBox(height: isVerySmallScreen ? 12 : 20),
          
//           // Botón de Google con diseño futurista
//           Container(
//             width: isLargeScreen ? screenWidth * 0.6 : double.infinity,
//             height: isSmallScreen ? 48 : 56,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(30),
//               border: Border.all(
//                 color: const Color(0xFFFFC93C),
//                 width: 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFFFFC93C).withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: _handleSignIn,
//                 borderRadius: BorderRadius.circular(30),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF8F9FA),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Image.asset(
//                           'assets/images/google_logo.png',
//                           height: isSmallScreen ? 18 : 22,
//                           width: isSmallScreen ? 18 : 22,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Icon(
//                               Icons.login,
//                               size: isSmallScreen ? 18 : 22,
//                               color: const Color(0xFF4285F4),
//                             );
//                           },
//                         ),
//                       ),
//                       SizedBox(width: isSmallScreen ? 8 : 12),
//                       Text(
//                         'EMPEZAR CON GOOGLE',
//                         style: TextStyle(
//                           fontSize: isSmallScreen ? 12 : 14,
//                           fontWeight: FontWeight.w800,
//                           color: const Color(0xFF1A1A2E),
//                           letterSpacing: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           SizedBox(height: isVerySmallScreen ? 12 : 16),
          
//           // Indicadores de tiempo
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildTimeIndicator('⚡', '5 min', 'Registro', isSmallScreen),
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
//                 width: isSmallScreen ? 20 : 30,
//                 height: 1,
//                 color: Colors.white30,
//               ),
//               _buildTimeIndicator('🍕', '30 min', 'Tu comida', isSmallScreen),
//             ],
//           ),
          
//           SizedBox(height: isVerySmallScreen ? 8 : 12),
          
//           // Términos minimalistas
//           Text(
//             'Al continuar aceptas términos y condiciones',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.6),
//               fontSize: isSmallScreen ? 10 : 11,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeIndicator(String emoji, String time, String label, bool isSmallScreen) {
//     return Column(
//       children: [
//         Text(
//           emoji,
//           style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
//         ),
//      const   SizedBox(height: 2),
//         Text(
//           time,
//           style: TextStyle(
//             color: const Color(0xFFFFC93C),
//             fontSize: isSmallScreen ? 12 : 14,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.7),
//             fontSize: isSmallScreen ? 9 : 10,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:logger/logger.dart';
// // import 'package:zonix/features/services/auth/api_service.dart';
// // import 'package:zonix/main.dart';
// // import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import 'package:zonix/features/utils/auth_utils.dart';
// // import 'package:google_sign_in/google_sign_in.dart';
// // import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// // const FlutterSecureStorage _storage = FlutterSecureStorage();
// // final ApiService apiService = ApiService();
// // final logger = Logger();

// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});

// //   @override
// //   SignInScreenState createState() => SignInScreenState();
// // }

// // class SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
// //   final GoogleSignInService googleSignInService = GoogleSignInService();
// //   bool isAuthenticated = false;
// //   GoogleSignInAccount? _currentUser;
// //   late AnimationController _pulseController;
// //   late AnimationController _rotateController;
// //   late Animation<double> _pulseAnimation;
// //   late Animation<double> _rotateAnimation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _setupAnimations();
// //     _checkAuthentication();
// //   }

// //   void _setupAnimations() {
// //     _pulseController = AnimationController(
// //       duration: const Duration(seconds: 2),
// //       vsync: this,
// //     )..repeat(reverse: true);
    
// //     _rotateController = AnimationController(
// //       duration: const Duration(seconds: 20),
// //       vsync: this,
// //     )..repeat();
    
// //     _pulseAnimation = Tween<double>(
// //       begin: 0.8,
// //       end: 1.0,
// //     ).animate(CurvedAnimation(
// //       parent: _pulseController,
// //       curve: Curves.easeInOut,
// //     ));
    
// //     _rotateAnimation = Tween<double>(
// //       begin: 0,
// //       end: 1,
// //     ).animate(_rotateController);
// //   }

// //   @override
// //   void dispose() {
// //     _pulseController.dispose();
// //     _rotateController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _checkAuthentication() async {
// //     isAuthenticated = await AuthUtils.isAuthenticated();
// //     if (isAuthenticated) {
// //       _currentUser = await GoogleSignInService.getCurrentUser();
// //       if (_currentUser != null) {
// //         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
// //         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
// //         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
// //         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
// //       }
// //     }
// //     setState(() {});
// //   }

// //   Future<void> _handleSignIn() async {
// //     try {
// //       await GoogleSignInService.signInWithGoogle();
// //       _currentUser = await GoogleSignInService.getCurrentUser();
// //       setState(() {});

// //       if (_currentUser != null) {
// //         await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
// //         await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
// //         await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

// //         String? savedName = await _storage.read(key: 'userName');
// //         String? savedEmail = await _storage.read(key: 'userEmail');
// //         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
// //         String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

// //         logger.i('Nombre guardado: $savedName');
// //         logger.i('Correo guardado: $savedEmail');
// //         logger.i('Foto guardada: $savedPhotoUrl');
// //         logger.i('Onboarding guardada: $savedOnboardingString');

// //         bool onboardingCompleted = savedOnboardingString == '1';
// //         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

// //         if (!mounted) return;

// //         if (!onboardingCompleted) {
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
// //           );
// //         } else {
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(builder: (context) => const MainRouter()),
// //           );
// //         }
// //       } else {
// //         logger.i('Inicio de sesión cancelado o fallido');
// //       }
// //     } catch (e) {
// //       logger.e('Error durante el manejo del inicio de sesión: $e');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final screenHeight = MediaQuery.of(context).size.height;
// //     final screenWidth = MediaQuery.of(context).size.width;
// //     final isSmallScreen = screenWidth < 400;
// //     final isLargeScreen = screenWidth > 600;
    
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // Fondo con patrón geométrico
// //           _buildGeometricBackground(),
          
// //           // Contenido principal
// //           SafeArea(
// //             child: SingleChildScrollView(
// //               child: ConstrainedBox(
// //                 constraints: BoxConstraints(
// //                   minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
// //                 ),
// //                 child: IntrinsicHeight(
// //                   child: Column(
// //                     children: [
// //                       // Header minimalista
// //                       _buildMinimalHeader(isSmallScreen),
                      
// //                       // Círculo central con logo animado
// //                       Expanded(
// //                         flex: isSmallScreen ? 2 : 3,
// //                         child: _buildCentralCircle(screenWidth, isSmallScreen, isLargeScreen),
// //                       ),
                      
// //                       // Sección inferior con botón
// //                       Expanded(
// //                         flex: isSmallScreen ? 3 : 2,
// //                         child: _buildBottomContent(screenWidth, isSmallScreen, isLargeScreen),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildGeometricBackground() {
// //     return Container(
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF1A1A2E),
// //       ),
// //       child: Stack(
// //         children: [
// //           // Círculos decorativos animados
// //           Positioned(
// //             top: -50,
// //             right: -50,
// //             child: RotationTransition(
// //               turns: _rotateAnimation,
// //               child: Container(
// //                 width: 200,
// //                 height: 200,
// //                 decoration: BoxDecoration(
// //                   shape: BoxShape.circle,
// //                   color: const Color(0xFFFF6B35).withOpacity(0.1),
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Positioned(
// //             bottom: -100,
// //             left: -100,
// //             child: RotationTransition(
// //               turns: _rotateAnimation,
// //               child: Container(
// //                 width: 300,
// //                 height: 300,
// //                 decoration: BoxDecoration(
// //                   shape: BoxShape.circle,
// //                   color: const Color(0xFFFFC93C).withOpacity(0.08),
// //                 ),
// //               ),
// //             ),
// //           ),
// //           // Patrón de puntos
// //           ...List.generate(20, (index) {
// //             return Positioned(
// //               top: (index * 50.0) % MediaQuery.of(context).size.height,
// //               left: (index * 80.0) % MediaQuery.of(context).size.width,
// //               child: Container(
// //                 width: 4,
// //                 height: 4,
// //                 decoration: BoxDecoration(
// //                   shape: BoxShape.circle,
// //                   color: Colors.white.withOpacity(0.1),
// //                 ),
// //               ),
// //             );
// //           }),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildMinimalHeader(bool isSmallScreen) {
// //     return Padding(
// //       padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(
// //             '16:24',
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: isSmallScreen ? 14 : 16,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //           Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: isSmallScreen ? 8 : 12, 
// //               vertical: isSmallScreen ? 4 : 6),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFFFFC93C).withOpacity(0.2),
// //               borderRadius: BorderRadius.circular(20),
// //             ),
// //             child: Text(
// //               'FOOD APP',
// //               style: TextStyle(
// //                 color: const Color(0xFFFFC93C),
// //                 fontSize: isSmallScreen ? 10 : 12,
// //                 fontWeight: FontWeight.w700,
// //                 letterSpacing: 1,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildCentralCircle(double screenWidth, bool isSmallScreen, bool isLargeScreen) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           // Círculo principal animado
// //           ScaleTransition(
// //             scale: _pulseAnimation,
// //             child: Container(
// //               width: isSmallScreen 
// //                   ? screenWidth * 0.7 
// //                   : isLargeScreen 
// //                       ? screenWidth * 0.4 
// //                       : screenWidth * 0.6,
// //               height: isSmallScreen 
// //                   ? screenWidth * 0.7 
// //                   : isLargeScreen 
// //                       ? screenWidth * 0.4 
// //                       : screenWidth * 0.6,
// //               decoration: BoxDecoration(
// //                 shape: BoxShape.circle,
// //                 color: const Color(0xFFFF6B35),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: const Color(0xFFFF6B35).withOpacity(0.4),
// //                     blurRadius: 40,
// //                     spreadRadius: 10,
// //                   ),
// //                 ],
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   // Logo principal
// //                   Container(
// //                     padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
// //                     ),
// //                     child: Icon(
// //                       Icons.fastfood,
// //                       size: isSmallScreen ? 36 : 48,
// //                       color: const Color(0xFFFF6B35),
// //                     ),
// //                   ),
// //                   SizedBox(height: isSmallScreen ? 12 : 20),
// //                   // Nombre de la app
// //                   RichText(
// //                     text: TextSpan(
// //                       children: [
// //                         TextSpan(
// //                           text: 'ZONI',
// //                           style: TextStyle(
// //                             fontSize: isSmallScreen ? 22 : 28,
// //                             fontWeight: FontWeight.w900,
// //                             color: Colors.white,
// //                             letterSpacing: 2,
// //                           ),
// //                         ),
// //                         TextSpan(
// //                           text: 'X',
// //                           style: TextStyle(
// //                             fontSize: isSmallScreen ? 22 : 28,
// //                             fontWeight: FontWeight.w900,
// //                             color: const Color(0xFFFFC93C),
// //                             letterSpacing: 2,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   SizedBox(height: isSmallScreen ? 6 : 8),
// //                   Text(
// //                     'FOOD DELIVERY',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: isSmallScreen ? 10 : 12,
// //                       fontWeight: FontWeight.w600,
// //                       letterSpacing: 3,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 20 : 40),
          
// //           // Texto de bienvenida
// //           Text(
// //             'Tu hambre, nuestra misión',
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: isSmallScreen ? 18 : 24,
// //               fontWeight: FontWeight.w300,
// //               letterSpacing: 1,
// //             ),
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 8 : 12),
          
// //           Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: isSmallScreen ? 16 : 20, 
// //               vertical: isSmallScreen ? 6 : 8),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFFFFC93C).withOpacity(0.2),
// //               borderRadius: BorderRadius.circular(25),
// //             ),
// //             child: Text(
// //               '🍕 🍔 🍟 🌮 🍗 🍜',
// //               style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildBottomContent(double screenWidth, bool isSmallScreen, bool isLargeScreen) {
// //     return Padding(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: isSmallScreen ? 16 : 24,
// //         vertical: isSmallScreen ? 8 : 0,
// //       ),
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           // Mensaje motivacional
// //           Text(
// //             'Miles de restaurantes te esperan',
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               color: Colors.white70,
// //               fontSize: isSmallScreen ? 16 : 18,
// //               fontWeight: FontWeight.w400,
// //               height: 1.4,
// //             ),
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 20 : 32),
          
// //           // Botón de Google con diseño futurista
// //           Container(
// //             width: isLargeScreen ? screenWidth * 0.6 : double.infinity,
// //             height: isSmallScreen ? 50 : 60,
// //             decoration: BoxDecoration(
// //               borderRadius: BorderRadius.circular(30),
// //               border: Border.all(
// //                 color: const Color(0xFFFFC93C),
// //                 width: 2,
// //               ),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: const Color(0xFFFFC93C).withOpacity(0.3),
// //                   blurRadius: 20,
// //                   offset: const Offset(0, 8),
// //                 ),
// //               ],
// //             ),
// //             child: Material(
// //               color: Colors.transparent,
// //               child: InkWell(
// //                 onTap: _handleSignIn,
// //                 borderRadius: BorderRadius.circular(30),
// //                 child: Container(
// //                   decoration: BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.circular(28),
// //                   ),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Container(
// //                         padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
// //                         decoration: BoxDecoration(
// //                           color: const Color(0xFFF8F9FA),
// //                           borderRadius: BorderRadius.circular(12),
// //                         ),
// //                         child: Image.asset(
// //                           'assets/images/google_logo.png',
// //                           height: isSmallScreen ? 20 : 24,
// //                           width: isSmallScreen ? 20 : 24,
// //                           errorBuilder: (context, error, stackTrace) {
// //                             return Icon(
// //                               Icons.login,
// //                               size: isSmallScreen ? 20 : 24,
// //                               color: const Color(0xFF4285F4),
// //                             );
// //                           },
// //                         ),
// //                       ),
// //                       SizedBox(width: isSmallScreen ? 12 : 16),
// //                       Text(
// //                         'EMPEZAR CON GOOGLE',
// //                         style: TextStyle(
// //                           fontSize: isSmallScreen ? 14 : 16,
// //                           fontWeight: FontWeight.w800,
// //                           color: const Color(0xFF1A1A2E),
// //                           letterSpacing: 1,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 16 : 24),
          
// //           // Indicadores de tiempo
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               _buildTimeIndicator('⚡', '5 min', 'Registro', isSmallScreen),
// //               Container(
// //                 margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
// //                 width: isSmallScreen ? 30 : 40,
// //                 height: 1,
// //                 color: Colors.white30,
// //               ),
// //               _buildTimeIndicator('🍕', '30 min', 'Tu comida', isSmallScreen),
// //             ],
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 16 : 24),
          
// //           // Términos minimalistas
// //           Text(
// //             'Al continuar aceptas términos y condiciones',
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               color: Colors.white.withOpacity(0.6),
// //               fontSize: isSmallScreen ? 10 : 12,
// //               height: 1.4,
// //             ),
// //           ),
          
// //           SizedBox(height: isSmallScreen ? 16 : 20),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTimeIndicator(String emoji, String time, String label, bool isSmallScreen) {
// //     return Column(
// //       children: [
// //         Text(
// //           emoji,
// //           style: TextStyle(fontSize: isSmallScreen ? 20 : 24),
// //         ),
// //         SizedBox(height: isSmallScreen ? 2 : 4),
// //         Text(
// //           time,
// //           style: TextStyle(
// //             color: const Color(0xFFFFC93C),
// //             fontSize: isSmallScreen ? 14 : 16,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         Text(
// //           label,
// //           style: TextStyle(
// //             color: Colors.white.withOpacity(0.7),
// //             fontSize: isSmallScreen ? 10 : 12,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:logger/logger.dart';
// // // import 'package:zonix/features/services/auth/api_service.dart';
// // // import 'package:zonix/main.dart';
// // // import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // // import 'package:zonix/features/utils/auth_utils.dart';
// // // import 'package:google_sign_in/google_sign_in.dart';
// // // import 'package:sign_in_button/sign_in_button.dart';
// // // import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// // // const FlutterSecureStorage _storage = FlutterSecureStorage();
// // // final ApiService apiService = ApiService();
// // // final logger = Logger();

// // // class SignInScreen extends StatefulWidget {
// // //   const SignInScreen({super.key});

// // //   @override
// // //   SignInScreenState createState() => SignInScreenState();
// // // }

// // // class SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
// // //   final GoogleSignInService googleSignInService = GoogleSignInService();
// // //   bool isAuthenticated = false;
// // //   GoogleSignInAccount? _currentUser;
// // //   late AnimationController _pulseController;
// // //   late AnimationController _rotateController;
// // //   late Animation<double> _pulseAnimation;
// // //   late Animation<double> _rotateAnimation;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _setupAnimations();
// // //     _checkAuthentication();
// // //   }

// // //   void _setupAnimations() {
// // //     _pulseController = AnimationController(
// // //       duration: const Duration(seconds: 2),
// // //       vsync: this,
// // //     )..repeat(reverse: true);
    
// // //     _rotateController = AnimationController(
// // //       duration: const Duration(seconds: 20),
// // //       vsync: this,
// // //     )..repeat();
    
// // //     _pulseAnimation = Tween<double>(
// // //       begin: 0.8,
// // //       end: 1.0,
// // //     ).animate(CurvedAnimation(
// // //       parent: _pulseController,
// // //       curve: Curves.easeInOut,
// // //     ));
    
// // //     _rotateAnimation = Tween<double>(
// // //       begin: 0,
// // //       end: 1,
// // //     ).animate(_rotateController);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _pulseController.dispose();
// // //     _rotateController.dispose();
// // //     super.dispose();
// // //   }

// // //   Future<void> _checkAuthentication() async {
// // //     isAuthenticated = await AuthUtils.isAuthenticated();
// // //     if (isAuthenticated) {
// // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // //       if (_currentUser != null) {
// // //         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
// // //         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
// // //         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
// // //         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
// // //       }
// // //     }
// // //     setState(() {});
// // //   }

// // //   Future<void> _handleSignIn() async {
// // //     try {
// // //       await GoogleSignInService.signInWithGoogle();
// // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // //       setState(() {});

// // //       if (_currentUser != null) {
// // //         await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
// // //         await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
// // //         await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

// // //         String? savedName = await _storage.read(key: 'userName');
// // //         String? savedEmail = await _storage.read(key: 'userEmail');
// // //         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
// // //         String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

// // //         logger.i('Nombre guardado: $savedName');
// // //         logger.i('Correo guardado: $savedEmail');
// // //         logger.i('Foto guardada: $savedPhotoUrl');
// // //         logger.i('Onboarding guardada: $savedOnboardingString');

// // //         bool onboardingCompleted = savedOnboardingString == '1';
// // //         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

// // //         if (!mounted) return;

// // //         if (!onboardingCompleted) {
// // //           Navigator.pushReplacement(
// // //             context,
// // //             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
// // //           );
// // //         } else {
// // //           Navigator.pushReplacement(
// // //             context,
// // //             MaterialPageRoute(builder: (context) => const MainRouter()),
// // //           );
// // //         }
// // //       } else {
// // //         logger.i('Inicio de sesión cancelado o fallido');
// // //       }
// // //     } catch (e) {
// // //       logger.e('Error durante el manejo del inicio de sesión: $e');
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final screenHeight = MediaQuery.of(context).size.height;
// // //     final screenWidth = MediaQuery.of(context).size.width;
    
// // //     return Scaffold(
// // //       body: Stack(
// // //         children: [
// // //           // Fondo con patrón geométrico
// // //           _buildGeometricBackground(),
          
// // //           // Contenido principal
// // //           SafeArea(
// // //             child: SingleChildScrollView(
// // //               child: ConstrainedBox(
// // //                 constraints: BoxConstraints(
// // //                   minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
// // //                 ),
// // //                 child: IntrinsicHeight(
// // //                   child: Column(
// // //                     children: [
// // //                       // Header minimalista
// // //                       _buildMinimalHeader(),
                      
// // //                       // Círculo central con logo animado
// // //                       Expanded(
// // //                         flex: 3,
// // //                         child: _buildCentralCircle(screenWidth),
// // //                       ),
                      
// // //                       // Sección inferior con botón
// // //                       Expanded(
// // //                         flex: 2,
// // //                         child: _buildBottomContent(screenWidth),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildGeometricBackground() {
// // //     return Container(
// // //       decoration: const BoxDecoration(
// // //         color: Color(0xFF1A1A2E), // Azul marino oscuro - sofisticación y confianza
// // //       ),
// // //       child: Stack(
// // //         children: [
// // //           // Círculos decorativos animados
// // //           Positioned(
// // //             top: -50,
// // //             right: -50,
// // //             child: RotationTransition(
// // //               turns: _rotateAnimation,
// // //               child: Container(
// // //                 width: 200,
// // //                 height: 200,
// // //                 decoration: BoxDecoration(
// // //                   shape: BoxShape.circle,
// // //                   color: const Color(0xFFFF6B35).withOpacity(0.1), // Naranja sutil
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           Positioned(
// // //             bottom: -100,
// // //             left: -100,
// // //             child: RotationTransition(
// // //               turns: _rotateAnimation,
// // //               child: Container(
// // //                 width: 300,
// // //                 height: 300,
// // //                 decoration: BoxDecoration(
// // //                   shape: BoxShape.circle,
// // //                   color: const Color(0xFFFFC93C).withOpacity(0.08), // Amarillo sutil
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           // Patrón de puntos
// // //           ...List.generate(20, (index) {
// // //             return Positioned(
// // //               top: (index * 50.0) % MediaQuery.of(context).size.height,
// // //               left: (index * 80.0) % MediaQuery.of(context).size.width,
// // //               child: Container(
// // //                 width: 4,
// // //                 height: 4,
// // //                 decoration: BoxDecoration(
// // //                   shape: BoxShape.circle,
// // //                   color: Colors.white.withOpacity(0.1),
// // //                 ),
// // //               ),
// // //             );
// // //           }),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildMinimalHeader() {
// // //     return Padding(
// // //       padding: const EdgeInsets.all(20),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           const Text(
// // //             '16:24',
// // //             style: TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 16,
// // //               fontWeight: FontWeight.w500,
// // //             ),
// // //           ),
// // //           Container(
// // //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //             decoration: BoxDecoration(
// // //               color: const Color(0xFFFFC93C).withOpacity(0.2), // Amarillo sutil
// // //               borderRadius: BorderRadius.circular(20),
// // //             ),
// // //             child: const Text(
// // //               'FOOD APP',
// // //               style: TextStyle(
// // //                 color: Color(0xFFFFC93C), // Amarillo dorado - alegría y apetito
// // //                 fontSize: 12,
// // //                 fontWeight: FontWeight.w700,
// // //                 letterSpacing: 1,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildCentralCircle(double screenWidth) {
// // //     return Center(
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           // Círculo principal animado
// // //           ScaleTransition(
// // //             scale: _pulseAnimation,
// // //             child: Container(
// // //               width: screenWidth * 0.6,
// // //               height: screenWidth * 0.6,
// // //               decoration: BoxDecoration(
// // //                 shape: BoxShape.circle,
// // //                 color: const Color(0xFFFF6B35), // Naranja intenso - hambre y energía
// // //                 boxShadow: [
// // //                   BoxShadow(
// // //                     color: const Color(0xFFFF6B35).withOpacity(0.4),
// // //                     blurRadius: 40,
// // //                     spreadRadius: 10,
// // //                   ),
// // //                 ],
// // //               ),
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   // Logo principal
// // //                   Container(
// // //                     padding: const EdgeInsets.all(16),
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.white,
// // //                       borderRadius: BorderRadius.circular(20),
// // //                     ),
// // //                     child: const Icon(
// // //                       Icons.fastfood,
// // //                       size: 48,
// // //                       color: Color(0xFFFF6B35),
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 20),
// // //                   // Nombre de la app
// // //                   RichText(
// // //                     text: const TextSpan(
// // //                       children: [
// // //                         TextSpan(
// // //                           text: 'ZONI',
// // //                           style: TextStyle(
// // //                             fontSize: 28,
// // //                             fontWeight: FontWeight.w900,
// // //                             color: Colors.white,
// // //                             letterSpacing: 2,
// // //                           ),
// // //                         ),
// // //                         TextSpan(
// // //                           text: 'X',
// // //                           style: TextStyle(
// // //                             fontSize: 28,
// // //                             fontWeight: FontWeight.w900,
// // //                             color: Color(0xFFFFC93C), // Amarillo dorado
// // //                             letterSpacing: 2,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 8),
// // //                   const Text(
// // //                     'FOOD DELIVERY',
// // //                     style: TextStyle(
// // //                       color: Colors.white,
// // //                       fontSize: 12,
// // //                       fontWeight: FontWeight.w600,
// // //                       letterSpacing: 3,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
          
// // //           const SizedBox(height: 40),
          
// // //           // Texto de bienvenida
// // //           const Text(
// // //             'Tu hambre, nuestra misión',
// // //             style: TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 24,
// // //               fontWeight: FontWeight.w300,
// // //               letterSpacing: 1,
// // //             ),
// // //           ),
          
// // //           const SizedBox(height: 12),
          
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFFFFC93C).withOpacity(0.2),
// //               borderRadius: BorderRadius.circular(25),
// //             ),
// //             child: const Text(
// //               '🍕 🍔 🍟 🌮 🍗 🍜',
// //               style: TextStyle(fontSize: 20),
// //             ),
// //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildBottomContent(double screenWidth) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 24),
// // //       child: Column(
// // //         children: [
// // //           // Mensaje motivacional
// // //           const Text(
// // //             'Miles de restaurantes te esperan',
// // //             textAlign: TextAlign.center,
// // //             style: TextStyle(
// // //               color: Colors.white70,
// // //               fontSize: 18,
// // //               fontWeight: FontWeight.w400,
// // //               height: 1.4,
// // //             ),
// // //           ),
          
// // //           const SizedBox(height: 32),
          
// // //           // Botón de Google con diseño futurista
// // //           Container(
// // //             width: double.infinity,
// // //             height: 60,
// // //             decoration: BoxDecoration(
// // //               borderRadius: BorderRadius.circular(30),
// // //               border: Border.all(
// // //                 color: const Color(0xFFFFC93C), // Amarillo dorado
// // //                 width: 2,
// // //               ),
// // //               boxShadow: [
// // //                 BoxShadow(
// // //                   color: const Color(0xFFFFC93C).withOpacity(0.3),
// // //                   blurRadius: 20,
// // //                   offset: const Offset(0, 8),
// // //                 ),
// // //               ],
// // //             ),
// // //             child: Material(
// // //               color: Colors.transparent,
// // //               child: InkWell(
// // //                 onTap: _handleSignIn,
// // //                 borderRadius: BorderRadius.circular(30),
// // //                 child: Container(
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white,
// // //                     borderRadius: BorderRadius.circular(28),
// // //                   ),
// // //                   child: Row(
// // //                     mainAxisAlignment: MainAxisAlignment.center,
// // //                     children: [
// // //                       Container(
// // //                         padding: const EdgeInsets.all(8),
// // //                         decoration: BoxDecoration(
// // //                           color: const Color(0xFFF8F9FA),
// // //                           borderRadius: BorderRadius.circular(12),
// // //                         ),
// // //                         child: Image.asset(
// // //                           'assets/images/google_logo.png',
// // //                           height: 24,
// // //                           width: 24,
// // //                           errorBuilder: (context, error, stackTrace) {
// // //                             return const Icon(
// // //                               Icons.login,
// // //                               size: 24,
// // //                               color: Color(0xFF4285F4),
// // //                             );
// // //                           },
// // //                         ),
// // //                       ),
// // //                       const SizedBox(width: 16),
// // //                       const Text(
// // //                         'EMPEZAR CON GOOGLE',
// // //                         style: TextStyle(
// // //                           fontSize: 16,
// // //                           fontWeight: FontWeight.w800,
// // //                           color: Color(0xFF1A1A2E),
// // //                           letterSpacing: 1,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
          
// // //           const SizedBox(height: 24),
          
// // //           // Indicadores de tiempo
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               _buildTimeIndicator('⚡', '5 min', 'Registro'),
// // //               Container(
// // //                 margin: const EdgeInsets.symmetric(horizontal: 16),
// // //                 width: 40,
// // //                 height: 1,
// // //                 color: Colors.white30,
// // //               ),
// // //               _buildTimeIndicator('🍕', '30 min', 'Tu comida'),
// // //             ],
// // //           ),
          
// // //           const SizedBox(height: 24),
          
// // //           // Términos minimalistas
// // //           Text(
// // //             'Al continuar aceptas términos y condiciones',
// // //             textAlign: TextAlign.center,
// // //             style: TextStyle(
// // //               color: Colors.white.withOpacity(0.6),
// // //               fontSize: 12,
// // //               height: 1.4,
// // //             ),
// // //           ),
          
// // //           const SizedBox(height: 20),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildTimeIndicator(String emoji, String time, String label) {
// // //     return Column(
// // //       children: [
// // //         Text(
// // //           emoji,
// // //           style: const TextStyle(fontSize: 24),
// // //         ),
// // //         const SizedBox(height: 4),
// // //         Text(
// // //           time,
// // //           style: const TextStyle(
// // //             color: Color(0xFFFFC93C),
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.w700,
// // //           ),
// // //         ),
// // //         Text(
// // //           label,
// // //           style: TextStyle(
// // //             color: Colors.white.withOpacity(0.7),
// // //             fontSize: 12,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }


// // // // import 'package:flutter/material.dart';
// // // // import 'package:logger/logger.dart';
// // // // import 'package:zonix/features/services/auth/api_service.dart';
// // // // import 'package:zonix/main.dart';
// // // // import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// // // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // // // import 'package:zonix/features/utils/auth_utils.dart';
// // // // import 'package:google_sign_in/google_sign_in.dart';
// // // // import 'package:sign_in_button/sign_in_button.dart';
// // // // import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// // // // const FlutterSecureStorage _storage = FlutterSecureStorage();
// // // // final ApiService apiService = ApiService();
// // // // final logger = Logger();

// // // // class SignInScreen extends StatefulWidget {
// // // //   const SignInScreen({super.key});

// // // //   @override
// // // //   SignInScreenState createState() => SignInScreenState();
// // // // }

// // // // class SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
// // // //   final GoogleSignInService googleSignInService = GoogleSignInService();
// // // //   bool isAuthenticated = false;
// // // //   GoogleSignInAccount? _currentUser;
// // // //   late AnimationController _pulseController;
// // // //   late Animation<double> _pulseAnimation;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _setupAnimations();
// // // //     _checkAuthentication();
// // // //   }

// // // //   void _setupAnimations() {
// // // //     _pulseController = AnimationController(
// // // //       duration: const Duration(seconds: 2),
// // // //       vsync: this,
// // // //     )..repeat(reverse: true);
    
// // // //     _pulseAnimation = Tween<double>(
// // // //       begin: 1.0,
// // // //       end: 1.05,
// // // //     ).animate(CurvedAnimation(
// // // //       parent: _pulseController,
// // // //       curve: Curves.easeInOut,
// // // //     ));
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _pulseController.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   Future<void> _checkAuthentication() async {
// // // //     isAuthenticated = await AuthUtils.isAuthenticated();
// // // //     if (isAuthenticated) {
// // // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // // //       if (_currentUser != null) {
// // // //         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
// // // //         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
// // // //         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
// // // //         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
// // // //       }
// // // //     }
// // // //     setState(() {});
// // // //   }

// // // //   Future<void> _handleSignIn() async {
// // // //     try {
// // // //       await GoogleSignInService.signInWithGoogle();
// // // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // // //       setState(() {});

// // // //       if (_currentUser != null) {
// // // //         await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
// // // //         await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
// // // //         await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

// // // //         String? savedName = await _storage.read(key: 'userName');
// // // //         String? savedEmail = await _storage.read(key: 'userEmail');
// // // //         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
// // // //         String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

// // // //         logger.i('Nombre guardado: $savedName');
// // // //         logger.i('Correo guardado: $savedEmail');
// // // //         logger.i('Foto guardada: $savedPhotoUrl');
// // // //         logger.i('Onboarding guardada: $savedOnboardingString');

// // // //         bool onboardingCompleted = savedOnboardingString == '1';
// // // //         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

// // // //         if (!mounted) return;

// // // //         if (!onboardingCompleted) {
// // // //           Navigator.pushReplacement(
// // // //             context,
// // // //             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
// // // //           );
// // // //         } else {
// // // //           Navigator.pushReplacement(
// // // //             context,
// // // //             MaterialPageRoute(builder: (context) => const MainRouter()),
// // // //           );
// // // //         }
// // // //       } else {
// // // //         logger.i('Inicio de sesión cancelado o fallido');
// // // //       }
// // // //     } catch (e) {
// // // //       logger.e('Error durante el manejo del inicio de sesión: $e');
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final screenHeight = MediaQuery.of(context).size.height;
// // // //     final screenWidth = MediaQuery.of(context).size.width;
    
// // // //     return Scaffold(
// // // //       backgroundColor: const Color(0xFF1A1A1A), // Negro profundo
// // // //       body: Stack(
// // // //         children: [
// // // //           // Background con patrón de círculos
// // // //           _buildBackgroundPattern(),
          
// // // //           // Contenido principal
// // // //           SafeArea(
// // // //             child: SingleChildScrollView(
// // // //               child: ConstrainedBox(
// // // //                 constraints: BoxConstraints(
// // // //                   minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
// // // //                 ),
// // // //                 child: IntrinsicHeight(
// // // //                   child: Padding(
// // // //                     padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
// // // //                     child: Column(
// // // //                       children: [
// // // //                         const SizedBox(height: 60),
                        
// // // //                         // Logo central minimalista
// // // //                         _buildMinimalistLogo(),
                        
// // // //                         const SizedBox(height: 80),
                        
// // // //                         // Título principal
// // // //                         _buildMainTitle(),
                        
// // // //                         const SizedBox(height: 24),
                        
// // // //                         // Subtítulo
// // // //                         _buildSubtitle(),
                        
// // // //                         const Spacer(flex: 2),
                        
// // // //                         // Ilustración central
// // // //                         _buildCentralIllustration(),
                        
// // // //                         const Spacer(flex: 3),
                        
// // // //                         // Botón flotante de Google
// // // //                         _buildFloatingGoogleButton(),
                        
// // // //                         const SizedBox(height: 32),
                        
// // // //                         // Indicadores de beneficios horizontal
// // // //                         _buildHorizontalBenefits(),
                        
// // // //                         const SizedBox(height: 40),
                        
// // // //                         // Términos minimalistas
// // // //                         _buildMinimalTerms(),
                        
// // // //                         const SizedBox(height: 32),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildBackgroundPattern() {
// // // //     return Positioned.fill(
// // // //       child: CustomPaint(
// // // //         painter: CirclePatternPainter(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildMinimalistLogo() {
// // // //     return Column(
// // // //       children: [
// // // //         // Ícono principal con animación
// // // //         ScaleTransition(
// // // //           scale: _pulseAnimation,
// // // //           child: Container(
// // // //             height: 80,
// // // //             width: 80,
// // // //             decoration: BoxDecoration(
// // // //               color: const Color(0xFFFF6B35), // Naranja vibrante
// // // //               borderRadius: BorderRadius.circular(24),
// // // //               boxShadow: [
// // // //                 BoxShadow(
// // // //                   color: const Color(0xFFFF6B35).withOpacity(0.3),
// // // //                   blurRadius: 20,
// // // //                   spreadRadius: 0,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             child: const Icon(
// // // //               Icons.local_dining,
// // // //               color: Colors.white,
// // // //               size: 40,
// // // //             ),
// // // //           ),
// // // //         ),
        
// // // //         const SizedBox(height: 20),
        
// // // //         // Logo texto
// // // //         RichText(
// // // //           text: const TextSpan(
// // // //             children: [
// // // //               TextSpan(
// // // //                 text: 'ZONI',
// // // //                 style: TextStyle(
// // // //                   fontFamily: 'system-ui',
// // // //                   fontSize: 28,
// // // //                   fontWeight: FontWeight.w300, // Más ligero
// // // //                   color: Colors.white,
// // // //                   letterSpacing: 4.0, // Más espaciado
// // // //                 ),
// // // //               ),
// // // //               TextSpan(
// // // //                 text: 'X',
// // // //                 style: TextStyle(
// // // //                   fontFamily: 'system-ui',
// // // //                   fontSize: 28,
// // // //                   fontWeight: FontWeight.w700,
// // // //                   color: Color(0xFFFF6B35),
// // // //                   letterSpacing: 4.0,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildMainTitle() {
// // // //     return const Text(
// // // //       'Sabores que\nte conectan',
// // // //       textAlign: TextAlign.center,
// // // //       style: TextStyle(
// // // //         fontSize: 36,
// // // //         fontWeight: FontWeight.w100, // Ultra ligero
// // // //         color: Colors.white,
// // // //         height: 1.1,
// // // //         letterSpacing: 1.0,
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildSubtitle() {
// // // //     return Container(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 20),
// // // //       child: const Text(
// // // //         'Descubre, ordena y disfruta.\nTodo en un solo lugar.',
// // // //         textAlign: TextAlign.center,
// // // //         style: TextStyle(
// // // //           fontSize: 16,
// // // //           fontWeight: FontWeight.w300,
// // // //           color: Color(0xFF999999),
// // // //           height: 1.6,
// // // //           letterSpacing: 0.5,
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildCentralIllustration() {
// // // //     return Container(
// // // //       height: 200,
// // // //       width: 200,
// // // //       decoration: BoxDecoration(
// // // //         borderRadius: BorderRadius.circular(100),
// // // //         border: Border.all(
// // // //           color: const Color(0xFFFF6B35).withOpacity(0.2),
// // // //           width: 2,
// // // //         ),
// // // //       ),
// // // //       child: ClipRRect(
// // // //         borderRadius: BorderRadius.circular(100),
// // // //         child: Container(
// // // //           color: const Color(0xFF2A2A2A),
// // // //           padding: const EdgeInsets.all(40),
// // // //           child: Image.asset(
// // // //             'assets/images/undraw_launching_szjw.png',
// // // //             fit: BoxFit.contain,
// // // //             color: Colors.white.withOpacity(0.8),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildFloatingGoogleButton() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       height: 60,
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white,
// // // //         borderRadius: BorderRadius.circular(30),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.3),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 10),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Material(
// // // //         color: Colors.transparent,
// // // //         child: InkWell(
// // // //           onTap: _handleSignIn,
// // // //           borderRadius: BorderRadius.circular(30),
// // // //           child: Row(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Image.asset(
// // // //                 'assets/images/google_logo.png',
// // // //                 height: 24,
// // // //                 width: 24,
// // // //                 errorBuilder: (context, error, stackTrace) {
// // // //                   return const Icon(
// // // //                     Icons.login,
// // // //                     size: 24,
// // // //                     color: Color(0xFF4285F4),
// // // //                   );
// // // //                 },
// // // //               ),
// // // //               const SizedBox(width: 16),
// // // //               const Text(
// // // //                 'Continuar con Google',
// // // //                 style: TextStyle(
// // // //                   fontSize: 16,
// // // //                   fontWeight: FontWeight.w500,
// // // //                   color: Color(0xFF1A1A1A),
// // // //                   letterSpacing: 0.5,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildHorizontalBenefits() {
// // // //     return Row(
// // // //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // //       children: [
// // // //         _buildBenefitDot('30min', 'Entrega'),
// // // //         Container(
// // // //           height: 40,
// // // //           width: 1,
// // // //           color: const Color(0xFF333333),
// // // //         ),
// // // //         _buildBenefitDot('500+', 'Opciones'),
// // // //         Container(
// // // //           height: 40,
// // // //           width: 1,
// // // //           color: const Color(0xFF333333),
// // // //         ),
// // // //         _buildBenefitDot('4.9★', 'Rating'),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildBenefitDot(String number, String label) {
// // // //     return Column(
// // // //       children: [
// // // //         Text(
// // // //           number,
// // // //           style: const TextStyle(
// // // //             color: Color(0xFFFF6B35),
// // // //             fontSize: 18,
// // // //             fontWeight: FontWeight.w600,
// // // //             letterSpacing: 0.5,
// // // //           ),
// // // //         ),
// // // //         const SizedBox(height: 4),
// // // //         Text(
// // // //           label,
// // // //           style: const TextStyle(
// // // //             color: Color(0xFF666666),
// // // //             fontSize: 12,
// // // //             fontWeight: FontWeight.w300,
// // // //             letterSpacing: 0.5,
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildMinimalTerms() {
// // // //     return RichText(
// // // //       textAlign: TextAlign.center,
// // // //       text: const TextSpan(
// // // //         children: [
// // // //           TextSpan(
// // // //             text: 'Al continuar aceptas los ',
// // // //             style: TextStyle(
// // // //               fontSize: 12,
// // // //               color: Color(0xFF666666),
// // // //               fontWeight: FontWeight.w300,
// // // //             ),
// // // //           ),
// // // //           TextSpan(
// // // //             text: 'términos de uso',
// // // //             style: TextStyle(
// // // //               fontSize: 12,
// // // //               color: Color(0xFFFF6B35),
// // // //               fontWeight: FontWeight.w400,
// // // //               decoration: TextDecoration.underline,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // // Custom painter para el patrón de fondo
// // // // class CirclePatternPainter extends CustomPainter {
// // // //   @override
// // // //   void paint(Canvas canvas, Size size) {
// // // //     final paint = Paint()
// // // //       ..color = const Color(0xFFFF6B35).withOpacity(0.03)
// // // //       ..style = PaintingStyle.fill;

// // // //     // Círculos decorativos
// // // //     canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 60, paint);
// // // //     canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 40, paint);
// // // //     canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 80, paint);
// // // //     canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), 50, paint);
// // // //   }

// // // //   @override
// // // //   bool shouldRepaint(CustomPainter oldDelegate) => false;
// // // // }



























// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:logger/logger.dart';
// // // // // import 'package:zonix/features/services/auth/api_service.dart';
// // // // // import 'package:zonix/main.dart';
// // // // // import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// // // // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // // // // import 'package:zonix/features/utils/auth_utils.dart';
// // // // // import 'package:google_sign_in/google_sign_in.dart';
// // // // // import 'package:sign_in_button/sign_in_button.dart';
// // // // // import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';

// // // // // const FlutterSecureStorage _storage = FlutterSecureStorage();
// // // // // final ApiService apiService = ApiService();
// // // // // final logger = Logger();

// // // // // class SignInScreen extends StatefulWidget {
// // // // //   const SignInScreen({super.key});

// // // // //   @override
// // // // //   SignInScreenState createState() => SignInScreenState();
// // // // // }

// // // // // class SignInScreenState extends State<SignInScreen> {
// // // // //   final GoogleSignInService googleSignInService = GoogleSignInService();
// // // // //   bool isAuthenticated = false;
// // // // //   GoogleSignInAccount? _currentUser;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _checkAuthentication();
// // // // //   }

// // // // //   Future<void> _checkAuthentication() async {
// // // // //     isAuthenticated = await AuthUtils.isAuthenticated();
// // // // //     if (isAuthenticated) {
// // // // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // // // //       if (_currentUser != null) {
// // // // //         logger.i('Foto de usuario: ${_currentUser!.photoUrl}');
// // // // //         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
// // // // //         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
// // // // //         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
// // // // //       }
// // // // //     }
// // // // //     setState(() {});
// // // // //   }

// // // // //   Future<void> _handleSignIn() async {
// // // // //     try {
// // // // //       await GoogleSignInService.signInWithGoogle();
// // // // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // // // //       setState(() {});

// // // // //       if (_currentUser != null) {
// // // // //         await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
// // // // //         await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
// // // // //         await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

// // // // //         String? savedName = await _storage.read(key: 'userName');
// // // // //         String? savedEmail = await _storage.read(key: 'userEmail');
// // // // //         String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
// // // // //         String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

// // // // //         logger.i('Nombre guardado: $savedName');
// // // // //         logger.i('Correo guardado: $savedEmail');
// // // // //         logger.i('Foto guardada: $savedPhotoUrl');
// // // // //         logger.i('Onboarding guardada: $savedOnboardingString');

// // // // //         bool onboardingCompleted = savedOnboardingString == '1';
// // // // //         logger.i('Conversión de completedOnboarding: $onboardingCompleted');

// // // // //         if (!mounted) return;

// // // // //         if (!onboardingCompleted) {
// // // // //           Navigator.pushReplacement(
// // // // //             context,
// // // // //             MaterialPageRoute(builder: (context) => const OnboardingScreen()),
// // // // //           );
// // // // //         } else {
// // // // //           Navigator.pushReplacement(
// // // // //             context,
// // // // //             MaterialPageRoute(builder: (context) => const MainRouter()),
// // // // //           );
// // // // //         }
// // // // //       } else {
// // // // //         logger.i('Inicio de sesión cancelado o fallido');
// // // // //       }
// // // // //     } catch (e) {
// // // // //       logger.e('Error durante el manejo del inicio de sesión: $e');
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final screenHeight = MediaQuery.of(context).size.height;
// // // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // // //     final isSmallScreen = screenHeight < 700;
    
// // // // //     return Scaffold(
// // // // //       backgroundColor: const Color(0xFFFFF8F0), // Crema cálido - estimula apetito
// // // // //       body: SafeArea(
// // // // //         child: SingleChildScrollView(
// // // // //           child: ConstrainedBox(
// // // // //             constraints: BoxConstraints(
// // // // //               minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
// // // // //             ),
// // // // //             child: IntrinsicHeight(
// // // // //               child: Column(
// // // // //                 children: [
// // // // //                   // Header con logo mejorado
// // // // //                   _buildHeader(),
                  
// // // // //                   // Contenido principal
// // // // //                   Expanded(
// // // // //                     child: Padding(
// // // // //                       padding: EdgeInsets.symmetric(
// // // // //                         horizontal: screenWidth * 0.06,
// // // // //                         vertical: isSmallScreen ? 16 : 24,
// // // // //                       ),
// // // // //                       child: Column(
// // // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                         children: [
// // // // //                           // Saludo principal
// // // // //                           _buildWelcomeText(),
                          
// // // // //                           SizedBox(height: isSmallScreen ? 16 : 24),
                          
// // // // //                           // Descripción
// // // // //                           _buildDescriptionText(),
                          
// // // // //                           SizedBox(height: isSmallScreen ? 24 : 32),
                          
// // // // //                           // Imagen ilustrativa
// // // // //                           _buildIllustration(isSmallScreen),
                          
// // // // //                           const Spacer(),
                          
// // // // //                           // Botón de Google mejorado
// // // // //                           _buildGoogleSignInButton(),
                          
// // // // //                           SizedBox(height: isSmallScreen ? 16 : 24),
                          
// // // // //                           // Texto de términos
// // // // //                           _buildTermsText(),
                          
// // // // //                           SizedBox(height: isSmallScreen ? 16 : 24),
// // // // //                         ],
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildHeader() {
// // // // //     return Container(
// // // // //       width: double.infinity,
// // // // //       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
// // // // //       decoration: const BoxDecoration(
// // // // //         color: Color(0xFFFF6B35), // Naranja vibrante - estimula hambre
// // // // //         borderRadius: BorderRadius.only(
// // // // //           bottomLeft: Radius.circular(32),
// // // // //           bottomRight: Radius.circular(32),
// // // // //         ),
// // // // //       ),
// // // // //       child: Column(
// // // // //         children: [
// // // // //           // Logo principal
// // // // //           RichText(
// // // // //             text: const TextSpan(
// // // // //               children: [
// // // // //                 TextSpan(
// // // // //                   text: 'ZONI',
// // // // //                   style: TextStyle(
// // // // //                     fontFamily: 'system-ui',
// // // // //                     fontSize: 32,
// // // // //                     fontWeight: FontWeight.w800,
// // // // //                     color: Colors.white,
// // // // //                     letterSpacing: 2.0,
// // // // //                   ),
// // // // //                 ),
// // // // //                 TextSpan(
// // // // //                   text: 'X',
// // // // //                   style: TextStyle(
// // // // //                     fontFamily: 'system-ui',
// // // // //                     fontSize: 32,
// // // // //                     fontWeight: FontWeight.w800,
// // // // //                     color: Color(0xFFFFE135), // Amarillo dorado - hambre y energía
// // // // //                     letterSpacing: 2.0,
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //           const SizedBox(height: 8),
// // // // //           const Text(
// // // // //             'Tu comida favorita, en minutos',
// // // // //             style: TextStyle(
// // // // //               color: Colors.white,
// // // // //               fontSize: 14,
// // // // //               fontWeight: FontWeight.w500,
// // // // //               letterSpacing: 0.5,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildWelcomeText() {
// // // // //     return const Text(
// // // // //       '¡Hola! 👋',
// // // // //       style: TextStyle(
// // // // //         fontSize: 28,
// // // // //         fontWeight: FontWeight.w700,
// // // // //         color: Color(0xFF2D3436), // Gris oscuro para contraste
// // // // //         height: 1.2,
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildDescriptionText() {
// // // // //     return RichText(
// // // // //       text: const TextSpan(
// // // // //         children: [
// // // // //           TextSpan(
// // // // //             text: 'Inicia sesión para descubrir sabores increíbles en ',
// // // // //             style: TextStyle(
// // // // //               fontSize: 18,
// // // // //               color: Color(0xFF636E72), // Gris medio para legibilidad
// // // // //               fontWeight: FontWeight.w400,
// // // // //               height: 1.4,
// // // // //             ),
// // // // //           ),
// // // // //           TextSpan(
// // // // //             text: 'ZONI',
// // // // //             style: TextStyle(
// // // // //               fontSize: 18,
// // // // //               fontWeight: FontWeight.w700,
// // // // //               color: Color(0xFFFF6B35), // Naranja de marca
// // // // //               height: 1.4,
// // // // //             ),
// // // // //           ),
// // // // //           TextSpan(
// // // // //             text: 'X',
// // // // //             style: TextStyle(
// // // // //               fontSize: 18,
// // // // //               fontWeight: FontWeight.w700,
// // // // //               color: Color(0xFFFFE135), // Amarillo dorado
// // // // //               height: 1.4,
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildIllustration(bool isSmallScreen) {
// // // // //     return Center(
// // // // //       child: Container(
// // // // //         padding: const EdgeInsets.all(20),
// // // // //         decoration: BoxDecoration(
// // // // //           color: Colors.white,
// // // // //           borderRadius: BorderRadius.circular(24),
// // // // //           boxShadow: [
// // // // //             BoxShadow(
// // // // //               color: const Color(0xFFFF6B35).withOpacity(0.1),
// // // // //               blurRadius: 20,
// // // // //               offset: const Offset(0, 8),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //         child: Image.asset(
// // // // //           'assets/images/undraw_launching_szjw.png',
// // // // //           height: isSmallScreen ? 160 : 200,
// // // // //           fit: BoxFit.contain,
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildGoogleSignInButton() {
// // // // //     return Container(
// // // // //       width: double.infinity,
// // // // //       height: 56,
// // // // //       decoration: BoxDecoration(
// // // // //         color: Colors.white,
// // // // //         borderRadius: BorderRadius.circular(16),
// // // // //         border: Border.all(
// // // // //           color: const Color(0xFFE0E0E0),
// // // // //           width: 1,
// // // // //         ),
// // // // //         boxShadow: [
// // // // //           BoxShadow(
// // // // //             color: Colors.black.withOpacity(0.08),
// // // // //             blurRadius: 12,
// // // // //             offset: const Offset(0, 4),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       child: Material(
// // // // //         color: Colors.transparent,
// // // // //         child: InkWell(
// // // // //           onTap: _handleSignIn,
// // // // //           borderRadius: BorderRadius.circular(16),
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.symmetric(horizontal: 16),
// // // // //             child: Row(
// // // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // // //               children: [
// // // // //                 Image.asset(
// // // // //                   'assets/images/google_logo.png', // Asegúrate de tener el logo de Google
// // // // //                   height: 24,
// // // // //                   width: 24,
// // // // //                   errorBuilder: (context, error, stackTrace) {
// // // // //                     return const Icon(
// // // // //                       Icons.login,
// // // // //                       size: 24,
// // // // //                       color: Color(0xFF4285F4),
// // // // //                     );
// // // // //                   },
// // // // //                 ),
// // // // //                 const SizedBox(width: 12),
// // // // //                 const Text(
// // // // //                   'Continuar con Google',
// // // // //                   style: TextStyle(
// // // // //                     fontSize: 16,
// // // // //                     fontWeight: FontWeight.w600,
// // // // //                     color: Color(0xFF2D3436),
// // // // //                   ),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   Widget _buildTermsText() {
// // // // //     return Center(
// // // // //       child: RichText(
// // // // //         textAlign: TextAlign.center,
// // // // //         text: const TextSpan(
// // // // //           children: [
// // // // //             TextSpan(
// // // // //               text: 'Al continuar, aceptas nuestros ',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 12,
// // // // //                 color: Color(0xFF636E72),
// // // // //                 height: 1.4,
// // // // //               ),
// // // // //             ),
// // // // //             TextSpan(
// // // // //               text: 'Términos de Servicio',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 12,
// // // // //                 color: Color(0xFFFF6B35),
// // // // //                 fontWeight: FontWeight.w600,
// // // // //                 decoration: TextDecoration.underline,
// // // // //                 height: 1.4,
// // // // //               ),
// // // // //             ),
// // // // //             TextSpan(
// // // // //               text: ' y ',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 12,
// // // // //                 color: Color(0xFF636E72),
// // // // //                 height: 1.4,
// // // // //               ),
// // // // //             ),
// // // // //             TextSpan(
// // // // //               text: 'Política de Privacidad',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 12,
// // // // //                 color: Color(0xFFFF6B35),
// // // // //                 fontWeight: FontWeight.w600,
// // // // //                 decoration: TextDecoration.underline,
// // // // //                 height: 1.4,
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }







// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:logger/logger.dart';
// // // // // // import 'package:zonix/features/services/auth/api_service.dart';
// // // // // // import 'package:zonix/main.dart';
// // // // // // import 'package:zonix/features/services/auth/google_sign_in_service.dart';
// // // // // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // // // // // import 'package:zonix/features/utils/auth_utils.dart';
// // // // // // import 'package:google_sign_in/google_sign_in.dart';
// // // // // // import 'package:sign_in_button/sign_in_button.dart';
// // // // // // import 'package:zonix/features/screens/onboarding/onboarding_screen.dart';


// // // // // // const FlutterSecureStorage _storage = FlutterSecureStorage();
// // // // // // final ApiService apiService = ApiService();

// // // // // // // Configuración del logger
// // // // // // final logger = Logger();

// // // // // // class SignInScreen extends StatefulWidget {
// // // // // //   const SignInScreen({super.key});

// // // // // //   @override
// // // // // //   SignInScreenState createState() => SignInScreenState();
// // // // // // }

// // // // // // class SignInScreenState extends State<SignInScreen> {
// // // // // //   final GoogleSignInService googleSignInService = GoogleSignInService();
// // // // // //   bool isAuthenticated = false;
// // // // // //   GoogleSignInAccount? _currentUser;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _checkAuthentication();
// // // // // //   }

// // // // // //   Future<void> _checkAuthentication() async {
// // // // // //     isAuthenticated = await AuthUtils.isAuthenticated();
// // // // // //     if (isAuthenticated) {
// // // // // //       _currentUser = await GoogleSignInService.getCurrentUser();
// // // // // //       if (_currentUser != null) {
// // // // // //         logger.i('Foto de usuario: ${_currentUser!.photoUrl}'); // Verifica la URL aquí
// // // // // //         await _storage.write(key: 'userPhotoUrl', value: _currentUser!.photoUrl);
// // // // // //         logger.i('Nombre de usuario: ${_currentUser!.displayName}');
// // // // // //         await _storage.write(key: 'displayName', value: _currentUser!.displayName);
// // // // // //       }
// // // // // //     }
// // // // // //     setState(() {});
// // // // // //   }

// // // // // //   Future<void> _handleSignIn() async {
// // // // // //   try {
// // // // // //     await GoogleSignInService.signInWithGoogle();
// // // // // //     _currentUser = await GoogleSignInService.getCurrentUser();
// // // // // //     setState(() {});

// // // // // //     if (_currentUser != null) {
// // // // // //       await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
// // // // // //       await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
// // // // // //       await AuthUtils.saveUserPhotoUrl(_currentUser!.photoUrl ?? 'URL de foto no disponible');

    
// // // // // //       String? savedName = await _storage.read(key: 'userName');
// // // // // //       String? savedEmail = await _storage.read(key: 'userEmail');
// // // // // //       String? savedPhotoUrl = await _storage.read(key: 'userPhotoUrl');
// // // // // //       String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');

// // // // // //       logger.i('Nombre guardado: $savedName');
// // // // // //       logger.i('Correo guardado: $savedEmail');
// // // // // //       logger.i('Foto guardada: $savedPhotoUrl');
// // // // // //       logger.i('Onboarding guardada: $savedOnboardingString');

// // // // // //       // Conversión de savedOnboardingString a booleano
// // // // // //       bool onboardingCompleted = savedOnboardingString == '1';
// // // // // //       logger.i('Conversión de completedOnboarding: $onboardingCompleted');

// // // // // //       if (!mounted) return;

// // // // // //       // Navegación según el estado del onboarding
// // // // // //       if (!onboardingCompleted) {
// // // // // //         Navigator.pushReplacement(
// // // // // //           context,
// // // // // //           MaterialPageRoute(builder: (context) => const OnboardingScreen()),
// // // // // //         );
// // // // // //       } else {
// // // // // //         Navigator.pushReplacement(
// // // // // //           context,
// // // // // //           MaterialPageRoute(builder: (context) => const MainRouter()),
// // // // // //         );
// // // // // //       }
// // // // // //     } else {
// // // // // //       logger.i('Inicio de sesión cancelado o fallido');
// // // // // //     }
// // // // // //   } catch (e) {
// // // // // //     logger.e('Error durante el manejo del inicio de sesión: $e');
// // // // // //     // Manejo adicional de errores, como mostrar un mensaje al usuario
// // // // // //   }
// // // // // // }


// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         title: RichText(
// // // // // //           text: TextSpan(
// // // // // //             children: [
// // // // // //               TextSpan(
// // // // // //                 text: 'ZONI',
// // // // // //                 style: TextStyle(
// // // // // //                   fontFamily: 'system-ui',
// // // // // //                   fontSize: 21,
// // // // // //                   fontWeight: FontWeight.bold,
// // // // // //                   color: Theme.of(context).brightness == Brightness.dark
// // // // // //                       ? Colors.white
// // // // // //                       : Colors.black,
// // // // // //                   letterSpacing: 1.2,
// // // // // //                 ),
// // // // // //               ),
// // // // // //               TextSpan(
// // // // // //                 text: 'X',
// // // // // //                 style: TextStyle(
// // // // // //                   fontFamily: 'system-ui',
// // // // // //                   fontSize: 21,
// // // // // //                   fontWeight: FontWeight.bold,
// // // // // //                   color: Theme.of(context).brightness == Brightness.dark
// // // // // //                       ? Colors.blueAccent[700]
// // // // // //                       : Colors.orange,
// // // // // //                   letterSpacing: 1.2,
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //       body: Center(
// // // // // //         // child: _currentUser == null ? _buildSignInButton() : _buildUserInfo(),
// // // // // //         child: _buildSignInButton(),
// // // // // //       ),
// // // // // //     );
// // // // // //   }


// // // // // //   Widget _buildSignInButton() {
// // // // // //     return Column(
// // // // // //       crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // // //       children: [
// // // // // //         Container(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 20.0), // Margen izquierdo y derecho
// // // // // //           child: const Text(
// // // // // //             '¡Hola! Inicia sesión para continuar.',
// // // // // //             textAlign: TextAlign.left,
// // // // // //             style: TextStyle(fontSize: 20),
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 18),

// // // // // //         Container(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 20.0), // Margen izquierdo y derecho
// // // // // //           child: RichText(
// // // // // //             textAlign: TextAlign.left,
// // // // // //             text: TextSpan(
// // // // // //               children: [
// // // // // //                 TextSpan(
// // // // // //                   text: 'Usa tu cuenta de Gmail para acceder a ',
// // // // // //                   style: TextStyle(
// // // // // //                     fontSize: 24, // Tamaño del texto normal
// // // // // //                     color: Theme.of(context).brightness == Brightness.dark
// // // // // //                         ? Colors.white
// // // // // //                         : Colors.black, // Color adaptado al tema
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 TextSpan(
// // // // // //                   text: 'ZONI',
// // // // // //                   style: TextStyle(
// // // // // //                     fontFamily: 'system-ui',
// // // // // //                     fontSize: 24, // Tamaño de fuente diferente para 'ZONIX'
// // // // // //                     fontWeight: FontWeight.bold,
// // // // // //                     color: Theme.of(context).brightness == Brightness.dark
// // // // // //                         ? Colors.white
// // // // // //                         : Colors.black,
// // // // // //                     letterSpacing: 1.2,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 TextSpan(
// // // // // //                   text: 'X',
// // // // // //                   style: TextStyle(
// // // // // //                     fontFamily: 'system-ui',
// // // // // //                     fontSize: 24,
// // // // // //                     fontWeight: FontWeight.bold,
// // // // // //                     color: Theme.of(context).brightness == Brightness.dark
// // // // // //                         ? Colors.blueAccent[700]
// // // // // //                         : Colors.orange,
// // // // // //                     letterSpacing: 1.2,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),

// // // // // //         const SizedBox(height: 24),

// // // // // //         Container(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 20.0), // Margen izquierdo y derecho
// // // // // //           child: Image.asset(
// // // // // //             'assets/images/undraw_launching_szjw.png', // Ruta de la imagen local
// // // // // //             fit: BoxFit.cover,
// // // // // //           ),
// // // // // //         ),


      
// // // // // //         const Spacer(),

// // // // // //         Container(
// // // // // //           padding: const EdgeInsets.symmetric(horizontal: 20.0), // Margen izquierdo y derecho
// // // // // //           child: SignInButton(
// // // // // //             Buttons.google,
// // // // // //             text: 'Iniciar sesión con Google',
// // // // // //             shape: RoundedRectangleBorder(
// // // // // //               borderRadius: BorderRadius.circular(50),
// // // // // //             ),
// // // // // //             padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // //             onPressed: _handleSignIn,
// // // // // //           ),
// // // // // //         ),
// // // // // //         const SizedBox(height: 30),
// // // // // //       ],
// // // // // //     );
// // // // // //   }
// // // // // // }
