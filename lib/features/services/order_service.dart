import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../helpers/auth_helper.dart';
import 'package:http_parser/http_parser.dart';

class OrderService extends ChangeNotifier {
  String get _baseUrl => dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000/api';

  Future<void> createOrder(List<CartItem> items) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders');
    final body = jsonEncode({
      'items': items.map((e) => {
        'product_id': e.id,
        'quantity': e.quantity,
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

  Future<void> uploadComprobante(int orderId, String filePath, String fileType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/comprobante');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('comprobante', filePath, contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Error al subir comprobante');
    }
  }

  Future<void> validarComprobante(int orderId, String accion) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/commerce/orders/$orderId/validar-comprobante');
    final response = await http.post(url, headers: headers, body: jsonEncode({'accion': accion}));
    if (response.statusCode != 200) {
      throw Exception('Error al validar comprobante');
    }
  }
}
