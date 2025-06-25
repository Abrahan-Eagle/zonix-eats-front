import 'package:flutter_test/flutter_test.dart';
import 'package:zonix_eats_front/lib/features/services/product_service.dart';

void main() {
  group('ProductService', () {
    test('fetchProducts returns a list', () async {
      final service = ProductService();
      final products = await service.fetchProducts();
      expect(products, isA<List>());
    });
  });
}
