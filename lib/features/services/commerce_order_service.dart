import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/commerce_order.dart';
import '../../config/app_config.dart';
import '../../utils/auth_helper.dart';

class CommerceOrderService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String get baseUrl => AppConfig.apiUrl;

  // Obtener todas las órdenes del comercio
  static Future<List<CommerceOrder>> getOrders({
    String? status,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final uri = Uri.parse('$baseUrl/commerce/orders').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => CommerceOrder.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => CommerceOrder.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error al obtener órdenes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener órdenes: $e');
    }
  }

  // Obtener una orden específica
  static Future<CommerceOrder> getOrder(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/orders/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CommerceOrder.fromJson(data);
      } else {
        throw Exception('Error al obtener orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener orden: $e');
    }
  }

  // Actualizar estado de una orden
  static Future<CommerceOrder> updateOrderStatus(int id, String status) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/commerce/orders/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['order'] != null) {
          return CommerceOrder.fromJson(data['order']);
        }
        throw Exception('Respuesta inválida del servidor');
      } else {
        throw Exception('Error al actualizar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // Validar comprobante de pago
  static Future<Map<String, dynamic>> validatePayment(int orderId, bool isValid, {String? reason}) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/commerce/orders/$orderId/validate-payment'),
        headers: headers,
        body: jsonEncode({
          'is_valid': isValid,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al validar pago: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al validar pago: $e');
    }
  }

  // Obtener estadísticas de órdenes
  static Future<Map<String, dynamic>> getOrderStats() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/orders/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Solicitar delivery para una orden
  static Future<Map<String, dynamic>> requestDelivery(int orderId, {
    String? notes,
    double? estimatedTime,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/commerce/delivery/request'),
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'notes': notes,
          'estimated_time': estimatedTime,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al solicitar delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al solicitar delivery: $e');
    }
  }

  // Obtener historial de órdenes con filtros
  static Future<List<CommerceOrder>> getOrderHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? deliveryType,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (status != null) queryParams['status'] = status;
      if (deliveryType != null) queryParams['delivery_type'] = deliveryType;

      final uri = Uri.parse('$baseUrl/commerce/orders/history').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => CommerceOrder.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => CommerceOrder.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  // Obtener órdenes pendientes
  static Future<List<CommerceOrder>> getPendingOrders() async {
    return getOrders(status: 'pending_payment');
  }

  // Obtener órdenes en preparación
  static Future<List<CommerceOrder>> getPreparingOrders() async {
    return getOrders(status: 'preparing');
  }

  // Obtener órdenes listas para entrega
  static Future<List<CommerceOrder>> getReadyOrders() async {
    return getOrders(status: 'ready');
  }

  // Obtener órdenes en camino
  static Future<List<CommerceOrder>> getOnWayOrders() async {
    return getOrders(status: 'on_way');
  }

  // Obtener órdenes entregadas
  static Future<List<CommerceOrder>> getDeliveredOrders() async {
    return getOrders(status: 'delivered');
  }

  // Obtener órdenes canceladas
  static Future<List<CommerceOrder>> getCancelledOrders() async {
    return getOrders(status: 'cancelled');
  }

  // Buscar órdenes por cliente
  static Future<List<CommerceOrder>> searchOrdersByCustomer(String customerName) async {
    return getOrders(search: customerName);
  }

  // Obtener órdenes por rango de fechas
  static Future<List<CommerceOrder>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$baseUrl/commerce/orders').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => CommerceOrder.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => CommerceOrder.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error al obtener órdenes por fecha: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener órdenes por fecha: $e');
    }
  }
} 