import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix/features/screens/onboarding/onboarding_page3.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';

void main() {
  setUpAll(() async {
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });

  testWidgets('Seleccionar rol Cliente actualiza OnboardingProvider', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<OnboardingProvider>(
        create: (_) => OnboardingProvider(),
        child: const MaterialApp(
          home: OnboardingPage3(),
        ),
      ),
    );

    // Tocar la tarjeta de "Cliente"
    final clienteTextFinder = find.text('Cliente');
    expect(clienteTextFinder, findsOneWidget);
    await tester.tap(clienteTextFinder);
    await tester.pump();

    // Verificar que el provider global tiene el rol 'users'
    final context = tester.element(find.byType(OnboardingPage3));
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    expect(onboardingProvider.selectedRole, equals('users'));
  });
}


