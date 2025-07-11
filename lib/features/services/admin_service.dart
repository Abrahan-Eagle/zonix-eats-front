import 'package:zonix/features/services/auth/api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 1,
      'name': 'Juan Pérez',
      'email': 'juan.perez@email.com',
      'phone': '+51 123 456 789',
      'role': 'buyer',
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
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/users', {'role': role, 'status': status});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      var users = _mockUsers;
      if (role != null) {
        users = users.where((u) => u['role'] == role).toList();
      }
      if (status != null) {
        users = users.where((u) => u['status'] == status).toList();
      }
      return users;
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/users/$userId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final user = _mockUsers.firstWhere((u) => u['id'] == userId);
      return user;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Update user status
  Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/admin/users/$userId/status', {'status': status});
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        _mockUsers[index]['status'] = status;
        return _mockUsers[index];
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // Update user role
  Future<Map<String, dynamic>> updateUserRole(int userId, String role, int level) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/admin/users/$userId/role', {
      //   'role': role,
      //   'level': level,
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        _mockUsers[index]['role'] = role;
        _mockUsers[index]['level'] = level;
        return _mockUsers[index];
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(int userId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/admin/users/$userId');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      _mockUsers.removeWhere((u) => u['id'] == userId);
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/statistics');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_users': _mockUsers.length,
        'active_users': _mockUsers.where((u) => u['status'] == 'active').length,
        'suspended_users': _mockUsers.where((u) => u['status'] == 'suspended').length,
        'user_distribution': {
          'buyers': _mockUsers.where((u) => u['role'] == 'buyer').length,
          'commerce': _mockUsers.where((u) => u['role'] == 'commerce').length,
          'delivery': _mockUsers.where((u) => u['role'] == 'delivery').length,
          'transport': _mockUsers.where((u) => u['role'] == 'transport').length,
          'affiliate': _mockUsers.where((u) => u['role'] == 'affiliate').length,
        },
        'verification_status': {
          'verified': _mockUsers.where((u) => u['verification_status'] == 'verified').length,
          'pending': _mockUsers.where((u) => u['verification_status'] == 'pending').length,
          'unverified': _mockUsers.where((u) => u['verification_status'] == 'unverified').length,
        },
        'monthly_growth': [
          {'month': 'Enero', 'users': 1000, 'growth': 0},
          {'month': 'Febrero', 'users': 1100, 'growth': 10.0},
          {'month': 'Marzo', 'users': 1250, 'growth': 13.6},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching system statistics: $e');
    }
  }

  // Get security logs
  Future<List<Map<String, dynamic>>> getSecurityLogs({String? action, String? status}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/security-logs', {'action': action, 'status': status});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var logs = _mockSecurityLogs;
      if (action != null) {
        logs = logs.where((l) => l['action'] == action).toList();
      }
      if (status != null) {
        logs = logs.where((l) => l['status'] == status).toList();
      }
      return logs;
    } catch (e) {
      throw Exception('Error fetching security logs: $e');
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics({String? metric, String? period}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/analytics', {'metric': metric, 'period': period});
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'user_growth': _mockAnalytics.firstWhere((a) => a['metric'] == 'user_growth')['data'],
        'revenue_growth': _mockAnalytics.firstWhere((a) => a['metric'] == 'revenue_growth')['data'],
        'order_volume': _mockAnalytics.firstWhere((a) => a['metric'] == 'order_volume')['data'],
        'top_performing_roles': [
          {'role': 'buyer', 'count': 850, 'percentage': 68.0},
          {'role': 'commerce', 'count': 120, 'percentage': 9.6},
          {'role': 'delivery', 'count': 180, 'percentage': 14.4},
          {'role': 'transport', 'count': 50, 'percentage': 4.0},
          {'role': 'affiliate', 'count': 50, 'percentage': 4.0},
        ],
        'geographic_distribution': [
          {'region': 'Lima', 'users': 750, 'percentage': 60.0},
          {'region': 'Arequipa', 'users': 200, 'percentage': 16.0},
          {'region': 'Trujillo', 'users': 150, 'percentage': 12.0},
          {'region': 'Piura', 'users': 100, 'percentage': 8.0},
          {'region': 'Otros', 'users': 50, 'percentage': 4.0},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/system-health');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return {
        'server_status': 'healthy',
        'database_status': 'healthy',
        'api_status': 'healthy',
        'uptime': '99.9%',
        'response_time': '120ms',
        'active_connections': 1250,
        'memory_usage': '65%',
        'cpu_usage': '45%',
        'disk_usage': '78%',
        'last_backup': '2024-01-15T02:00:00',
        'security_alerts': 0,
        'performance_score': 95,
      };
    } catch (e) {
      throw Exception('Error fetching system health: $e');
    }
  }

  // Get user activity
  Future<List<Map<String, dynamic>>> getUserActivity(int userId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/users/$userId/activity');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return [
        {
          'id': 1,
          'action': 'login',
          'timestamp': '2024-01-15T10:30:00',
          'ip_address': '192.168.1.100',
          'user_agent': 'Mozilla/5.0 (Android)',
          'status': 'success',
        },
        {
          'id': 2,
          'action': 'order_placed',
          'timestamp': '2024-01-15T11:15:00',
          'order_id': 123,
          'amount': 85.0,
          'status': 'completed',
        },
        {
          'id': 3,
          'action': 'profile_updated',
          'timestamp': '2024-01-15T12:00:00',
          'changes': ['phone_number', 'address'],
          'status': 'success',
        },
      ];
    } catch (e) {
      throw Exception('Error fetching user activity: $e');
    }
  }

  // Send system notification
  Future<Map<String, dynamic>> sendSystemNotification(Map<String, dynamic> notification) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/admin/notifications', notification);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': notification['title'],
        'message': notification['message'],
        'type': notification['type'],
        'target_users': notification['target_users'],
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
        'recipients_count': 1250,
      };
    } catch (e) {
      throw Exception('Error sending system notification: $e');
    }
  }

  // Get system settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/admin/settings');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return {
        'app_name': 'ZONIX EATS',
        'app_version': '1.0.0',
        'maintenance_mode': false,
        'registration_enabled': true,
        'email_verification_required': true,
        'phone_verification_required': true,
        'max_file_size': '10MB',
        'allowed_file_types': ['jpg', 'png', 'pdf'],
        'session_timeout': 3600,
        'password_policy': {
          'min_length': 8,
          'require_uppercase': true,
          'require_lowercase': true,
          'require_numbers': true,
          'require_special_chars': true,
        },
        'notification_settings': {
          'email_notifications': true,
          'push_notifications': true,
          'sms_notifications': false,
        },
      };
    } catch (e) {
      throw Exception('Error fetching system settings: $e');
    }
  }

  // Update system settings
  Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/admin/settings', settings);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'status': 'success',
        'message': 'System settings updated successfully',
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error updating system settings: $e');
    }
  }
} 