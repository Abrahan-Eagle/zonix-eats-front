import 'package:flutter/foundation.dart';
import 'package:zonix/models/order.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class DeliveryService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  // Get delivery orders (for DeliveryOrdersPage)
  Future<List<Map<String, dynamic>>> getDeliveryOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error fetching delivery orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update order status (for DeliveryOrdersPage)
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return;
        }
        throw Exception('Error updating order status: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating order status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get available orders for delivery
  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/available-orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching available orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get orders assigned to delivery agent
  Future<List<Order>> getAssignedOrders(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/assigned-orders/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching assigned orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Accept order for delivery
  Future<Order> acceptOrder(int orderId, int deliveryAgentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/accept'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'notes': ''}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Order.fromJson(data['data']);
        }
        throw Exception('Error accepting order: Invalid response');
      } else {
        throw Exception('Error accepting order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  // Update delivery status
  Future<Order> updateDeliveryStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Order.fromJson(data['data']);
        }
        throw Exception('Error updating delivery status: Invalid response');
      } else {
        throw Exception('Error updating delivery status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery status: $e');
    }
  }

  // Get delivery history
  Future<List<Order>> getDeliveryHistory(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/history/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching delivery history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery earnings
  Future<Map<String, dynamic>> getDeliveryEarnings(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/earnings/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery earnings: Invalid response');
      } else {
        throw Exception('Error fetching delivery earnings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/routes/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error fetching delivery routes: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update delivery location
  Future<void> updateDeliveryLocation(int deliveryAgentId, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/location/update'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error updating delivery location: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating delivery location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery location: $e');
    }
  }

  // Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStatistics(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/statistics/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery statistics: Invalid response');
      } else {
        throw Exception('Error fetching delivery statistics: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Report delivery issue
  Future<void> reportDeliveryIssue(int orderId, String issue, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/report-issue'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'issue': issue,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error reporting delivery issue: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error reporting delivery issue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reporting delivery issue: $e');
    }
  }
} 