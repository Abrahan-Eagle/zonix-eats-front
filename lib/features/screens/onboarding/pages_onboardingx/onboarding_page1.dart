import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.indigo,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               SvgPicture.asset(
                'assets/onboarding/undraw_outer_space_re_u9vd.svg',
                height: 200.0, // Ajusta la altura según sea necesario
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido a Zonix',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Descubre la manera más rápida, confiable y conveniente de gestionar el suministro de gas a tu hogar. Con Zonix, puedes reservar citas, verificar la disponibilidad, y mantener un control completo sobre tus bombonas desde cualquier lugar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ahorra tiempo y evita contratiempos. Zonix garantiza una entrega segura y eficiente, con notificaciones en tiempo real y soporte dedicado para que nunca te falte el gas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
