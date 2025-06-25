import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../lib/features/services/product_service.dart';
import '../../lib/models/product.dart';

class ProductServiceMock extends ProductService {
  @override
  Future<List<Product>> fetchProducts() async {
    // Sobrescribe el método para usar headers fijos
    final headers = {'Content-Type': 'application/json'};
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Error al cargar productos');
    }
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('ProductService', () {
    test('fetchProducts returns a list', () async {
      final service = ProductServiceMock();
      try {
        final products = await service.fetchProducts();
        expect(products, isA<List>());
        if (products.isNotEmpty) {
          expect(products.first, isNotNull);
          expect(products.first.nombre, isNotEmpty);
        }
      } catch (e) {
        fail('Error al obtener productos: $e');
      }
    });
  });
}
