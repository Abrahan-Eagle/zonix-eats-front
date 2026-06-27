import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:zonix_glasses/features/screens/onboarding/onboarding_page3.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

void main() {
  setUpAll(() async {
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });

  testWidgets('OnboardingPage3 muestra CTA de entrada', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<UserProvider>(
        create: (_) => UserProvider()..setAuthenticatedForTest(role: 'user'),
        child: const MaterialApp(
          home: OnboardingPage3(),
        ),
      ),
    );

    expect(find.text('Entrar a la app'), findsOneWidget);
    expect(find.text('¡Listo para empezar!'), findsOneWidget);
  });
}
