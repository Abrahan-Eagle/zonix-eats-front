import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/features/services/cart_service.dart';

void main() {
  testWidgets('CheckoutPage muestra resumen de compra', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<CartService>(
          create: (_) => CartService(),
          child: CheckoutPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resumen de compra'), findsOneWidget);
  });
}
