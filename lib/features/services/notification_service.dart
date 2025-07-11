import 'package:flutter/material.dart';
import 'package:zonix/features/services/auth/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 1,
      'title': 'Nueva Orden Recibida',
      'message': 'Has recibido una nueva orden #ORD-123',
      'type': 'order',
      'priority': 'high',
      'read': false,
      'created_at': '2024-01-15T10:30:00',
      'data': {
        'order_id': 123,
        'order_number': 'ORD-123',
        'amount': 45.50,
      },
    },
    {
      'id': 2,
      'title': 'Comisión Ganada',
      'message': 'Has ganado \$12.50 en comisiones',
      'type': 'commission',
      'priority': 'medium',
      'read': false,
      'created_at': '2024-01-15T09:15:00',
      'data': {
        'commission_amount': 12.50,
        'referral_id': 5,
      },
    },
    {
      'id': 3,
      'title': 'Mantenimiento Programado',
      'message': 'Tu vehículo necesita mantenimiento',
      'type': 'maintenance',
      'priority': 'medium',
      'read': true,
      'created_at': '2024-01-15T08:00:00',
      'data': {
        'vehicle_id': 2,
        'maintenance_date': '2024-01-20',
      },
    },
    {
      'id': 4,
      'title': 'Sistema Actualizado',
      'message': 'Nuevas funciones disponibles',
      'type': 'system',
      'priority': 'low',
      'read': true,
      'created_at': '2024-01-14T16:00:00',
      'data': {
        'version': '1.2.0',
        'features': ['Chat mejorado', 'Nuevos filtros'],
      },
    },
  ];

  // Get all notifications
  Future<List<Map<String, dynamic>>> getNotifications({String? type, bool? read}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/notifications', {'type': type, 'read': read});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var notifications = _mockNotifications;
      
      if (type != null) {
        notifications = notifications.where((n) => n['type'] == type).toList();
      }
      
      if (read != null) {
        notifications = notifications.where((n) => n['read'] == read).toList();
      }
      
      return notifications;
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/notifications/$notificationId/read');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final index = _mockNotifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _mockNotifications[index]['read'] = true;
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/notifications/mark-all-read');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      for (var notification in _mockNotifications) {
        notification['read'] = true;
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/notifications/$notificationId');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      _mockNotifications.removeWhere((n) => n['id'] == notificationId);
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Get notification count
  Future<Map<String, dynamic>> getNotificationCount() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/notifications/count');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 200));
      return {
        'total': _mockNotifications.length,
        'unread': _mockNotifications.where((n) => !n['read']).length,
        'by_type': {
          'order': _mockNotifications.where((n) => n['type'] == 'order').length,
          'commission': _mockNotifications.where((n) => n['type'] == 'commission').length,
          'maintenance': _mockNotifications.where((n) => n['type'] == 'maintenance').length,
          'system': _mockNotifications.where((n) => n['type'] == 'system').length,
        },
      };
    } catch (e) {
      throw Exception('Error fetching notification count: $e');
    }
  }

  // Send push notification
  Future<void> sendPushNotification(Map<String, dynamic> notification) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/notifications/push', notification);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final newNotification = {
        'id': _mockNotifications.length + 1,
        'title': notification['title'],
        'message': notification['message'],
        'type': notification['type'] ?? 'system',
        'priority': notification['priority'] ?? 'medium',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': notification['data'] ?? {},
      };
      _mockNotifications.insert(0, newNotification);
    } catch (e) {
      throw Exception('Error sending push notification: $e');
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/notifications/settings');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return {
        'push_notifications': true,
        'email_notifications': true,
        'sms_notifications': false,
        'order_notifications': true,
        'commission_notifications': true,
        'maintenance_notifications': true,
        'system_notifications': true,
        'quiet_hours': {
          'enabled': true,
          'start': '22:00',
          'end': '08:00',
        },
      };
    } catch (e) {
      throw Exception('Error fetching notification settings: $e');
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/notifications/settings', settings);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      // In a real implementation, this would update the user's settings
    } catch (e) {
      throw Exception('Error updating notification settings: $e');
    }
  }

  // Show in-app notification
  void showInAppNotification(BuildContext context, Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification['message']),
          ],
        ),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _handleNotificationTap(context, notification),
        ),
      ),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'order':
        // Navigate to order details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando a orden #${notification['data']['order_number']}')),
        );
        break;
      case 'commission':
        // Navigate to commission details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando a comisiones')),
        );
        break;
      case 'maintenance':
        // Navigate to maintenance details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando a mantenimiento')),
        );
        break;
      default:
        // Navigate to notifications page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando a notificaciones')),
        );
    }
  }

  // Get notification icon
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'commission':
        return Icons.attach_money;
      case 'maintenance':
        return Icons.build;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color
  Color getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'commission':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Get priority color
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
