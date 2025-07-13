import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
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

    // Verificar que la página se carga correctamente
    expect(find.byType(ProductsPage), findsOneWidget);
    
    // Verificar que hay elementos de UI básicos
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Verificar que la página no falla al inicializarse
    expect(tester.takeException(), isNull);
  });
}
