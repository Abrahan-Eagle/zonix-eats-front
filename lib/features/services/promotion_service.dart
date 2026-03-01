import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class PromotionService {
  final Logger _logger = Logger();

  // GET /api/buyer/promotions/active - Obtener promociones activas
  Future<List<Map<String, dynamic>>> getActivePromotions({
    int? commerceId,
    String? type,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (commerceId != null) queryParams['commerce_id'] = commerceId.toString();
      if (type != null) queryParams['type'] = type;
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/promotions/active')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener promociones activas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getActivePromotions: $e');
      throw Exception('Error al obtener promociones activas: $e');
    }
  }

  // GET /api/buyer/promotions/coupons - Obtener cupones disponibles
  Future<List<Map<String, dynamic>>> getAvailableCoupons({
    int? commerceId,
    double? minAmount,
    String? category,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (commerceId != null) queryParams['commerce_id'] = commerceId.toString();
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (category != null) queryParams['category'] = category;

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/promotions/coupons')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener cupones: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getAvailableCoupons: $e');
      throw Exception('Error al obtener cupones: $e');
    }
  }

  // POST /api/buyer/promotions/validate-coupon - Validar cupón
  // Backend espera: code (required), order_amount (required, numeric, min:0)
  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    double? orderAmount,
    int? commerceId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/promotions/validate-coupon');
      final amount = orderAmount ?? 0.0;

      final body = {
        'code': couponCode.trim(),
        'order_amount': amount,
        if (commerceId != null) 'commerce_id': commerceId,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final data = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>? ?? <String, dynamic>{})
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>? ?? {};
        }
        throw Exception(data['message'] as String? ?? 'Error al validar cupón');
      }

      final message = data['message'] as String? ?? _defaultCouponError(response.statusCode);
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final parts = errors.values.expand((e) => e is List ? e : [e]);
        final msg = parts.map((e) => e.toString()).join(' ').trim();
        throw Exception(msg.isNotEmpty ? msg : message);
      }
      throw Exception(message);
    } catch (e) {
      _logger.e('Error en validateCoupon: $e');
      rethrow;
    }
  }

  static String _defaultCouponError(int statusCode) {
    switch (statusCode) {
      case 422:
        return 'Datos inválidos. Revisa el código y el monto del pedido.';
      case 404:
        return 'Cupón no válido o expirado.';
      case 400:
        return 'No se pudo aplicar el cupón.';
      default:
        return 'Error al validar cupón ($statusCode).';
    }
  }

  // POST /api/buyer/promotions/apply-coupon - Aplicar cupón a la orden
  // Backend espera: order_id (required), coupon_id (required)
  Future<Map<String, dynamic>> applyCouponToOrder({
    required int couponId,
    required int orderId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/promotions/apply-coupon');
      final body = {'coupon_id': couponId, 'order_id': orderId};

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final data = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>? ?? <String, dynamic>{})
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>? ?? {};
        }
        throw Exception(data['message'] as String? ?? 'Error al aplicar cupón');
      }

      final message = data['message'] as String? ?? 'Error al aplicar cupón (${response.statusCode})';
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final parts = errors.values.expand((e) => e is List ? e : [e]);
        final msg = parts.map((e) => e.toString()).join(' ').trim();
        throw Exception(msg.isNotEmpty ? msg : message);
      }
      throw Exception(message);
    } catch (e) {
      _logger.e('Error en applyCouponToOrder: $e');
      rethrow;
    }
  }

  // GET /api/buyer/promotions/coupon-history - Obtener historial de cupones
  Future<List<Map<String, dynamic>>> getCouponHistory({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/promotions/coupon-history')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener historial de cupones: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getCouponHistory: $e');
      throw Exception('Error al obtener historial de cupones: $e');
    }
  }
} 