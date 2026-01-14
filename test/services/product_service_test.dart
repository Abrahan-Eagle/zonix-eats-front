import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:zonix/models/product.dart';

class ProductServiceMock extends ProductService {
  @override
  Future<List<Product>> fetchProducts({int? categoryId}) async {
    // Mock de respuesta exitosa
    final mockClient = MockClient((request) async {
      return http.Response('[{"id":1,"name":"Mocked Product","is_available":true,"price":10.0,"description":"desc","image":"img.jpg","category":"cat","stock":5,"tags":[],"allergens":[],"is_vegetarian":false,"is_vegan":false,"is_gluten_free":false,"preparation_time":10,"rating":4.5,"review_count":2,"created_at":"2024-01-01T00:00:00.000Z","updated_at":"2024-01-01T00:00:00.000Z"}]', 200);
    });
    final headers = {'Content-Type': 'application/json'};
    final response = await mockClient.get(
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
          expect(products.first.name, isNotEmpty);
        }
      } catch (e) {
        fail('Error al obtener productos: $e');
      }
    });
  });
}
