import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page2x.dart';
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
      OnboardingPage2x(),
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
        body: PageView(
          controller: _controller,
          // onPageChanged: (index) {
          //   // Si el usuario intenta deslizarse más allá de OnboardingPage2 y no tiene un perfil creado, se lo regresa.
          //   if (index > 2 && !userProvider.profileCreated) {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Por favor, crea tu perfil antes de continuar.'),
          //       ),
          //     );
          //     _controller.jumpToPage(2); // Regresa al usuario a la página 2
          //   } else {
          //     setState(() {
          //       _currentPage = index;
          //     });
          //   }
          // },
          onPageChanged: (index) {
            if (index > 2 && !userProvider.profileCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, crea tu perfil antes de continuar.'),
                ),
              );
              _controller.jumpToPage(2);
            } else {
              setState(() {
                _currentPage = index;
              });
            }
          },

          children: onboardingPages,
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 80.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SmoothPageIndicator(
                controller: _controller,
                count: onboardingPages.length,
                effect: const WormEffect(),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Bloqueo del avance en OnboardingPage2 si el perfil no está creado
                  if (_currentPage == 2 && !userProvider.profileCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, crea tu perfil antes de continuar.'),
                      ),
                    );
                    return;
                  }

                  if (_currentPage == onboardingPages.length - 1) {
                    // Completar el onboarding si estamos en la última página
                    final userId = userProvider.userId;
                    if (userId != null) {
                      await _completeOnboarding(userId);
                    }
                  } else {
                    // Avanzar a la siguiente página
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  }
                },
                child: Text(
                  _currentPage == onboardingPages.length - 1 ? 'Finalizar' : 'Siguiente',
                ),
              ),
            ],
          ),
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
