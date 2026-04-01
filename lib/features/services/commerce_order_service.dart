import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/commerce_order.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import 'cache_service.dart';
import '../utils/http_retry.dart';

class CommerceOrderService {
  static String get baseUrl => AppConfig.apiUrl;

  /// Stale-while-revalidate: returns cached commerce orders instantly.
  static Future<List<CommerceOrder>?> getCachedOrders() async {
    final cached = await CacheService.getRawJson('commerce_orders');
    if (cached == null) return null;
    final list = jsonDecode(cached) as List;
    return list.map((j) => CommerceOrder.fromJson(j as Map<String, dynamic>)).toList();
  }

  // Obtener todas las órdenes del comercio
  static Future<List<CommerceOrder>> getOrders({
    String? status,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final uri = Uri.parse('$baseUrl/api/commerce/orders').replace(queryParameters: queryParams);
      
      final response = await withRetry(() => http.get(uri, headers: headers));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          list = data['data'] as List;
        } else if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          final payload = data['data'] as Map<String, dynamic>;
          final rawItems = payload['items'] ?? payload['data'] ?? [];
          list = rawItems is List ? rawItems : <dynamic>[];
        } else {
          return [];
        }
        if (status == null) {
          CacheService.setRawJson('commerce_orders', jsonEncode(list), expiration: const Duration(minutes: 10));
        }
        return list.map((json) => CommerceOrder.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener órdenes: ${response.statusCode}');
      }
    } catch (e) {
      if (status == null) {
        final cached = await CacheService.getRawJson('commerce_orders');
        if (cached != null) {
          final list = jsonDecode(cached) as List;
          return list.map((j) => CommerceOrder.fromJson(j)).toList();
        }
      }
      rethrow;
    }
  }

  // Obtener una orden específica
  static Future<CommerceOrder> getOrder(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/orders/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          return CommerceOrder.fromJson(data['data'] as Map<String, dynamic>);
        }
        return CommerceOrder.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Error al obtener orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener orden: $e');
    }
  }

  static Future<String?> getPickupQrPayload(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/orders/$orderId/pickup-qr'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data']['qr_payload'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Actualizar estado de una orden
  static Future<CommerceOrder> updateOrderStatus(int id, String status) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/commerce/orders/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['order'] != null) {
          return CommerceOrder.fromJson(data['order']);
        }
        // El backend puede devolver solo success/message; reobtener la orden actualizada.
        return getOrder(id);
      } else {
        String message = 'Error al actualizar estado: ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          final msg = body['message']?.toString();
          if (msg != null && msg.isNotEmpty) message = msg;
        } catch (e) {
          debugPrint('[CommerceOrderService] error parse: $e');
        }
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // Rechazar orden en pending_payment (cuando no hay acuerdo tras chat)
  static Future<void> rejectOrder(int orderId, {String? reason}) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/orders/$orderId/reject'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return;
        throw Exception(data['message'] ?? 'Error al rechazar orden');
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(data?['message'] ?? 'Error al rechazar orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al rechazar orden: $e');
    }
  }

  // Aprobar orden para que el comprador pueda proceder al pago
  static Future<void> approveForPayment(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/orders/$orderId/approve-for-payment'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return;
        throw Exception(data['message'] ?? 'Error al aprobar orden para pago');
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(data?['message'] ?? 'Error al aprobar orden para pago: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al aprobar orden para pago: $e');
    }
  }

  // Validar comprobante de pago
  static Future<Map<String, dynamic>> validatePayment(int orderId, bool isValid, {String? reason}) async {
    try {
      if (!isValid && (reason == null || reason.trim().isEmpty)) {
        throw Exception('Debes indicar un motivo de rechazo.');
      }

      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/orders/$orderId/validate-payment'),
        headers: headers,
        body: jsonEncode({
          'is_valid': isValid,
          'rejection_reason': reason?.trim(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final message = data is Map
            ? (data['message'] ??
                data['error'] ??
                (data['errors'] is Map
                    ? (data['errors'].values.first is List
                        ? (data['errors'].values.first as List).first
                        : data['errors'].values.first)
                    : null))
            : null;
        throw Exception((message ?? 'Error al validar pago: ${response.statusCode}').toString());
      }
    } catch (e) {
      throw Exception('Error al validar pago: $e');
    }
  }

  // Solicitar delivery para una orden
  static Future<Map<String, dynamic>> requestDelivery(int orderId, {
    String? notes,
    double? estimatedTime,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/delivery/request'),
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

  // Obtener órdenes pendientes
  static Future<List<CommerceOrder>> getPendingOrders() async {
    return getOrders(status: 'pending_payment');
  }

  static Future<List<CommerceOrder>> getPreparingOrders() async {
    return getOrders(status: 'processing');
  }

  static Future<List<CommerceOrder>> getReadyOrders() async {
    return getOrders(status: 'processing');
  }

  static Future<List<CommerceOrder>> getOnWayOrders() async {
    return getOrders(status: 'shipped');
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
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$baseUrl/api/commerce/orders').replace(queryParameters: queryParams);
      
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