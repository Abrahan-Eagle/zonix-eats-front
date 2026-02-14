import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../lib/features/screens/commerce/commerce_profile_page.dart';
import '../../../../lib/models/commerce_profile.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  testWidgets('CommerceProfilePage muestra el título', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    await tester.pump();
    expect(find.text('Perfil comercio'), findsOneWidget);
  });

  testWidgets('Muestra el switch de apertura/cierre', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    await tester.pump();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.textContaining('Comercio abierto').evaluate().isNotEmpty || find.textContaining('Comercio cerrado').evaluate().isNotEmpty, true);
  });

  testWidgets('Permite cambiar el estado de apertura/cierre', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    await tester.pump();
    expect(find.text('Comercio abierto'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Comercio cerrado'), findsOneWidget);
  });

  testWidgets('Muestra datos del comercio en modo test', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommerceProfilePage(initialProfile: profile, isTestMode: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Perfil comercio'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });
} 