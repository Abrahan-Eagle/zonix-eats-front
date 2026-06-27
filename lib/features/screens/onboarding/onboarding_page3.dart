import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/app/main_router.dart';
import 'package:zonix_glasses/features/screens/onboarding/onboarding_service.dart';
import 'package:zonix_glasses/features/utils/app_colors.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

/// Último paso del onboarding genérico del scaffold.
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: AppColors.blue),
          const SizedBox(height: 16),
          Text(
            '¡Listo para empezar!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa tu perfil y dirección desde Ajustes cuando quieras.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final userId = context.read<UserProvider>().userId;
                try {
                  await OnboardingService().completeOnboarding(userId, role: 'user');
                } catch (_) {
                  // Offline o endpoint no disponible: marcar localmente.
                }
                if (!context.mounted) return;
                context.read<UserProvider>().setCompletedOnboarding(true);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainRouter()),
                  (_) => false,
                );
              },
              child: const Text('Entrar a la app'),
            ),
          ),
        ],
      ),
    );
  }
}
