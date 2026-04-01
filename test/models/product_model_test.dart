import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/models/product.dart';

void main() {
  group('Product model stock semantics', () {
    test('stock_quantity null means unlimited stock', () {
      final product = Product.fromJson({
        'id': 1,
        'commerce_id': 10,
        'name': 'Pizza',
        'description': 'Demo',
        'price': 9.99,
        'available': true,
        'stock_quantity': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(product.isAvailable, true);
      expect(product.hasStockLimit, false);
      expect(product.stock, 0);
    });

    test('stock_quantity numeric means stock-limited', () {
      final product = Product.fromJson({
        'id': 1,
        'commerce_id': 10,
        'name': 'Pizza',
        'description': 'Demo',
        'price': 9.99,
        'available': true,
        'stock_quantity': 3,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(product.hasStockLimit, true);
      expect(product.stock, 3);
    });
  });

  group('Product model commerce id parsing', () {
    test('uses nested commerce.id when commerce_id is absent', () {
      final product = Product.fromJson({
        'id': 2,
        'commerce': {'id': 25, 'name': 'Demo Commerce'},
        'name': 'Hamburguesa',
        'description': 'Demo',
        'price': 12.5,
        'available': true,
        'stock_quantity': 5,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(product.commerceId, 25);
    });

    test('uses image_url and category_name aliases when present', () {
      final product = Product.fromJson({
        'id': 3,
        'commerce_id': 10,
        'name': 'Arepa',
        'description': 'Demo',
        'price': 4.5,
        'is_available': true,
        'stock_quantity': 7,
        'image_url': 'https://cdn.example.com/arepa.jpg',
        'category_name': 'Desayunos',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(product.image, 'https://cdn.example.com/arepa.jpg');
      expect(product.category, 'Desayunos');
    });
  });
}

