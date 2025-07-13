import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/cart/checkout_page.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
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
    // El texto exacto que muestra CheckoutPage
    expect(find.text('Resumen de compra'), findsOneWidget);
  });
}
