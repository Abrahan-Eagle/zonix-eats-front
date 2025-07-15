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
    await tester.pumpWidget(const MaterialApp(home: CommerceProfilePage()));
    expect(find.text('Perfil de Comercio'), findsOneWidget);
  });

  testWidgets('Muestra el switch de apertura/cierre', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    await tester.pump();
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.textContaining('Comercio ABIERTO').evaluate().isNotEmpty || find.textContaining('Comercio CERRADO').evaluate().isNotEmpty, true);
  });

  testWidgets('Permite cambiar el estado de apertura/cierre', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    expect(find.text('Comercio ABIERTO'), findsOneWidget);
    // Cambiar el switch
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    // Imprimir todos los textos para debug
    final allTexts = find.byType(Text);
    for (var i = 0; i < tester.widgetList(allTexts).length; i++) {
      final textWidget = tester.widgetList(allTexts).elementAt(i) as Text;
      print('Texto encontrado: \'${textWidget.data}\'');
    }
    expect(find.text('Comercio CERRADO'), findsOneWidget);
  });

  testWidgets('Muestra feedback al guardar cambios (simulado)', (WidgetTester tester) async {
    final profile = CommerceProfile(id: 1, businessName: 'Test', address: 'A', phone: '1', open: true);
    await tester.pumpWidget(MaterialApp(home: CommerceProfilePage(initialProfile: profile, isTestMode: true)));
    await tester.pump();
    final saveButton = find.widgetWithText(ElevatedButton, 'Guardar cambios');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 20));
    // Esperar SnackBar
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SnackBar), findsOneWidget);
  });
} 