import 'dart:convert';

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

  group('Add-commerce payload (schedule como string)', () {
    test('schedule se envía como string cuando es un Map (mismo criterio que el flujo)', () {
      // Mismo tipo que _commerceSchedule en ClientOnboardingFlow
      final Map<String, Map<String, String>> commerceSchedule = {
        'Lunes': {'open': '09:00', 'close': '18:00'},
        'Martes': {'open': '09:00', 'close': '18:00'},
      };
      final scheduleValue = commerceSchedule.isEmpty ? '' : jsonEncode(commerceSchedule);
      expect(scheduleValue, isA<String>());
      expect(scheduleValue, isNotEmpty);
      expect(() => jsonDecode(scheduleValue), returnsNormally);
    });

    test('schedule se envía como string vacío cuando el Map está vacío', () {
      final Map<String, Map<String, String>> commerceSchedule = {};
      final scheduleValue = commerceSchedule.isEmpty ? '' : jsonEncode(commerceSchedule);
      expect(scheduleValue, isA<String>());
      expect(scheduleValue, isEmpty);
    });
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

    // No usar pumpAndSettle: el widget dispara llamadas de red (fetchOperatorCodes, etc.)
    // que no completan en test. Con pump() alcanza para que se dibuje el paso inicial.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

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

    // No usar pumpAndSettle: el widget hace llamadas de red que no completan en test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Debe existir el botón de continuar del paso 0
    expect(find.text('Continuar'), findsOneWidget);
  });
}
