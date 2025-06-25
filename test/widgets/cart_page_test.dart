import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lib/features/screens/cart_page.dart';
import '../../lib/features/services/cart_service.dart';

void main() {
  testWidgets('CartPage muestra mensaje si el carrito está vacío', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartService(),
        child: const MaterialApp(home: CartPage()),
      ),
    );
    expect(find.text('El carrito está vacío'), findsOneWidget);
  });
}
