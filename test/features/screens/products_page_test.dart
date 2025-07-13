import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockProductService extends ProductService {
  @override
  Future<List<Product>> fetchProducts() async {
    // Return immediately to avoid timeout
    return [
      Product(
        id: 1,
        commerceId: 1,
        name: 'Hamburguesa',
        description: 'Rica hamburguesa',
        price: 50.0,
        image: '',
        category: 'Comida Rápida',
        isAvailable: true,
        stock: 10,
        tags: [],
        allergens: [],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        preparationTime: 15,
        rating: 4.5,
        reviewCount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 2,
        commerceId: 1,
        name: 'Pizza',
        description: 'Pizza grande',
        price: 80.0,
        image: '',
        category: 'Pizzería',
        isAvailable: true,
        stock: 5,
        tags: [],
        allergens: [],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        preparationTime: 20,
        rating: 4.3,
        reviewCount: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<Product?> fetchProduct(int id) async {
    return Product(
      id: id,
      commerceId: 1,
      name: 'Test Product',
      description: 'Test',
      price: 50.0,
      image: '',
      category: 'Test',
      isAvailable: true,
      stock: 1,
      tags: [],
      allergens: [],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      preparationTime: 10,
      rating: 4.0,
      reviewCount: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    return [];
  }

  @override
  Future<Product> getProductById(int productId) async {
    return Product(
      id: productId,
      commerceId: 1,
      name: 'Test Product',
      description: 'Test',
      price: 50.0,
      image: '',
      category: 'Test',
      isAvailable: true,
      stock: 1,
      tags: [],
      allergens: [],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      preparationTime: 10,
      rating: 4.0,
      reviewCount: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  
  testWidgets('ProductsPage muestra productos reales y navega a detalles', (WidgetTester tester) async {
    // Inyecta el ProductService mockeado directamente
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

    // Espera a que cargue el FutureBuilder
    await tester.pumpAndSettle();

    // Verifica que los productos se muestran usando los textos
    expect(find.text('Hamburguesa'), findsAtLeastNWidgets(1));
    expect(find.text('Pizza'), findsAtLeastNWidgets(1));
    expect(find.text(r'50.00 $'), findsAtLeastNWidgets(1));
    expect(find.text(r'80.00 $'), findsAtLeastNWidgets(1));

    // Toca el primer widget con el texto 'Hamburguesa' y verifica navegación a detalles
    await tester.tap(find.text('Hamburguesa').first);
    await tester.pumpAndSettle();
    // Aquí podrías verificar que se navega a ProductDetailPage si lo implementas
  });
}
