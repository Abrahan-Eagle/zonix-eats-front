import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/utils/search_radius_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockLocationService extends LocationService {
  @override
  Future<Map<String, dynamic>> getCurrentLocation() async => {
        'latitude': -12.0,
        'longitude': -77.0,
        'address': 'Test',
      };
  @override
  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    String? type,
  }) async => [
        {'id': 1, 'name': 'Test Commerce', 'distance': 1.0},
      ];
}

class MockProductService implements ProductService {
  @override
  final String apiUrl = 'http://test.com/api/products';

  @override
  Future<List<Product>> fetchProducts({int? categoryId}) async {
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
  
  testWidgets('Cliente puede ver productos y no ve acciones de comercio/delivery', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartService>(create: (_) => CartService()),
          ChangeNotifierProvider<LocationService>(create: (_) => MockLocationService()),
          ChangeNotifierProvider<SearchRadiusProvider>(create: (_) => SearchRadiusProvider()),
        ],
        child: MaterialApp(
          home: ProductsPage(productService: MockProductService()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Hamburguesa'), findsAtLeastNWidgets(1));
    expect(find.text('Pizza'), findsAtLeastNWidgets(1));
    // No debe haber botones de gestión de productos (solo para comercio)
    expect(find.text('Agregar producto'), findsNothing);
    // No debe haber acciones de delivery
    expect(find.text('Órdenes asignadas'), findsNothing);
  });
} 