import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../../lib/features/screens/commerce/commerce_notifications_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  testWidgets('CommerceNotificationsPage muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommerceNotificationsPage()));
    expect(find.text('Notificaciones'), findsOneWidget);
  });
} 