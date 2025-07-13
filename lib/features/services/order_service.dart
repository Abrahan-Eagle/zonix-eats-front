import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../helpers/auth_helper.dart';
import 'package:http_parser/http_parser.dart';

class OrderService extends ChangeNotifier {
  final String _baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;

  // POST /api/buyer/orders - Crear orden
  Future<Order> createOrder(List<CartItem> items) async {
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
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al crear la orden');
      }
    } else {
      throw Exception('Error al crear la orden: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders - Listar órdenes del usuario
  Future<List<Order>> fetchOrders() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle the new API response structure with success and data wrapper
      if (data['success'] == true && data['data'] != null) {
        final ordersData = data['data'];
        if (ordersData is List) {
          return ordersData.map<Order>((item) => Order.fromJson(item)).toList();
        }
      }
      return [];
    } else {
      throw Exception('Error al obtener órdenes: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{id} - Obtener detalle de orden específica
  Future<Order> getOrderById(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener la orden');
      }
    } else {
      throw Exception('Error al obtener la orden: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/payment-proof - Subir comprobante de pago
  Future<void> uploadPaymentProof(int orderId, String filePath, String fileType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/payment-proof');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath(
      'payment_proof', 
      filePath, 
      contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al subir comprobante de pago');
      }
    } else {
      throw Exception('Error al subir comprobante de pago: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/cancel - Cancelar orden
  Future<void> cancelOrder(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/cancel');
    final response = await http.post(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al cancelar la orden');
      }
    } else {
      throw Exception('Error al cancelar la orden: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{id}/comprobante - Subir comprobante (método alternativo)
  Future<void> uploadComprobante(int orderId, String filePath, String fileType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/comprobante');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    
    request.files.add(await http.MultipartFile.fromPath(
      'comprobante', 
      filePath, 
      contentType: fileType == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', fileType)
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al subir comprobante');
      }
    } else {
      throw Exception('Error al subir comprobante: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{orderId}/tracking - Obtener tracking de la orden
  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/tracking');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Error al obtener tracking');
      }
    } else {
      throw Exception('Error al obtener tracking: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{orderId}/tracking/location - Actualizar ubicación de entrega
  Future<void> updateDeliveryLocation(int orderId, double latitude, double longitude) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/tracking/location');
    final response = await http.post(
      url,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al actualizar ubicación');
      }
    } else {
      throw Exception('Error al actualizar ubicación: ${response.statusCode}');
    }
  }

  // GET /api/buyer/orders/{orderId}/messages - Obtener mensajes de la orden
  Future<List<Map<String, dynamic>>> getOrderMessages(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/messages');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener mensajes');
      }
    } else {
      throw Exception('Error al obtener mensajes: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{orderId}/messages - Enviar mensaje
  Future<void> sendOrderMessage(int orderId, String message) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/buyer/orders/$orderId/messages');
    final response = await http.post(
      url,
      body: jsonEncode({
        'message': message,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al enviar mensaje');
      }
    } else {
      throw Exception('Error al enviar mensaje: ${response.statusCode}');
    }
  }

  // Método para validar comprobante (para comercios)
  Future<void> validarComprobante(int orderId, String accion) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('$_baseUrl/api/commerce/orders/$orderId/validar-comprobante');
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'accion': accion})
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al validar comprobante');
      }
    } else {
      throw Exception('Error al validar comprobante: ${response.statusCode}');
    }
  }

  // Alias method for getUserOrders to maintain compatibility
  Future<List<Order>> getUserOrders() async {
    return await fetchOrders();
  }
}
