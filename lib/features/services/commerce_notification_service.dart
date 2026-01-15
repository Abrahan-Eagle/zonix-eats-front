import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'websocket_service.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommerceNotificationService {
  static final CommerceNotificationService _instance = CommerceNotificationService._internal();
  factory CommerceNotificationService() => _instance;
  CommerceNotificationService._internal();

  static String get baseUrl => AppConfig.apiUrl;
  final Logger _logger = Logger();

  StreamSubscription? _wsSubscription;
  StreamController<List<Map<String, dynamic>>>? _notificationsController;
  List<Map<String, dynamic>> _notifications = [];
  bool _isConnected = false;
  int? _commerceId;

  // Getters
  bool get isConnected => _isConnected;
  Stream<List<Map<String, dynamic>>>? get notificationsStream => _notificationsController?.stream;
  List<Map<String, dynamic>> get notifications => _notifications;

  // Obtener todas las notificaciones del comercio
  Future<List<Map<String, dynamic>>> getNotifications({
    String? type,
    bool? read,
    String? sortBy,
    String? sortOrder,
    int? perPage,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (read != null) queryParams['read'] = read.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (perPage != null) queryParams['per_page'] = perPage.toString();

      final uri = Uri.parse('$baseUrl/api/commerce/notifications').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final notifications = List<Map<String, dynamic>>.from(data['data']);
          _notifications = notifications;
          _notificationsController?.add(_notifications);
          return notifications;
        }
        return [];
      } else {
        // Si el endpoint no existe, retornar datos mock
        _logger.w('Endpoint de notificaciones no disponible (${response.statusCode}), usando datos mock');
        return _getMockNotifications();
      }
    } catch (e) {
      _logger.e('Error en getNotifications: $e');
      // En caso de error, retornar datos mock
      return _getMockNotifications();
    }
  }

  // Datos mock para notificaciones
  List<Map<String, dynamic>> _getMockNotifications() {
    return [
      {
        'id': 1,
        'type': 'order',
        'title': 'Nuevo pedido recibido',
        'message': 'Pedido #ORD-001 recibido por \$25.00',
        'read_at': null,
        'created_at': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
      },
      {
        'id': 2,
        'type': 'payment',
        'title': 'Pago confirmado',
        'message': 'Pago confirmado para pedido #ORD-002',
        'read_at': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
        'created_at': DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
      },
      {
        'id': 3,
        'type': 'delivery',
        'title': 'Pedido en camino',
        'message': 'Pedido #ORD-003 está siendo entregado',
        'read_at': null,
        'created_at': DateTime.now().subtract(Duration(minutes: 15)).toIso8601String(),
      },
    ];
  }

  // Obtener una notificación específica
  Future<Map<String, dynamic>> getNotification(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/notifications/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al obtener notificación: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getNotification: $e');
      throw Exception('Error al obtener notificación: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/notifications/$id/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Actualizar notificación local
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          _notificationsController?.add(_notifications);
        }
      } else {
        throw Exception('Error al marcar como leída: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en markAsRead: $e');
      throw Exception('Error al marcar como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commerce/notifications/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Actualizar todas las notificaciones locales
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i]['read_at'] = DateTime.now().toIso8601String();
        }
        _notificationsController?.add(_notifications);
      } else {
        throw Exception('Error al marcar todas como leídas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en markAllAsRead: $e');
      throw Exception('Error al marcar todas como leídas: $e');
    }
  }

  // Eliminar notificación
  Future<void> deleteNotification(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/commerce/notifications/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Remover notificación local
        _notifications.removeWhere((n) => n['id'] == id);
        _notificationsController?.add(_notifications);
      } else {
        throw Exception('Error al eliminar notificación: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en deleteNotification: $e');
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Obtener estadísticas de notificaciones
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/notifications/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        // Si el endpoint no existe, retornar datos mock
        _logger.w('Endpoint de estadísticas no disponible (${response.statusCode}), usando datos mock');
        return _getMockNotificationStats();
      }
    } catch (e) {
      _logger.e('Error en getNotificationStats: $e');
      // En caso de error, retornar datos mock
      return _getMockNotificationStats();
    }
  }

  // Datos mock para estadísticas de notificaciones
  Map<String, dynamic> _getMockNotificationStats() {
    return {
      'total': 15,
      'unread': 3,
      'read': 12,
      'today': 5,
      'this_week': 12,
      'this_month': 45,
    };
  }

  // Conectar WebSocket para notificaciones en tiempo real
  Future<void> connectWebSocket(int commerceId) async {
    if (_isConnected) return;

    try {
      _commerceId = commerceId;
      _notificationsController = StreamController<List<Map<String, dynamic>>>.broadcast();

      // Conectar WebSocket
      await WebSocketService().connect();
      
      // Suscribirse a canales de comercio
      await WebSocketService().subscribeToCommerce(commerceId);
      await WebSocketService().subscribeToPrivateChannel('user.$commerceId');

      // Escuchar mensajes
      _wsSubscription = WebSocketService().messageStream?.listen((event) {
        _handleWebSocketMessage(event);
      });

      _isConnected = true;
      _logger.i('WebSocket conectado para notificaciones de comercio');
    } catch (e) {
      _logger.e('Error conectando WebSocket: $e');
      _isConnected = false;
    }
  }

  // Manejar mensajes de WebSocket
  void _handleWebSocketMessage(Map<String, dynamic> event) {
    try {
      switch (event['type']) {
        case 'notification':
          _handleNewNotification(event['data']);
          break;
        case 'order_created':
          _handleOrderCreated(event['data']);
          break;
        case 'order_status_changed':
          _handleOrderStatusChanged(event['data']);
          break;
        case 'payment_validated':
          _handlePaymentValidated(event['data']);
          break;
        case 'delivery_request':
          _handleDeliveryRequest(event['data']);
          break;
        default:
          _logger.d('Evento WebSocket no manejado: ${event['type']}');
      }
    } catch (e) {
      _logger.e('Error manejando mensaje WebSocket: $e');
    }
  }

  // Manejar nueva notificación
  void _handleNewNotification(Map<String, dynamic> data) {
    final notification = {
      'id': data['id'],
      'title': data['title'],
      'body': data['body'],
      'type': data['type'],
      'data': data['data'],
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _notifications.insert(0, notification);
    _notificationsController?.add(_notifications);
    
    _logger.i('Nueva notificación recibida: ${data['title']}');
  }

  // Manejar nueva orden
  void _handleOrderCreated(Map<String, dynamic> data) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': 'Nueva Orden Recibida',
      'body': 'Has recibido una nueva orden #${data['id']} por \$${data['total']?.toStringAsFixed(2)}',
      'type': 'order',
      'data': data,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _notifications.insert(0, notification);
    _notificationsController?.add(_notifications);
    
    _logger.i('Nueva orden recibida: #${data['id']}');
  }

  // Manejar cambio de estado de orden
  void _handleOrderStatusChanged(Map<String, dynamic> data) {
    final statusText = _getStatusText(data['new_status']);
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': 'Estado de Orden Actualizado',
      'body': 'La orden #${data['order_id']} cambió a: $statusText',
      'type': 'order_status',
      'data': data,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _notifications.insert(0, notification);
    _notificationsController?.add(_notifications);
    
    _logger.i('Estado de orden actualizado: #${data['order_id']} -> ${data['new_status']}');
  }

  // Manejar validación de pago
  void _handlePaymentValidated(Map<String, dynamic> data) {
    final isValid = data['is_valid'] ?? false;
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': isValid ? 'Pago Validado' : 'Pago Rechazado',
      'body': isValid 
          ? 'El pago de la orden #${data['order_id']} ha sido validado'
          : 'El pago de la orden #${data['order_id']} ha sido rechazado',
      'type': 'payment',
      'data': data,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _notifications.insert(0, notification);
    _notificationsController?.add(_notifications);
    
    _logger.i('Pago ${isValid ? 'validado' : 'rechazado'}: #${data['order_id']}');
  }

  // Manejar solicitud de delivery
  void _handleDeliveryRequest(Map<String, dynamic> data) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': 'Solicitud de Delivery',
      'body': 'Se ha solicitado delivery para la orden #${data['order_id']}',
      'type': 'delivery',
      'data': data,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _notifications.insert(0, notification);
    _notificationsController?.add(_notifications);
    
    _logger.i('Solicitud de delivery: #${data['order_id']}');
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment': return 'Pendiente de Pago';
      case 'paid': return 'Pagado';
      case 'preparing': return 'En Preparación';
      case 'ready': return 'Listo';
      case 'on_way': return 'En Camino';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconocido';
    }
  }

  // Obtener notificaciones no leídas
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    return getNotifications(read: false);
  }

  // Obtener notificaciones por tipo
  Future<List<Map<String, dynamic>>> getNotificationsByType(String type) async {
    return getNotifications(type: type);
  }

  // Obtener conteo de notificaciones no leídas
  Future<int> getUnreadCount() async {
    try {
      final unreadNotifications = await getUnreadNotifications();
      return unreadNotifications.length;
    } catch (e) {
      _logger.e('Error obteniendo conteo de no leídas: $e');
      return 0;
    }
  }

  // Desconectar WebSocket
  Future<void> disconnect() async {
    try {
      _wsSubscription?.cancel();
      WebSocketService().disconnect();
      _notificationsController?.close();
      _isConnected = false;
      _logger.i('WebSocket desconectado');
    } catch (e) {
      _logger.e('Error desconectando WebSocket: $e');
    }
  }

  // Limpiar recursos
  void dispose() {
    _wsSubscription?.cancel();
    _notificationsController?.close();
    _isConnected = false;
  }
} 