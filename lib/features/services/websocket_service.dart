import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Getters
  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  // Connect to WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final url = '${AppConfig.websocketUrl}/app/local?protocol=7&client=js&version=4.3.1&flash=false';
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Send authentication
      await _sendAuthMessage(token);

      // Listen for messages
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      print('WebSocket conectado exitosamente');
    } catch (e) {
      print('Error conectando WebSocket: $e');
      _scheduleReconnect();
    }
  }

  // Send authentication message
  Future<void> _sendAuthMessage(String token) async {
    final authMessage = {
      'event': 'pusher:subscribe',
      'data': {
        'auth': token,
        'channel': 'private-user.${await _getUserId()}',
      },
    };
    _channel?.sink.add(jsonEncode(authMessage));
  }

  // Get user ID from storage
  Future<String> _getUserId() async {
    // TODO: Implement user ID retrieval from storage
    return '1';
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      // Handle different message types
      switch (data['event']) {
        case 'chat.message':
          _messageController?.add({
            'type': 'chat',
            'data': data['data'],
          });
          break;
        case 'order.status_changed':
          _messageController?.add({
            'type': 'order_update',
            'data': data['data'],
          });
          break;
        case 'delivery.location_update':
          _messageController?.add({
            'type': 'location_update',
            'data': data['data'],
          });
          break;
        case 'notification.new':
          _messageController?.add({
            'type': 'notification',
            'data': data['data'],
          });
          break;
        default:
          _messageController?.add({
            'type': 'unknown',
            'data': data,
          });
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  // Handle WebSocket disconnect
  void _handleDisconnect() {
    print('WebSocket desconectado');
    _isConnected = false;
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Máximo número de intentos de reconexión alcanzado');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectAttempts * 2 + 1), () {
      _reconnectAttempts++;
      print('Intentando reconectar WebSocket (intento $_reconnectAttempts)');
      connect();
    });
  }

  // Send message
  Future<void> sendMessage(String event, Map<String, dynamic> data) async {
    if (!_isConnected) {
      throw Exception('WebSocket no conectado');
    }

    final message = {
      'event': event,
      'data': data,
    };

    _channel?.sink.add(jsonEncode(message));
  }

  // Subscribe to channel
  Future<void> subscribeToChannel(String channelName) async {
    final message = {
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
      },
    };
    _channel?.sink.add(jsonEncode(message));
  }

  // Unsubscribe from channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    final message = {
      'event': 'pusher:unsubscribe',
      'data': {
        'channel': channelName,
      },
    };
    _channel?.sink.add(jsonEncode(message));
  }

  // Disconnect
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  // Send chat message
  Future<void> sendChatMessage(int conversationId, String content, {String type = 'text'}) async {
    await sendMessage('chat.send_message', {
      'conversation_id': conversationId,
      'content': content,
      'type': type,
    });
  }

  // Send location update
  Future<void> sendLocationUpdate(double latitude, double longitude) async {
    await sendMessage('delivery.update_location', {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send order status update
  Future<void> sendOrderStatusUpdate(int orderId, String status) async {
    await sendMessage('order.update_status', {
      'order_id': orderId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
} 