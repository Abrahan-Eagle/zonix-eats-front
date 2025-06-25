import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lib/features/screens/checkout_page.dart';
import '../../lib/features/services/cart_service.dart';

void main() {
  testWidgets('CheckoutPage muestra resumen de compra', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartService(),
        child: const MaterialApp(home: CheckoutPage()),
      ),
    );
    expect(find.text('Resumen de compra'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
