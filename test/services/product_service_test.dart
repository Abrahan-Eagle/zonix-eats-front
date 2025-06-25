import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/features/services/product_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('ProductService', () {
    test('fetchProducts returns a list', () async {
      final service = ProductService();
      final products = await service.fetchProducts();
      expect(products, isA<List>());
    });
  });
}
