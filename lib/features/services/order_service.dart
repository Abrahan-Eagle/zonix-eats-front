import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OrderService extends ChangeNotifier {
  final storage = const FlutterSecureStorage();
  String get _baseUrl => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000/api';

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> createOrder(List<Map<String, dynamic>> items) async {
    String? token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/buyer/orders');
    final body = jsonEncode({
      'items': items.map((e) => {
        'product_id': e['id'],
        'quantity': 1,
      }).toList(),
    });
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear la orden');
    }
  }

  Future<List<dynamic>> fetchOrders() async {
    String? token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/buyer/orders');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener órdenes');
    }
  }
}
