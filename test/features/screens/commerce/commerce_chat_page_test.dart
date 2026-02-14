import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../../lib/features/screens/commerce/commerce_chat_page.dart';

void main() {
  testWidgets('CommerceChatPage construye y muestra estado inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommerceChatPage()));
    // Estado inicial: loading (CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
} 