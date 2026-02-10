import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/features/screens/onboarding/client_onboarding_flow.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';
import 'package:zonix/features/utils/user_provider.dart';

void main() {
  setUpAll(() async {
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });

  testWidgets('ClientOnboardingFlow construye y muestra el paso de datos personales', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => OnboardingProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MaterialApp(
          home: ClientOnboardingFlow(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Debe mostrar el primer paso (datos personales): al menos un campo de nombre o botón de continuar
    expect(find.byType(Form), findsWidgets);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('OnboardingProvider y UserProvider permiten construir ClientOnboardingFlow', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => OnboardingProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MaterialApp(
          home: ClientOnboardingFlow(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // Debe existir el botón de continuar del paso 0
    expect(find.text('Continuar'), findsOneWidget);
  });
}
