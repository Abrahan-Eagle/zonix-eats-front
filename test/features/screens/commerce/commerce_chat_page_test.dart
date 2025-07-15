import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../../lib/features/screens/commerce/commerce_chat_page.dart';

void main() {
  testWidgets('CommerceChatPage muestra mensajes y campo de texto', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommerceChatPage()));
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Hola, ¿está disponible la pizza familiar?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
} 