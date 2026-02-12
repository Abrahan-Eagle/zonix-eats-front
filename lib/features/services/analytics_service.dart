import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class AnalyticsService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  // Get overview analytics
  Future<Map<String, dynamic>> getOverviewAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/overview'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['data'] ?? {});
      } else {
        throw Exception('Error al obtener overview analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/admin/analytics/revenue').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['data'] ?? {});
      } else {
        throw Exception('Error al obtener revenue analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/admin/analytics/orders').replace(queryParameters: queryParams);
      
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
        throw Exception('Error al obtener order analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/customers'),
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
      rethrow;
    }
  }

  // Get restaurant analytics
  Future<Map<String, dynamic>> getRestaurantAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/restaurants'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener restaurant analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery analytics
  Future<Map<String, dynamic>> getDeliveryAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/delivery'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener delivery analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get marketing analytics
  Future<Map<String, dynamic>> getMarketingAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/marketing'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener marketing analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get custom analytics report
  Future<Map<String, dynamic>> getCustomReport(Map<String, dynamic> reportConfig) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/analytics/custom-report'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(reportConfig),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Export analytics data
  Future<String> exportAnalyticsData(Map<String, dynamic> exportConfig) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/analytics/export'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(exportConfig),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['download_url'] != null) {
          return data['data']['download_url'];
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al exportar datos: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get real-time analytics
  Future<Map<String, dynamic>> getRealTimeAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/realtime'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener real-time analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get predictive analytics
  Future<Map<String, dynamic>> getPredictiveAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/predictive'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener predictive analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get comparative analytics
  Future<Map<String, dynamic>> getComparativeAnalytics({
    DateTime? period1Start,
    DateTime? period1End,
    DateTime? period2Start,
    DateTime? period2End,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period1Start != null) queryParams['period1_start'] = period1Start.toIso8601String();
      if (period1End != null) queryParams['period1_end'] = period1End.toIso8601String();
      if (period2Start != null) queryParams['period2_start'] = period2Start.toIso8601String();
      if (period2End != null) queryParams['period2_end'] = period2End.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/admin/analytics/comparative').replace(queryParameters: queryParams);
      
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
        throw Exception('Error al obtener comparative analytics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get KPI dashboard
  Future<Map<String, dynamic>> getKPIDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/analytics/kpi-dashboard'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener KPI dashboard: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Format currency
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Format percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Format number with commas
  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Get trend indicator
  String getTrendIndicator(double change) {
    if (change > 0) {
      return '↗️';
    } else if (change < 0) {
      return '↘️';
    } else {
      return '→';
    }
  }

  // Get trend color
  String getTrendColor(double change) {
    if (change > 0) {
      return 'green';
    } else if (change < 0) {
      return 'red';
    } else {
      return 'grey';
    }
  }
} 