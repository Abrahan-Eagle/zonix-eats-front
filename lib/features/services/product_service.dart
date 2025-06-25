import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import '../../models/product.dart';
import '../../helpers/auth_helper.dart';

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
final Logger _logger = Logger();

class ProductService {
  final String apiUrl = '$baseUrl/api/buyer/products';

  Future<List<Product>> fetchProducts() async {
    final headers = await AuthHelper.getAuthHeaders();
    _logger.i('Llamando a $apiUrl con headers:');
    _logger.i(headers);
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );
    _logger.i('Status code: \\${response.statusCode}');
    _logger.i('Response body: \\${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _logger.i('Decoded data: \\${data.runtimeType}');
      if (data is List) {
        _logger.i('Cantidad de productos recibidos: \\${data.length}');
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        _logger.w('La respuesta no es una lista');
        return [];
      }
    } else {
      _logger.e('Error al cargar productos: \\${response.statusCode}');
      throw Exception('Error al cargar productos');
    }
  }
}
