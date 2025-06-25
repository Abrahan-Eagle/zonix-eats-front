import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../helpers/auth_helper.dart';
import '../../models/restaurant.dart';

class RestaurantService {
  final String baseUrl;

  RestaurantService([String? baseUrl])
      : baseUrl = baseUrl ?? (dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000');

  Future<List<Restaurant>> fetchRestaurants() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/buyer/restaurants'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((item) => Restaurant.fromJson(item)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Error al cargar restaurantes');
    }
  }
}
