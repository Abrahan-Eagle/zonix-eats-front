import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/cart_page.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/features/services/cart_service.dart';

void main() {
  testWidgets('CartPage muestra mensaje si el carrito está vacío', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<CartService>(
          create: (_) => CartService(),
          child: const CartPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('El carrito está vacío'), findsOneWidget);
  });
}
