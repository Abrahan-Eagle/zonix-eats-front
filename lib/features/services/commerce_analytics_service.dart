import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommerceAnalyticsService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  /// Obtener analytics generales del comercio
  Future<Map<String, dynamic>> getOverview() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/analytics/overview'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener overview: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo overview analytics: $e');
    }
  }

  /// Obtener analytics de revenue
  Future<Map<String, dynamic>> getRevenue({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/commerce/analytics/revenue').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener revenue analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo revenue analytics: $e');
    }
  }

  /// Obtener analytics de órdenes
  Future<Map<String, dynamic>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/analytics/orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener order analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo order analytics: $e');
    }
  }

  /// Obtener productos más vendidos
  Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/analytics/products'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener product analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo product analytics: $e');
    }
  }

  /// Obtener analytics de clientes
  Future<Map<String, dynamic>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/analytics/customers'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener customer analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo customer analytics: $e');
    }
  }

  /// Obtener métricas de rendimiento
  Future<Map<String, dynamic>> getPerformance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/analytics/performance'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener performance analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo performance analytics: $e');
    }
  }
}
