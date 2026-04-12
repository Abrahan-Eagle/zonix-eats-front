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
  static List<dynamic> _extractListFromEnvelope(dynamic body) {
    if (body is List) return body;
    if (body is! Map<String, dynamic>) return const [];
    final payload = body['data'];
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List) return items;
      final nestedData = payload['data'];
      if (nestedData is List) return nestedData;
    }
    return const [];
  }

  static Map<String, dynamic>? _extractMapFromEnvelope(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final payload = body['data'];
    if (payload is Map<String, dynamic>) return payload;
    return body;
  }

  /// Evita mostrar al usuario URLs de red, Pusher o trazas largas.
  static String _sanitizeUserMessage(String message) {
    final t = message.trim();
    final lower = t.toLowerCase();
    if (t.contains('http://') ||
        t.contains('https://') ||
        lower.contains('curl error') ||
        lower.contains('pusher') ||
        lower.contains('could not resolve host')) {
      return 'No se pudo completar la acción. Revisa tu conexión e intenta de nuevo.';
    }
    if (t.length > 280) {
      return '${t.substring(0, 277)}...';
    }
    return t;
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      if (response.body.isEmpty) return '$fallback: ${response.statusCode}';
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) return message.trim();
        final error = decoded['error']?.toString();
        if (error != null && error.trim().isNotEmpty) return error.trim();
        final errors = decoded['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              final first = value.first?.toString();
              if (first != null && first.trim().isNotEmpty) return first.trim();
            } else if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[CommerceOrderService] parse error: $e');
    }
    return '$fallback: ${response.statusCode}';
  }

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
        final list = _extractListFromEnvelope(data);
        if (list.isEmpty) return [];
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
        final orderMap = _extractMapFromEnvelope(data);
        if (orderMap == null) {
          throw Exception('Respuesta inválida');
        }
        return CommerceOrder.fromJson(orderMap);
      } else {
        throw Exception(_extractErrorMessage(response, 'Error al obtener orden'));
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
        throw Exception(_sanitizeUserMessage(
            _extractErrorMessage(response, 'Error al actualizar estado')));
      }
    } catch (e) {
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      throw Exception(_sanitizeUserMessage(msg));
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
        throw Exception(_extractErrorMessage(response, 'Error al rechazar orden'));
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
        throw Exception(_extractErrorMessage(response, 'Error al aprobar orden para pago'));
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
        throw Exception(_sanitizeUserMessage(
            (message ?? 'Error al validar pago: ${response.statusCode}').toString()));
      }
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      throw Exception(_sanitizeUserMessage(raw));
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