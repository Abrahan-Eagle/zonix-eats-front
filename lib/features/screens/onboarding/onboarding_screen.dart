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
import 'package:zonix/main.dart';

final OnboardingService _onboardingService = OnboardingService();

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
      OnboardingPage1(),
      OnboardingPage2(),
      OnboardingPage3(),
      OnboardingPage4(),
      OnboardingPage5(),
    ];
  }

  Future<void> _completeOnboarding(int userId) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _onboardingService.completeOnboarding(userId);
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainRouter()),
      );
    } catch (e) {
      debugPrint("Error al completar el onboarding: $e");
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
          content:  Text('Error al completar el onboarding'),
          behavior: SnackBarBehavior.floating,
          margin:  EdgeInsets.all(20),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNext() {
    if (_isLoading) return;
    
    if (_currentPage == onboardingPages.length - 1) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId != null) {
        _completeOnboarding(userId);
      }
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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
                          activeDotColor: theme.primaryColor,
                          dotColor: theme.dividerColor,
                          spacing: 8,
                          expansionFactor: 3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botones de navegación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón Atrás/Saltar
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: _handleBack,
                              child: const Text('Atrás'),
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
                            ),

                          // Botón Siguiente/Finalizar
                          FloatingActionButton(
                            onPressed: _handleNext,
                            backgroundColor: theme.primaryColor,
                            elevation: 2,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : Icon(
                                    _currentPage == onboardingPages.length - 1
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                          ),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/onboarding/welcome_image.svg',
            height: 200,
          ),
          const SizedBox(height: 32),
          Text(
            '¡Bienvenido a Zonix!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'La forma más rápida y segura de gestionar tus bombonas de gas. '
            'Aquí puedes gestionar tus citas de manera eficiente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}