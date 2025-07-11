import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalyticsService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  
  // Mock data for development
  static final Map<String, dynamic> _mockAnalytics = {
    'overview': {
      'total_orders': 1247,
      'total_revenue': 45680.50,
      'total_customers': 892,
      'total_deliveries': 1189,
      'average_order_value': 36.63,
      'customer_satisfaction': 4.7,
      'delivery_success_rate': 98.5,
      'active_restaurants': 45,
      'active_delivery_agents': 23,
    },
    'revenue': {
      'daily': [
        {'date': '2024-01-10', 'revenue': 1250.50, 'orders': 34},
        {'date': '2024-01-11', 'revenue': 1380.75, 'orders': 37},
        {'date': '2024-01-12', 'revenue': 1420.25, 'orders': 39},
        {'date': '2024-01-13', 'revenue': 1580.00, 'orders': 43},
        {'date': '2024-01-14', 'revenue': 1650.30, 'orders': 45},
        {'date': '2024-01-15', 'revenue': 1720.80, 'orders': 47},
      ],
      'monthly': [
        {'month': 'Octubre', 'revenue': 28500.00, 'orders': 780},
        {'month': 'Noviembre', 'revenue': 31200.00, 'orders': 850},
        {'month': 'Diciembre', 'revenue': 34500.00, 'orders': 920},
        {'month': 'Enero', 'revenue': 45680.50, 'orders': 1247},
      ],
      'by_category': [
        {'category': 'Comida Rápida', 'revenue': 18500.25, 'percentage': 40.5},
        {'category': 'Pizzerías', 'revenue': 12500.75, 'percentage': 27.4},
        {'category': 'Cafés', 'revenue': 8200.50, 'percentage': 18.0},
        {'category': 'Restaurantes', 'revenue': 6479.00, 'percentage': 14.1},
      ],
    },
    'orders': {
      'status_distribution': [
        {'status': 'Completado', 'count': 1189, 'percentage': 95.3},
        {'status': 'En Proceso', 'count': 35, 'percentage': 2.8},
        {'status': 'Cancelado', 'count': 23, 'percentage': 1.9},
      ],
      'peak_hours': [
        {'hour': '12:00', 'orders': 45, 'percentage': 15.2},
        {'hour': '13:00', 'orders': 52, 'percentage': 17.6},
        {'hour': '19:00', 'orders': 48, 'percentage': 16.2},
        {'hour': '20:00', 'orders': 41, 'percentage': 13.8},
        {'hour': '21:00', 'orders': 38, 'percentage': 12.8},
      ],
      'delivery_times': {
        'average': 28.5,
        'fastest': 15.2,
        'slowest': 45.8,
        'distribution': [
          {'range': '0-15 min', 'count': 89, 'percentage': 7.5},
          {'range': '15-30 min', 'count': 892, 'percentage': 75.0},
          {'range': '30-45 min', 'count': 178, 'percentage': 15.0},
          {'range': '45+ min', 'count': 30, 'percentage': 2.5},
        ],
      },
    },
    'customers': {
      'new_vs_returning': {
        'new_customers': 234,
        'returning_customers': 658,
        'retention_rate': 73.8,
      },
      'top_customers': [
        {'id': 1, 'name': 'María García', 'orders': 45, 'total_spent': 1850.75},
        {'id': 2, 'name': 'Carlos López', 'orders': 38, 'total_spent': 1520.50},
        {'id': 3, 'name': 'Ana Rodríguez', 'orders': 32, 'total_spent': 1280.25},
        {'id': 4, 'name': 'Luis Martínez', 'orders': 28, 'total_spent': 1150.00},
        {'id': 5, 'name': 'Sofia Pérez', 'orders': 25, 'total_spent': 980.75},
      ],
      'customer_segments': [
        {'segment': 'VIP', 'count': 45, 'revenue': 12500.00},
        {'segment': 'Regular', 'count': 234, 'revenue': 18500.00},
        {'segment': 'Casual', 'count': 613, 'revenue': 14680.50},
      ],
    },
    'restaurants': {
      'top_performers': [
        {'id': 1, 'name': 'Restaurante El Buen Sabor', 'orders': 156, 'revenue': 5850.75, 'rating': 4.8},
        {'id': 2, 'name': 'Pizzería La Italiana', 'orders': 134, 'revenue': 4820.50, 'rating': 4.6},
        {'id': 3, 'name': 'Café Central', 'orders': 98, 'revenue': 3240.25, 'rating': 4.7},
        {'id': 4, 'name': 'Hamburguesas Express', 'orders': 87, 'revenue': 2980.00, 'rating': 4.5},
        {'id': 5, 'name': 'Sushi Bar', 'orders': 76, 'revenue': 3850.75, 'rating': 4.9},
      ],
      'performance_metrics': {
        'average_preparation_time': 12.5,
        'average_rating': 4.6,
        'order_acceptance_rate': 96.8,
        'customer_satisfaction': 4.7,
      },
    },
    'delivery': {
      'agent_performance': [
        {'id': 1, 'name': 'Juan Pérez', 'deliveries': 89, 'rating': 4.8, 'earnings': 1250.75},
        {'id': 2, 'name': 'María García', 'deliveries': 76, 'rating': 4.7, 'earnings': 1080.50},
        {'id': 3, 'name': 'Carlos López', 'deliveries': 65, 'rating': 4.6, 'earnings': 920.25},
        {'id': 4, 'name': 'Ana Rodríguez', 'deliveries': 58, 'rating': 4.9, 'earnings': 850.00},
        {'id': 5, 'name': 'Luis Martínez', 'deliveries': 52, 'rating': 4.5, 'earnings': 780.75},
      ],
      'delivery_zones': [
        {'zone': 'Centro', 'deliveries': 456, 'average_time': 25.5, 'revenue': 18500.00},
        {'zone': 'Norte', 'deliveries': 234, 'average_time': 32.8, 'revenue': 9200.00},
        {'zone': 'Sur', 'deliveries': 198, 'average_time': 28.2, 'revenue': 7800.00},
        {'zone': 'Este', 'deliveries': 156, 'average_time': 35.5, 'revenue': 6200.00},
        {'zone': 'Oeste', 'deliveries': 145, 'average_time': 30.1, 'revenue': 5580.50},
      ],
    },
    'marketing': {
      'campaign_performance': [
        {'campaign': 'Descuento 20%', 'orders': 89, 'revenue': 3560.00, 'roi': 2.8},
        {'campaign': 'Envío Gratis', 'orders': 67, 'revenue': 2680.00, 'roi': 1.9},
        {'campaign': 'Primera Orden', 'orders': 45, 'revenue': 1800.00, 'roi': 3.2},
        {'campaign': 'Referidos', 'orders': 34, 'revenue': 1360.00, 'roi': 4.1},
      ],
      'customer_acquisition': {
        'organic': 156,
        'referral': 45,
        'campaign': 33,
        'total_cost': 2500.00,
        'cost_per_acquisition': 10.68,
      },
    },
  };

  // Get overview analytics
  Future<Map<String, dynamic>> getOverviewAnalytics() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/overview'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? _mockAnalytics['overview'];
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 600));
        return _mockAnalytics['overview'];
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      return _mockAnalytics['overview'];
    }
  }

  // Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/analytics/revenue').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? _mockAnalytics['revenue'];
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 500));
        return _mockAnalytics['revenue'];
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return _mockAnalytics['revenue'];
    }
  }

  // Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/orders', {
      //   'status': status,
      //   'start_date': startDate?.toIso8601String(),
      //   'end_date': endDate?.toIso8601String(),
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return _mockAnalytics['orders'];
    } catch (e) {
      throw Exception('Error fetching order analytics: $e');
    }
  }

  // Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/customers');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockAnalytics['customers'];
    } catch (e) {
      throw Exception('Error fetching customer analytics: $e');
    }
  }

  // Get restaurant analytics
  Future<Map<String, dynamic>> getRestaurantAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/restaurants');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockAnalytics['restaurants'];
    } catch (e) {
      throw Exception('Error fetching restaurant analytics: $e');
    }
  }

  // Get delivery analytics
  Future<Map<String, dynamic>> getDeliveryAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/delivery');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockAnalytics['delivery'];
    } catch (e) {
      throw Exception('Error fetching delivery analytics: $e');
    }
  }

  // Get marketing analytics
  Future<Map<String, dynamic>> getMarketingAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/marketing');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockAnalytics['marketing'];
    } catch (e) {
      throw Exception('Error fetching marketing analytics: $e');
    }
  }

  // Get custom analytics report
  Future<Map<String, dynamic>> getCustomReport(Map<String, dynamic> reportConfig) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/analytics/custom-report', reportConfig);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Generate custom report based on configuration
      final report = <String, dynamic>{};
      
      if (reportConfig['include_revenue'] == true) {
        report['revenue'] = _mockAnalytics['revenue'];
      }
      
      if (reportConfig['include_orders'] == true) {
        report['orders'] = _mockAnalytics['orders'];
      }
      
      if (reportConfig['include_customers'] == true) {
        report['customers'] = _mockAnalytics['customers'];
      }
      
      if (reportConfig['include_restaurants'] == true) {
        report['restaurants'] = _mockAnalytics['restaurants'];
      }
      
      if (reportConfig['include_delivery'] == true) {
        report['delivery'] = _mockAnalytics['delivery'];
      }
      
      if (reportConfig['include_marketing'] == true) {
        report['marketing'] = _mockAnalytics['marketing'];
      }
      
      return report;
    } catch (e) {
      throw Exception('Error generating custom report: $e');
    }
  }

  // Export analytics data
  Future<String> exportAnalyticsData(Map<String, dynamic> exportConfig) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/analytics/export', exportConfig);
      // return response['data']['download_url'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 2000));
      return 'https://example.com/analytics-export-${DateTime.now().millisecondsSinceEpoch}.csv';
    } catch (e) {
      throw Exception('Error exporting analytics data: $e');
    }
  }

  // Get real-time analytics
  Future<Map<String, dynamic>> getRealTimeAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/realtime');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return {
        'active_orders': 12,
        'active_delivery_agents': 8,
        'online_restaurants': 23,
        'revenue_today': 1850.75,
        'orders_today': 47,
        'average_wait_time': 18.5,
        'system_uptime': 99.8,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error fetching real-time analytics: $e');
    }
  }

  // Get predictive analytics
  Future<Map<String, dynamic>> getPredictiveAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/predictive');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      return {
        'revenue_forecast': {
          'next_week': 12500.00,
          'next_month': 52000.00,
          'next_quarter': 158000.00,
        },
        'order_forecast': {
          'next_week': 340,
          'next_month': 1450,
          'next_quarter': 4200,
        },
        'customer_growth': {
          'next_month': 120,
          'next_quarter': 380,
        },
        'peak_hours_prediction': [
          {'hour': '12:00', 'predicted_orders': 52},
          {'hour': '13:00', 'predicted_orders': 58},
          {'hour': '19:00', 'predicted_orders': 55},
          {'hour': '20:00', 'predicted_orders': 48},
        ],
        'demand_forecast': {
          'high_demand_days': ['Viernes', 'Sábado', 'Domingo'],
          'low_demand_days': ['Lunes', 'Martes'],
          'seasonal_trends': [
            {'month': 'Febrero', 'trend': 'up', 'percentage': 15},
            {'month': 'Marzo', 'trend': 'up', 'percentage': 8},
            {'month': 'Abril', 'trend': 'stable', 'percentage': 2},
          ],
        },
      };
    } catch (e) {
      throw Exception('Error fetching predictive analytics: $e');
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
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/comparative', {
      //   'period1_start': period1Start?.toIso8601String(),
      //   'period1_end': period1End?.toIso8601String(),
      //   'period2_start': period2Start?.toIso8601String(),
      //   'period2_end': period2End?.toIso8601String(),
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'revenue_comparison': {
          'period1': 12500.00,
          'period2': 15800.00,
          'change_percentage': 26.4,
          'trend': 'up',
        },
        'orders_comparison': {
          'period1': 340,
          'period2': 425,
          'change_percentage': 25.0,
          'trend': 'up',
        },
        'customer_comparison': {
          'period1': 89,
          'period2': 112,
          'change_percentage': 25.8,
          'trend': 'up',
        },
        'delivery_time_comparison': {
          'period1': 32.5,
          'period2': 28.5,
          'change_percentage': -12.3,
          'trend': 'down',
        },
        'satisfaction_comparison': {
          'period1': 4.5,
          'period2': 4.7,
          'change_percentage': 4.4,
          'trend': 'up',
        },
      };
    } catch (e) {
      throw Exception('Error fetching comparative analytics: $e');
    }
  }

  // Get KPI dashboard
  Future<Map<String, dynamic>> getKPIDashboard() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/analytics/kpi-dashboard');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'financial_kpis': {
          'total_revenue': 45680.50,
          'revenue_growth': 15.8,
          'average_order_value': 36.63,
          'profit_margin': 18.5,
        },
        'operational_kpis': {
          'order_fulfillment_rate': 98.5,
          'average_delivery_time': 28.5,
          'customer_satisfaction': 4.7,
          'system_uptime': 99.8,
        },
        'customer_kpis': {
          'customer_retention_rate': 73.8,
          'customer_acquisition_cost': 10.68,
          'customer_lifetime_value': 245.50,
          'net_promoter_score': 8.2,
        },
        'growth_kpis': {
          'month_over_month_growth': 12.5,
          'new_customer_growth': 18.3,
          'restaurant_growth': 8.7,
          'delivery_agent_growth': 15.2,
        },
      };
    } catch (e) {
      throw Exception('Error fetching KPI dashboard: $e');
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