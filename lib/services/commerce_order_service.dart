import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commerce_order.dart';
import '../config/app_config.dart';
import '../helpers/auth_helper.dart';

class CommerceOrderService {
  final String apiUrl = '${AppConfig.apiUrl}/api/commerce/orders';

  Future<List<CommerceOrder>> fetchOrders() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(Uri.parse(apiUrl), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> ordersData = data is List ? data : (data['data'] ?? []);
      return ordersData.map((item) => CommerceOrder.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar órdenes');
    }
  }

  Future<CommerceOrder> fetchOrderDetail(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(Uri.parse('$apiUrl/$id'), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CommerceOrder.fromJson(data is Map ? data : data['data']);
    } else {
      throw Exception('Error al cargar detalle de orden');
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$apiUrl/$id/status'),
      headers: headers,
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado de orden');
    }
  }

  Future<void> validatePayment(int id, bool isValid, {String? reason}) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/$id/validate-payment'),
      headers: headers,
      body: {
        'is_valid': isValid.toString(),
        if (reason != null) 'rejection_reason': reason,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al validar pago');
    }
  }
} 