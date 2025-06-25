import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

class ProductService {
  final String apiUrl = '$baseUrl/api/buyer/products';
  final storage = const FlutterSecureStorage(); // Instancia de almacenamiento seguro

  // Método para recuperar el token almacenado
  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<List<dynamic>> fetchProducts() async {
    String? token = await _getToken();


    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Error al cargar productos');
    }
  }
}
