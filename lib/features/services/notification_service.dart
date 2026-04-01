import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/commerce/commerce_order_detail_page.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import 'package:zonix/features/screens/delivery/delivery_order_detail_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_orders_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import '../utils/http_retry.dart';
import 'package:zonix/models/notification_item.dart';
import 'package:zonix/main.dart' show showLocalNotification;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';
import 'error_handler.dart';
import 'pusher_service.dart';

class NotificationService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  static NotificationService? _instance;
  static NotificationService? get instance => _instance;

  List<NotificationItem> _items = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _pusherSubscription;
  final _newNotificationController = StreamController<NotificationItem>.broadcast();

  List<NotificationItem> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<NotificationItem> get newNotificationStream => _newNotificationController.stream;

  /// Una sola carga concurrente (MainRouter + pantalla de notificaciones no duplican GET).
  Future<void>? _loadInitialDataInFlight;

  NotificationService() {
    _instance = this;
    _initPusherListener();
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    _newNotificationController.close();
    super.dispose();
  }

  void _initPusherListener() {
    _pusherSubscription = PusherService.instance.eventStream.listen((event) {
      final eventName = event['eventName']?.toString() ?? '';
      final data = _coerceEventData(event['data']);

      // Solo log en debug y solo para notificaciones in-app (evita ruido de OrderStatusChanged, etc.)
      if (kDebugMode && eventName.contains('NotificationCreated')) {
        debugPrint('🔔 NotificationService: NotificationCreated');
      }

      // El nombre del evento en Pusher suele omitir el namespace o usar el definido en broadcastAs()
      if (eventName.contains('NotificationCreated')) {
        _handleNewNotification(data);
      }
    });
  }

  /// Pusher a veces entrega `data` como String JSON.
  Map<String, dynamic> _coerceEventData(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('[NotificationService] Pusher data parse error: $e');
      }
    }
    return {};
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      final newItem = NotificationItem.fromJson(data);
      
      if (newItem.id != null && _items.any((n) => n.id == newItem.id)) {
        return;
      }

      _items.insert(0, newItem);
      if (newItem.isUnread) {
        _unreadCount++;
        _lastPusherBump = DateTime.now();
        HapticFeedback.lightImpact();
        _newNotificationController.add(newItem);

        final now = DateTime.now();
        if (_lastLocalNotificationAt == null ||
            now.difference(_lastLocalNotificationAt!).inSeconds >= 2) {
          final payload = newItem.data != null ? jsonEncode(newItem.data) : null;
          showLocalNotification(
            title: newItem.title,
            body: newItem.body,
            payload: payload,
          );
          _lastLocalNotificationAt = now;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling new notification from Pusher: $e');
    }
  }

  /// Called from FCM foreground handler so the badge updates even if Pusher
  /// hasn't delivered the event yet. Skips if Pusher already bumped the count
  /// in the last 2 seconds (same logical notification).
  DateTime? _lastPusherBump;
  DateTime? _lastLocalNotificationAt;

  void incrementUnreadFromFcm() {
    final now = DateTime.now();
    if (_lastPusherBump != null &&
        now.difference(_lastPusherBump!).inSeconds < 2) {
      return;
    }
    _unreadCount++;
    notifyListeners();
  }

  /// Populates [_items] from cache instantly without showing loading spinner.
  Future<void> loadCachedNotifications() async {
    final cached = await CacheService.getRawJson('notifications');
    if (cached != null) {
      final list = List<Map<String, dynamic>>.from(jsonDecode(cached));
      _items = list.map((j) => NotificationItem.fromJson(j)).toList();
      notifyListeners();
    }
  }

  Future<void> loadInitialData() async {
    if (_loadInitialDataInFlight != null) {
      return _loadInitialDataInFlight!;
    }
    _loadInitialDataInFlight = _loadInitialDataImpl();
    try {
      await _loadInitialDataInFlight!;
    } finally {
      _loadInitialDataInFlight = null;
    }
  }

  Future<void> _loadInitialDataImpl() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        getNotificationItems(),
        getNotificationCount(),
      ]);

      final fresh = results[0] as List<NotificationItem>;
      final freshIds = fresh.map((n) => n.id).toSet();
      final pusherOnly = _items
          .where((n) => n.id != null && !freshIds.contains(n.id))
          .toList();
      _items = [...pusherOnly, ...fresh];

      final stats = results[1] as Map<String, dynamic>;
      _unreadCount = (stats['unread'] ?? 0) + pusherOnly.where((n) => n.isUnread).length;
    } catch (e) {
      _error = ErrorHandler.getUserFriendlyMessage(e);
      debugPrint('Error loading initial notification data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all notifications
  Future<List<Map<String, dynamic>>> getNotifications({String? type, bool? read}) async {
    if (!ConnectivityService.isConnected && type == null && read == null) {
      final cached = await CacheService.getRawJson('notifications');
      if (cached != null) return List<Map<String, dynamic>>.from(jsonDecode(cached));
    }
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (read != null) queryParams['read'] = read.toString();

      final uri = Uri.parse('$baseUrl/api/notifications').replace(queryParameters: queryParams);
      final headers = await AuthHelper.getAuthHeaders();
      final response = await withRetry(() => http.get(uri, headers: headers));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = List<Map<String, dynamic>>.from(data['data']);
          if (type == null && read == null) {
            CacheService.setRawJson('notifications', jsonEncode(list), expiration: const Duration(minutes: 30));
          }
          return list;
        }
        return [];
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      if (type == null && read == null) {
        final cached = await CacheService.getRawJson('notifications');
        if (cached != null) return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
      rethrow;
    }
  }

  // Get notifications as NotificationItem objects
  Future<List<NotificationItem>> getNotificationItems({String? type, bool? read}) async {
    try {
      final notifications = await getNotifications(type: type, read: read);
      return notifications.map((n) => NotificationItem.fromJson(Map<String, dynamic>.from(n))).toList();
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

      final now = DateTime.now();
      final idx = _items.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        final item = _items[idx];
        if (item.isUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
        }
        _items[idx] = NotificationItem(
          id: item.id,
          title: item.title,
          body: item.body,
          receivedAt: item.receivedAt,
          readAt: now,
          type: item.type,
          data: item.data,
        );
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Mark all notifications as read (backend: POST)
  Future<void> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/mark-all-read'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        _unreadCount = 0;
        final now = DateTime.now();
        _items = _items.map((item) {
          if (item.isUnread) {
            return NotificationItem(
              id: item.id,
              title: item.title,
              body: item.body,
              receivedAt: item.receivedAt,
              readAt: now,
              type: item.type,
              data: item.data,
            );
          }
          return item;
        }).toList();
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

      final removed = _items.where((n) => n.id == notificationId).toList();
      _items.removeWhere((n) => n.id == notificationId);
      for (final r in removed) {
        if (r.isUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
        }
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Get notification count (usa /notifications/stats del backend)
  Future<Map<String, dynamic>> getNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/stats'),
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
        final map = Map<String, dynamic>.from(countData);
        // Backend devuelve unread_count; normalizamos a 'unread'
        final unread = map['unread'] ?? map['unread_count'] ?? 0;
        return {
          'total': unread,
          'unread': unread,
          'by_type': map['by_type'] ?? <String, int>{},
        };
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

  // Handle notification tap (Deep Linking)
  void navigateToNotificationDetail(BuildContext context, NotificationItem notification) {
    final type = notification.type ?? '';
    final data = notification.data ?? {};
    final rawId = data['order_id'];
    int? orderId;
    if (rawId != null) {
      orderId = rawId is int ? rawId : int.tryParse(rawId.toString());
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final role = userProvider.userRole;
    final senderName = (data['sender_name'] ?? '').toString();

    void markReadIfNeeded() {
      if (notification.id != null && notification.isUnread) {
        markAsRead(notification.id!);
      }
    }

    if (orderId == null || orderId <= 0) {
      markReadIfNeeded();
      return;
    }
    final oid = orderId;

    if (type == 'chat') {
      if (role == 'commerce' || role == 'delivery_agent' || role == 'delivery') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommerceChatMessagesPage(
              orderId: oid,
              customerName: senderName.isNotEmpty ? senderName : 'Cliente',
            ),
          ),
        );
      } else if (role == 'delivery_company') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryCompanyOrdersPage(highlightOrderId: oid),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerOrderChatPage(orderId: oid),
          ),
        );
      }
      markReadIfNeeded();
      return;
    }

    final isOrderLike = type == 'order' ||
        type == 'commerce_order' ||
        type == 'delivery_order' ||
        type.isEmpty;

    if (!isOrderLike) {
      markReadIfNeeded();
      return;
    }

    if (role == 'commerce') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommerceOrderDetailPage(orderId: oid),
        ),
      );
    } else if (role == 'delivery_company') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryCompanyOrdersPage(highlightOrderId: oid),
        ),
      );
    } else if (role == 'delivery_agent' || role == 'delivery') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryOrderDetailLoaderPage(orderId: oid),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: oid, order: null),
        ),
      );
    }

    markReadIfNeeded();
  }

  // Handle old notification tap (Map-based, for backward compatibility or direct SnackBar actions)
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final item = NotificationItem.fromJson(notification);
    navigateToNotificationDetail(context, item);
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
        return AppColors.blue;
      case 'commission':
        return AppColors.green;
      case 'maintenance':
        return AppColors.orange;
      case 'system':
        return AppColors.purple;
      default:
        return AppColors.textMutedGray;
    }
  }

  // Get priority color
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.orange;
      case 'low':
        return AppColors.green;
      default:
        return AppColors.textMutedGray;
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
