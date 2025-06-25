import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RestaurantService {
  final String baseUrl;
  final storage = const FlutterSecureStorage();

  RestaurantService([String? baseUrl])
      : baseUrl = baseUrl ?? (dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000');

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<List<dynamic>> fetchRestaurants() async {
    String? token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/buyer/restaurants'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Error al cargar restaurantes');
    }
  }
}
