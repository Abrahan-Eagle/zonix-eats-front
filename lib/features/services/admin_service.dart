import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class AdminService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 1,
      'name': 'Juan Pérez',
      'email': 'juan.perez@email.com',
      'phone': '+51 123 456 789',
      'role': 'users',
      'level': 0,
      'status': 'active',
      'created_at': '2024-01-01',
      'last_login': '2024-01-15T10:30:00',
      'total_orders': 15,
      'total_spent': 850.0,
      'verification_status': 'verified',
    },
    {
      'id': 2,
      'name': 'María González',
      'email': 'maria.gonzalez@email.com',
      'phone': '+51 987 654 321',
      'role': 'commerce',
      'level': 1,
      'status': 'active',
      'created_at': '2024-01-05',
      'last_login': '2024-01-15T14:20:00',
      'total_orders': 0,
      'total_spent': 0.0,
      'verification_status': 'verified',
    },
    {
      'id': 3,
      'name': 'Carlos Rodríguez',
      'email': 'carlos.rodriguez@email.com',
      'phone': '+51 456 789 123',
      'role': 'delivery',
      'level': 2,
      'status': 'active',
      'created_at': '2024-01-10',
      'last_login': '2024-01-15T16:45:00',
      'total_orders': 0,
      'total_spent': 0.0,
      'verification_status': 'pending',
    },
    {
      'id': 4,
      'name': 'Ana Martínez',
      'email': 'ana.martinez@email.com',
      'phone': '+51 111 222 333',
      'role': 'transport',
      'level': 3,
      'status': 'suspended',
      'created_at': '2024-01-12',
      'last_login': '2024-01-14T09:15:00',
      'total_orders': 0,
      'total_spent': 0.0,
      'verification_status': 'verified',
    },
    {
      'id': 5,
      'name': 'Luis Fernández',
      'email': 'luis.fernandez@email.com',
      'phone': '+51 444 555 666',
      'role': 'affiliate',
      'level': 4,
      'status': 'active',
      'created_at': '2024-01-15',
      'last_login': '2024-01-15T18:30:00',
      'total_orders': 0,
      'total_spent': 0.0,
      'verification_status': 'verified',
    },
  ];

  static final List<Map<String, dynamic>> _mockSystemStats = [
    {
      'id': 1,
      'metric': 'total_users',
      'value': 1250,
      'change': 12.5,
      'period': 'month',
      'category': 'users',
    },
    {
      'id': 2,
      'metric': 'active_users',
      'value': 890,
      'change': 8.3,
      'period': 'month',
      'category': 'users',
    },
    {
      'id': 3,
      'metric': 'total_orders',
      'value': 3450,
      'change': 15.7,
      'period': 'month',
      'category': 'orders',
    },
    {
      'id': 4,
      'metric': 'total_revenue',
      'value': 125000.0,
      'change': 22.1,
      'period': 'month',
      'category': 'revenue',
    },
    {
      'id': 5,
      'metric': 'average_order_value',
      'value': 36.2,
      'change': 5.8,
      'period': 'month',
      'category': 'orders',
    },
    {
      'id': 6,
      'metric': 'customer_satisfaction',
      'value': 4.6,
      'change': 0.2,
      'period': 'month',
      'category': 'quality',
    },
  ];

  static final List<Map<String, dynamic>> _mockSecurityLogs = [
    {
      'id': 1,
      'user_id': 1,
      'user_name': 'Juan Pérez',
      'action': 'login',
      'ip_address': '192.168.1.100',
      'user_agent': 'Mozilla/5.0 (Android)',
      'status': 'success',
      'timestamp': '2024-01-15T10:30:00',
      'location': 'Lima, Perú',
    },
    {
      'id': 2,
      'user_id': 2,
      'user_name': 'María González',
      'action': 'password_change',
      'ip_address': '192.168.1.101',
      'user_agent': 'Mozilla/5.0 (iOS)',
      'status': 'success',
      'timestamp': '2024-01-15T14:20:00',
      'location': 'Lima, Perú',
    },
    {
      'id': 3,
      'user_id': 3,
      'user_name': 'Carlos Rodríguez',
      'action': 'login',
      'ip_address': '192.168.1.102',
      'user_agent': 'Mozilla/5.0 (Android)',
      'status': 'failed',
      'timestamp': '2024-01-15T16:45:00',
      'location': 'Lima, Perú',
    },
    {
      'id': 4,
      'user_id': 4,
      'user_name': 'Ana Martínez',
      'action': 'account_suspension',
      'ip_address': '192.168.1.103',
      'user_agent': 'Admin Panel',
      'status': 'success',
      'timestamp': '2024-01-15T09:15:00',
      'location': 'Lima, Perú',
    },
  ];

  static final List<Map<String, dynamic>> _mockAnalytics = [
    {
      'id': 1,
      'metric': 'user_growth',
      'data': [
        {'date': '2024-01-01', 'value': 1000},
        {'date': '2024-01-08', 'value': 1100},
        {'date': '2024-01-15', 'value': 1250},
      ],
      'category': 'users',
    },
    {
      'id': 2,
      'metric': 'revenue_growth',
      'data': [
        {'date': '2024-01-01', 'value': 100000},
        {'date': '2024-01-08', 'value': 115000},
        {'date': '2024-01-15', 'value': 125000},
      ],
      'category': 'revenue',
    },
    {
      'id': 3,
      'metric': 'order_volume',
      'data': [
        {'date': '2024-01-01', 'value': 3000},
        {'date': '2024-01-08', 'value': 3200},
        {'date': '2024-01-15', 'value': 3450},
      ],
      'category': 'orders',
    },
  ];

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
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 500));
        var users = _mockUsers;
        if (role != null) {
          users = users.where((u) => u['role'] == role).toList();
        }
        if (status != null) {
          users = users.where((u) => u['status'] == status).toList();
        }
        return users;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      var users = _mockUsers;
      if (role != null) {
        users = users.where((u) => u['role'] == role).toList();
      }
      if (status != null) {
        users = users.where((u) => u['status'] == status).toList();
      }
      return users;
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 300));
      try {
        return _mockUsers.firstWhere((u) => u['id'] == userId);
      } catch (_) {
        throw Exception('Error fetching user: $e');
      }
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_users': _mockUsers.length,
        'active_users': _mockUsers.where((u) => u['status'] == 'active').length,
        'suspended_users': _mockUsers.where((u) => u['status'] == 'suspended').length,
        'user_distribution': {
          'users': _mockUsers.where((u) => u['role'] == 'users').length,
          'commerce': _mockUsers.where((u) => u['role'] == 'commerce').length,
          'delivery': _mockUsers.where((u) => u['role'] == 'delivery').length,
        },
      };
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      var logs = _mockSecurityLogs;
      if (action != null) {
        logs = logs.where((l) => l['action'] == action).toList();
      }
      if (status != null) {
        logs = logs.where((l) => l['status'] == status).toList();
      }
      return logs;
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'user_growth': _mockAnalytics.firstWhere((a) => a['metric'] == 'user_growth', orElse: () => {'data': []})['data'],
        'revenue_growth': _mockAnalytics.firstWhere((a) => a['metric'] == 'revenue_growth', orElse: () => {'data': []})['data'],
        'order_volume': _mockAnalytics.firstWhere((a) => a['metric'] == 'order_volume', orElse: () => {'data': []})['data'],
      };
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      return {
        'server_status': 'healthy',
        'database_status': 'healthy',
        'api_status': 'healthy',
        'uptime': '99.9%',
        'response_time': '120ms',
      };
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      return [
        {
          'id': 1,
          'action': 'login',
          'timestamp': '2024-01-15T10:30:00',
          'status': 'success',
        },
      ];
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
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 300));
      return {
        'app_name': 'ZONIX EATS',
        'app_version': '1.0.0',
        'maintenance_mode': false,
        'registration_enabled': true,
      };
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