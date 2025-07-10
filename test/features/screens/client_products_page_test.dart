import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/product_service.dart';

class MockProductService implements ProductService {
  @override
  final String apiUrl = 'http://test.com/api/products';

  @override
  Future<List<Product>> fetchProducts() async {
    return [
      Product(id: 1, nombre: 'Hamburguesa', disponible: true, precio: 50.0, descripcion: 'Rica hamburguesa', imagen: null),
      Product(id: 2, nombre: 'Pizza', disponible: true, precio: 80.0, descripcion: 'Pizza grande', imagen: null),
    ];
  }

  @override
  Future<Product?> fetchProduct(int id) async {
    return Product(id: id, nombre: 'Test Product', disponible: true, precio: 50.0, descripcion: 'Test', imagen: null);
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    return [];
  }
}

void main() {
  testWidgets('Cliente puede ver productos y no ve acciones de comercio/delivery', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartService>(create: (_) => CartService()),
        ],
        child: MaterialApp(
          home: ProductsPage(productService: MockProductService()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hamburguesa'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    // No debe haber botones de gestión de productos (solo para comercio)
    expect(find.text('Agregar producto'), findsNothing);
    // No debe haber acciones de delivery
    expect(find.text('Órdenes asignadas'), findsNothing);
  });
} 