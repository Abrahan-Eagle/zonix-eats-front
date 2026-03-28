import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '');
    }
  });
  
  testWidgets('ProductsPage se inicializa correctamente', (WidgetTester tester) async {
    // Usar ProductService real para conectar con el backend
    final productService = ProductService();
    
    await tester.pumpWidget(
      ChangeNotifierProvider<CartService>(
        create: (_) => CartService(),
        child: MaterialApp(
          home: ProductsPage(productService: productService),
        ),
      ),
    );

    // Advance past the 3s promo delay to avoid pending timer assertion
    await tester.pump(const Duration(seconds: 4));

    expect(find.byType(ProductsPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
