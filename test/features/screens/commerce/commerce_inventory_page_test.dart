import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../lib/features/screens/commerce/commerce_inventory_page.dart';
import '../../../../lib/services/commerce_profile_service.dart';
import '../../../../lib/models/commerce_profile.dart';

// Quitar mockito y test de mock, agregar test funcional simple
void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  testWidgets('CommerceInventoryPage muestra botón de agregar producto', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommerceInventoryPage()));
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
} 