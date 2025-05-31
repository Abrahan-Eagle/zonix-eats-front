import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import 'onboarding_page4.dart';
import 'onboarding_page5.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'onboarding_service.dart';
import 'package:zonix/features/ScreenDashboard/users/users_dashboard.dart';

final OnboardingService _onboardingService = OnboardingService();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<Widget> get onboardingPages {
    return const [
      WelcomePage(),
      OnboardingPage1(),
      OnboardingPage2(),
      OnboardingPage3(),
      OnboardingPage4(),
      OnboardingPage5(),
    ];
  }

  Future<void> _completeOnboarding(int userId) async {
    try {
      await _onboardingService.completeOnboarding(userId);
      debugPrint("Onboarding completado con éxito.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UsersDashboard()),
      );
    } catch (e) {
      debugPrint("Error al completar el onboarding: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al completar el onboarding')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            // Contenido principal ocupando toda la pantalla
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: onboardingPages,
            ),
            // Navegación flotante posicionada absolutamente
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    // Botón "Saltar" o "Atrás"
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Atrás'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          final userId = userProvider.userId;
                          if (userId != null) {
                            await _completeOnboarding(userId);
                          }
                        },
                        child: const Text('Saltar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    
                    // Indicador de páginas
                    SmoothPageIndicator(
                      controller: _controller,
                      count: onboardingPages.length,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Theme.of(context).primaryColor,
                        dotColor: Colors.grey[300]!,
                      ),
                    ),
                    
                    // Botón "Siguiente" o "Finalizar" flotante
                    GestureDetector(
                      onTap: () async {
                        if (_currentPage == onboardingPages.length - 1) {
                          final userId = userProvider.userId;
                          if (userId != null) {
                            await _completeOnboarding(userId);
                          }
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentPage == onboardingPages.length - 1 
                            ? Icons.check 
                            : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/onboarding/welcome_image.svg', height: 200),
          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido a Zonix!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'La forma más rápida y segura de gestionar tus bombonas de gas. '
              'Aquí puedes gestionar tus citas de manera eficiente.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}