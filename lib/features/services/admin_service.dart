import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import '../utils/http_retry.dart';

class AdminService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  /// Stale-while-revalidate: returns cached admin stats instantly.
  static Future<Map<String, dynamic>?> getCachedStats() async {
    final cached = await CacheService.getRawJson('admin_stats');
    if (cached == null) return null;
    return Map<String, dynamic>.from(jsonDecode(cached));
  }

  /// Stale-while-revalidate: returns cached admin users instantly.
  static Future<List<Map<String, dynamic>>?> getCachedUsers() async {
    final cached = await CacheService.getRawJson('admin_users');
    if (cached == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(cached));
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getUsers({String? role, String? status}) async {
    if (!ConnectivityService.isConnected && role == null && status == null) {
      final cached = await CacheService.getRawJson('admin_users');
      if (cached != null) return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
    try {
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: queryParams);
      final headers = await AuthHelper.getAuthHeaders();
      final response = await withRetry(() => http.get(uri, headers: headers));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
        if (role == null && status == null) {
          CacheService.setRawJson('admin_users', jsonEncode(list), expiration: const Duration(minutes: 10));
        }
        return list;
      } else {
        throw Exception('Error fetching users: ${response.statusCode}');
      }
    } catch (e) {
      if (role == null && status == null) {
        final cached = await CacheService.getRawJson('admin_users');
        if (cached != null) return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? Map<String, dynamic>.from(data) : {'id': userId};
      } else {
        throw Exception('Error fetching user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Update user status
  Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/$userId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data is Map ? Map<String, dynamic>.from(data['user'] ?? data) : {'id': userId, 'status': status};
      } else {
        throw Exception('Error updating user status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // Update user role
  Future<Map<String, dynamic>> updateUserRole(int userId, String role, int level) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/$userId/role'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data is Map ? Map<String, dynamic>.from(data) : {'id': userId, 'role': role};
      } else {
        throw Exception('Error updating user role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error deleting user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    if (!ConnectivityService.isConnected) {
      final cached = await CacheService.getRawJson('admin_stats');
      if (cached != null) return Map<String, dynamic>.from(jsonDecode(cached));
    }
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await withRetry(() => http.get(
        Uri.parse('$baseUrl/api/admin/statistics'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        CacheService.setRawJson('admin_stats', jsonEncode(result), expiration: const Duration(minutes: 5));
        return result;
      } else {
        throw Exception('Error fetching system statistics: ${response.statusCode}');
      }
    } catch (e) {
      final cached = await CacheService.getRawJson('admin_stats');
      if (cached != null) return Map<String, dynamic>.from(jsonDecode(cached));
      rethrow;
    }
  }

  // Get security logs
  Future<List<Map<String, dynamic>>> getSecurityLogs({String? action, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (action != null) queryParams['action'] = action;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/admin/security-logs').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['logs'] != null) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
        return [];
      } else {
        throw Exception('Error fetching security logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching security logs: $e');
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics({String? metric, String? period}) async {
    try {
      final queryParams = <String, String>{};
      if (metric != null) queryParams['metric'] = metric;
      if (period != null) queryParams['period'] = period;

      final uri = Uri.parse('$baseUrl/api/admin/analytics').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? Map<String, dynamic>.from(data) : {};
      } else {
        throw Exception('Error fetching analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/system-health'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? Map<String, dynamic>.from(data) : {};
      } else {
        throw Exception('Error fetching system health: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching system health: $e');
    }
  }

  // Get user activity
  Future<List<Map<String, dynamic>>> getUserActivity(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users/$userId/activity'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // La respuesta puede tener 'orders' u otra estructura
        if (data is Map) {
          final activities = <Map<String, dynamic>>[];
          if (data['orders'] != null) {
            activities.addAll(List<Map<String, dynamic>>.from(data['orders']));
          }
          return activities;
        }
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error fetching user activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user activity: $e');
    }
  }

  // Send system notification
  Future<Map<String, dynamic>> sendSystemNotification(Map<String, dynamic> notification) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/notifications'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(notification),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data is Map ? Map<String, dynamic>.from(data) : {
          'id': DateTime.now().millisecondsSinceEpoch,
          'status': 'sent',
        };
      } else {
        throw Exception('Error sending system notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending system notification: $e');
    }
  }

  // Get system settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/settings'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? Map<String, dynamic>.from(data) : {};
      } else {
        throw Exception('Error fetching system settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching system settings: $e');
    }
  }

  // Update system settings
  Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/settings'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        notifyListeners();
        return data is Map ? Map<String, dynamic>.from(data) : {
          'status': 'success',
          'message': 'System settings updated successfully',
        };
      } else {
        throw Exception('Error updating system settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating system settings: $e');
    }
  }

  // ---- Delivery Settings ----
  Future<Map<String, dynamic>> getDeliverySettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/delivery-settings'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? data);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateDeliverySettings(Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/delivery-settings'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode(settings),
    );
    if (response.statusCode == 200) {
      notifyListeners();
      return jsonDecode(response.body);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Delivery Zones ----
  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/delivery-zones'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] ?? data;
      return List<Map<String, dynamic>>.from(list is List ? list : []);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createDeliveryZone(Map<String, dynamic> zone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/delivery-zones'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode(zone),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      notifyListeners();
      return jsonDecode(response.body);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateDeliveryZone(int id, Map<String, dynamic> zone) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/delivery-zones/$id'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode(zone),
    );
    if (response.statusCode == 200) {
      notifyListeners();
      return jsonDecode(response.body);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  Future<void> deleteDeliveryZone(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/delivery-zones/$id'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      notifyListeners();
      return;
    }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Commerces ----
  Future<Map<String, dynamic>> getCommerces({int page = 1, String? search, bool? open}) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (open != null) params['open'] = open ? '1' : '0';
    final uri = Uri.parse('$baseUrl/api/admin/commerces').replace(queryParameters: params);
    final response = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getCommerceById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/commerces/$id'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<void> updateCommerceStatus(int id, bool open) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/commerces/$id/status'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode({'open': open}),
    );
    if (response.statusCode == 200) { notifyListeners(); return; }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Delivery Companies ----
  Future<Map<String, dynamic>> getDeliveryCompanies({int page = 1, String? search}) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final uri = Uri.parse('$baseUrl/api/admin/delivery-companies').replace(queryParameters: params);
    final response = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getDeliveryCompanyById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/delivery-companies/$id'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getDeliveryCompanyAgents(int companyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/delivery-companies/$companyId/agents'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Orders (admin) ----
  Future<Map<String, dynamic>> getOrders({int page = 1, String? status, int? commerceId}) async {
    final params = <String, String>{'page': '$page'};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (commerceId != null) params['commerce_id'] = '$commerceId';
    final uri = Uri.parse('$baseUrl/api/admin/orders').replace(queryParameters: params);
    final response = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/orders/$orderId/status'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) { notifyListeners(); return; }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Disputes ----
  Future<Map<String, dynamic>> getDisputes({int page = 1, String? status, String? type}) async {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    final uri = Uri.parse('$baseUrl/api/admin/disputes').replace(queryParameters: params);
    final response = await http.get(uri, headers: await AuthHelper.getAuthHeaders());
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getDisputeStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/disputes/stats'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getDisputeById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/disputes/$id'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<void> resolveDispute(int id, String resolution, String adminNotes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/disputes/$id/resolve'),
      headers: await AuthHelper.getAuthHeaders(),
      body: jsonEncode({
        'resolution': resolution,
        'admin_notes': adminNotes.trim(),
      }),
    );
    if (response.statusCode == 200) { notifyListeners(); return; }
    throw Exception('Error: ${response.statusCode}');
  }

  // ---- Analytics (detailed endpoints) ----
  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/overview'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAnalyticsRevenue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/revenue'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAnalyticsOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/orders'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAnalyticsRealtime() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/realtime'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAnalyticsKpi() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/kpi-dashboard'),
      headers: await AuthHelper.getAuthHeaders(),
    );
    if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    throw Exception('Error: ${response.statusCode}');
  }
}