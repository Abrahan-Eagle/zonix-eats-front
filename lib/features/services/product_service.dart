import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product.dart';
import '../../helpers/auth_helper.dart';

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

class ProductService {
  final String apiUrl = '$baseUrl/api/buyer/products';

  Future<List<Product>> fetchProducts() async {
    final headers = await AuthHelper.getAuthHeaders();
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
