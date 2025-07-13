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

  // GET /api/buyer/products - Listar productos
  Future<List<Product>> fetchProducts() async {
    final headers = await AuthHelper.getAuthHeaders();
    _logger.i('Llamando a $apiUrl');
    
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );
    
    _logger.i('Status code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _logger.i('Decoded data type: ${data.runtimeType}');
      
      // Handle the new API response structure with success and data wrapper
      List<dynamic> productsData;
      if (data['success'] == true && data['data'] != null) {
        productsData = data['data'];
      } else {
        // Fallback to direct data if not wrapped
        productsData = data is List ? data : [];
      }
      
      if (productsData.isNotEmpty) {
        _logger.i('Cantidad de productos recibidos: ${productsData.length}');
        return productsData.map((item) => Product.fromJson(item)).toList();
      } else {
        _logger.w('La respuesta no contiene productos');
        return [];
      }
    } else {
      _logger.e('Error al cargar productos: ${response.statusCode}');
      throw Exception('Error al cargar productos: ${response.statusCode}');
    }
  }

  // GET /api/buyer/products/{id} - Obtener producto por ID
  Future<Product> getProductById(int productId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = '$apiUrl/$productId';
    _logger.i('Llamando a $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    
    _logger.i('Status code: ${response.statusCode}');
    _logger.i('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _logger.i('Decoded data type: ${data.runtimeType}');
      _logger.i('Decoded data: $data');
      
      // Handle different response structures
      Map<String, dynamic> productData;
      
      if (data is Map<String, dynamic>) {
        // Check if it's wrapped in success/data structure
        if (data['success'] == true && data['data'] != null) {
          productData = data['data'];
        } else {
          // Direct product object
          productData = data;
        }
      } else if (data is List && data.isNotEmpty) {
        // If backend returns an array, take the first item
        _logger.w('Backend returned array instead of object, taking first item');
        productData = data[0];
      } else {
        throw Exception('Invalid response format from backend');
      }
      
      _logger.i('Final product data: $productData');
      return Product.fromJson(productData);
    } else {
      _logger.e('Error al cargar producto: ${response.statusCode}');
      _logger.e('Error response body: ${response.body}');
      throw Exception('Error al cargar producto: ${response.statusCode}');
    }
  }
}
