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

      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/promotions/active')
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

      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/promotions/coupons')
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
  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    double? orderAmount,
    int? commerceId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/promotions/validate-coupon');
      
      final body = {
        'coupon_code': couponCode,
        if (orderAmount != null) 'order_amount': orderAmount,
        if (commerceId != null) 'commerce_id': commerceId,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al validar cupón');
        }
      } else {
        throw Exception('Error al validar cupón: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en validateCoupon: $e');
      throw Exception('Error al validar cupón: $e');
    }
  }

  // POST /api/buyer/promotions/apply-coupon - Aplicar cupón a la orden
  Future<Map<String, dynamic>> applyCouponToOrder({
    required String couponCode,
    required int orderId,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/promotions/apply-coupon');
      
      final body = {
        'coupon_code': couponCode,
        'order_id': orderId,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Error al aplicar cupón');
        }
      } else {
        throw Exception('Error al aplicar cupón: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en applyCouponToOrder: $e');
      throw Exception('Error al aplicar cupón: $e');
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

      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/promotions/coupon-history')
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