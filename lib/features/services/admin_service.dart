import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class AdminService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  // Get all users
  Future<List<Map<String, dynamic>>> getUsers({String? role, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error fetching users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/statistics'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map ? Map<String, dynamic>.from(data) : {};
      } else {
        throw Exception('Error fetching system statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching system statistics: $e');
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
} 