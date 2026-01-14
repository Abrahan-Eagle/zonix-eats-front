import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/main.dart';
import 'package:zonix/features/services/auth/google_sign_in_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String? _loginError;

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
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleSignIn() async {
    try {
      await GoogleSignInService.signInWithGoogle();
      _currentUser = await GoogleSignInService.getCurrentUser();
      setState(() {
        _loginError = null;
      });

      if (_currentUser != null) {
        await AuthUtils.saveUserName(_currentUser!.displayName ?? 'Nombre no disponible');
        await AuthUtils.saveUserEmail(_currentUser!.email ?? 'Email no disponible');
        // Solo guardar photoUrl si es válida, de lo contrario guardar cadena vacía
        final photoUrl = _currentUser!.photoUrl;
        await AuthUtils.saveUserPhotoUrl(photoUrl?.isNotEmpty == true ? photoUrl : '');

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
        if (!mounted) return;
        setState(() {
          _loginError = 'Inicio de sesión cancelado o fallido';
        });
      }
    } catch (e) {
      logger.e('Error durante el manejo del inicio de sesión: $e');
      if (!mounted) return;
      setState(() {
        _loginError = 'Error durante el inicio de sesión';
      });
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
                        
                        if (_loginError != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _loginError!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        
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
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      
      
      Transform.translate(
  offset: const Offset(0, -25), // Ajusta este valor
  child: Text(
    TimeOfDay.now().format(context),
    style: TextStyle(
      color: Colors.white,
      fontSize: isSmallScreen ? 14 : 16,
      fontWeight: FontWeight.w500,
    ),
  ),
),
      
      Transform.translate(
        offset: const Offset(0, -25),
        child: Image.asset(
          'assets/images/logo_login.png',
          width: isSmallScreen ? 90 : 90,
          height: isSmallScreen ? 90 : 90,
          fit: BoxFit.contain,
        ),
      ),
    ],
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
    // decoration: BoxDecoration(
    //   shape: BoxShape.circle,
    //   color: const Color(0xFFFF6B35),
    //   boxShadow: [
    //     BoxShadow(
    //       color: const Color(0xFFFF6B35).withOpacity(0.4),
    //       blurRadius: 40,
    //       spreadRadius: 10,
    //     ),
    //   ],
    // ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo principal (ajustado para evitar overflow)
        Flexible(
          child: Image.asset(
            'assets/images/logo_login2.png',
            width: isSmallScreen ? 400 : 500,
            height: isSmallScreen ? 146 : 183,
            fit: BoxFit.contain,
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
          height: isSmallScreen ? 52 : 60,
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
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/google_logo.png',
                        height: isSmallScreen ? 24 : 28,
                        width: isSmallScreen ? 24 : 28,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.login,
                            size: isSmallScreen ? 24 : 28,
                            color: const Color(0xFF4285F4),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
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