import 'package:flutter/material.dart';
import 'package:zonix/models/notification_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class NotificationService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;

  // Get all notifications
  Future<List<Map<String, dynamic>>> getNotifications({String? type, bool? read}) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (read != null) queryParams['read'] = read.toString();

      final uri = Uri.parse('$baseUrl/api/notifications').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  // Get notifications as NotificationItem objects
  Future<List<NotificationItem>> getNotificationItems({String? type, bool? read}) async {
    try {
      final notifications = await getNotifications(type: type, read: read);
      return notifications.map((notification) => NotificationItem(
        title: notification['title'] ?? '',
        body: notification['message'] ?? '',
        receivedAt: DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now(),
      )).toList();
    } catch (e) {
      throw Exception('Error fetching notification items: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al marcar notificación como leída: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/mark-all-read'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return;
      } else {
        throw Exception('Error al marcar todas como leídas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar notificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Get notification count
  Future<Map<String, dynamic>> getNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/count'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countData = data['data'];
        if (countData == null) {
          return {
            'total': 0,
            'unread': 0,
            'by_type': <String, int>{},
          };
        }
        return Map<String, dynamic>.from(countData);
      } else {
        throw Exception('Error al obtener conteo de notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send push notification
  Future<void> sendPushNotification(Map<String, dynamic> notification) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/push'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'title': notification['title'],
          'message': notification['message'] ?? notification['body'],
          'type': notification['type'] ?? 'system',
          'data': notification['data'] ?? {},
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return;
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al enviar notificación push: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending push notification: $e');
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/settings'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al obtener configuración: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/settings'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return;
        }
        throw Exception('Error en respuesta del servidor');
      } else {
        throw Exception('Error al actualizar configuración: ${response.statusCode}');
      }
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification['message']),
          ],
        ),
        duration: const Duration(seconds: 4),
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
          const SnackBar(content: Text('Navegando a comisiones')),
        );
        break;
      case 'maintenance':
        // Navigate to maintenance details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navegando a mantenimiento')),
        );
        break;
      default:
        // Navigate to notifications page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navegando a notificaciones')),
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

  // Create test notification (for testing purposes)
  Future<void> createTestNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al crear notificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }
}
