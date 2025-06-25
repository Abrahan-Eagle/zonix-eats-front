import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/order.dart';
import '../../helpers/auth_helper.dart';

class OrderService extends ChangeNotifier {
  String get _baseUrl => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000/api';

  Future<void> createOrder(List<Map<String, dynamic>> items) async {
    final headers = await AuthHelper.getAuthHeaders();
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
      headers: headers,
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear la orden');
    }
  }

  Future<List<Order>> fetchOrders() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders');
    final response = await http.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map<Order>((item) => Order.fromJson(item)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Error al obtener órdenes');
    }
  }
}
