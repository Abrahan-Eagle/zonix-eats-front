import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

// Colores del template Stitch (basados en logo)
const Color _kBackgroundDark = Color(0xFF1A2E46);
const Color _kPrimary = Color(0xFF3399FF);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final GoogleSignInService googleSignInService = GoogleSignInService();
  bool isAuthenticated = false;
  GoogleSignInAccount? _currentUser;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
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
    } catch (e) {
      logger.w('Error al verificar autenticación: $e');
      isAuthenticated = false;
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
        final user = _currentUser!;
        await AuthUtils.saveUserName(user.displayName ?? '');
        await AuthUtils.saveUserEmail(user.email);
        final photoUrl = user.photoUrl;
        await AuthUtils.saveUserPhotoUrl(photoUrl?.isNotEmpty == true ? photoUrl : '');

        String? savedOnboardingString = await _storage.read(key: 'userCompletedOnboarding');
        bool onboardingCompleted = savedOnboardingString == '1';

        if (!mounted) return;

        if (!onboardingCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainRouter()),
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
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildLogoAndTitle(),
                      const SizedBox(height: 32),
                      _buildBottomContent(),
                      const SizedBox(height: 40),
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

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: _kBackgroundDark,
      ),
      child: Stack(
        children: [
          // Gradiente espacial (como space-gradient del HTML)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.2,
                  colors: [
                    _kPrimary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 1.2,
                  colors: [
                    _kPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          // Círculo decorativo inferior izquierdo (balance visual con el planeta)
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // Círculo con logo del planeta (esquina superior derecha)
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.2),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo_login.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Patrón de estrellas: dispersas, tamaños variables (como screen.png)
          ...List.generate(60, (i) {
            final positions = [
              20.0, 35.0, 55.0, 75.0, 100.0, 130.0, 155.0, 180.0, 205.0, 230.0,
              260.0, 290.0, 320.0, 350.0, 380.0, 15.0, 45.0, 85.0, 120.0, 165.0,
            ];
            final x = (positions[i % 10] + (i ~/ 10) * 180) % 420;
            final y = (positions[(i + 5) % 10] + (i ~/ 10) * 220) % 850;
            final size = (i % 5 == 2) ? 2.0 : 1.0;
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: 0.25 + (i % 3) * 0.05,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoAndTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/dart_dark-android.png',
          height: 92,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pide comida a velocidad de la luz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF93C5FD).withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loginError != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _loginError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        // Botón Continuar con Google (pill-shaped)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: _handleSignIn,
              borderRadius: BorderRadius.circular(28),
              splashColor: _kPrimary.withOpacity(0.15),
              highlightColor: _kPrimary.withOpacity(0.08),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Continuar con Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Al continuar, aceptas nuestros Términos y Condiciones y Política de Privacidad.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF93C5FD).withOpacity(0.55),
            height: 1.5,
          ),
        ),
      ],
    );
  }

}
