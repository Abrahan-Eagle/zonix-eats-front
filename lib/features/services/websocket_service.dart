import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final _storage = const FlutterSecureStorage();
  final _logger = Logger();
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Subscribed channels
  final Set<String> _subscribedChannels = <String>{};

  // Getters
  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  // Connect to Laravel Echo Server
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      // Build WebSocket URL for Laravel Echo Server
      final wsUrl = _buildWebSocketUrl();
      _logger.i('Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

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

      _logger.i('WebSocket connected successfully');
    } catch (e) {
      _logger.e('Error connecting WebSocket: $e');
      _scheduleReconnect();
    }
  }

  // Build WebSocket URL for Laravel Echo Server
  String _buildWebSocketUrl() {
    return AppConfig.websocketUrl;
  }

  // Send authentication message
  Future<void> _sendAuthMessage(String token) async {
    final userId = await _getUserId();
    final authMessage = {
      'event': 'pusher:subscribe',
      'data': {
        'auth': token,
        'channel': 'private-user.$userId',
      },
    };
    _channel?.sink.add(jsonEncode(authMessage));
  }

  // Get user ID from storage
  Future<String> _getUserId() async {
    final userId = await _storage.read(key: 'userId');
    return userId ?? '1';
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      _logger.d('WebSocket message received: $data');
      
      // Handle different message types
      switch (data['event']) {
        case 'OrderCreated':
          _messageController?.add({
            'type': 'order_created',
            'data': data['data'],
          });
          break;
        case 'OrderStatusChanged':
          _messageController?.add({
            'type': 'order_status_changed',
            'data': data['data'],
          });
          break;
        case 'PaymentValidated':
          _messageController?.add({
            'type': 'payment_validated',
            'data': data['data'],
          });
          break;
        case 'NewMessage':
          _messageController?.add({
            'type': 'chat_message',
            'data': data['data'],
          });
          break;
        case 'DeliveryLocationUpdated':
          _messageController?.add({
            'type': 'delivery_location',
            'data': data['data'],
          });
          break;
        case 'pusher:connection_established':
          _logger.i('WebSocket connection established');
          break;
        case 'pusher:subscription_succeeded':
          _logger.i('Channel subscription succeeded: ${data['channel']}');
          break;
        case 'pusher:subscription_error':
          _logger.e('Channel subscription error: ${data['data']}');
          break;
        default:
          _messageController?.add({
            'type': 'unknown',
            'data': data,
          });
      }
    } catch (e) {
      _logger.e('Error parsing WebSocket message: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  // Handle WebSocket disconnect
  void _handleDisconnect() {
    _logger.i('WebSocket disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Maximum reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectAttempts * 2 + 1), () {
      _reconnectAttempts++;
      _logger.i('Attempting WebSocket reconnection (attempt $_reconnectAttempts)');
      connect();
    });
  }

  // Subscribe to private channel
  Future<void> subscribeToPrivateChannel(String channelName) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }

    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token not found');
    }

    final message = {
      'event': 'pusher:subscribe',
      'data': {
        'auth': token,
        'channel': 'private-$channelName',
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _subscribedChannels.add('private-$channelName');
    _logger.i('Subscribed to private channel: private-$channelName');
  }

  // Subscribe to presence channel
  Future<void> subscribeToPresenceChannel(String channelName) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }

    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token not found');
    }

    final message = {
      'event': 'pusher:subscribe',
      'data': {
        'auth': token,
        'channel': 'presence-$channelName',
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _subscribedChannels.add('presence-$channelName');
    _logger.i('Subscribed to presence channel: presence-$channelName');
  }

  // Subscribe to public channel
  Future<void> subscribeToPublicChannel(String channelName) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _subscribedChannels.add(channelName);
    _logger.i('Subscribed to public channel: $channelName');
  }

  // Alias method for subscribeToChannel to maintain compatibility
  Future<void> subscribeToChannel(String channelName) async {
    await subscribeToPublicChannel(channelName);
  }

  // Unsubscribe from channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    if (!_isConnected) {
      return;
    }

    final message = {
      'event': 'pusher:unsubscribe',
      'data': {
        'channel': channelName,
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _subscribedChannels.remove(channelName);
    _logger.i('Unsubscribed from channel: $channelName');
  }

  // Subscribe to order updates
  Future<void> subscribeToOrder(int orderId) async {
    await subscribeToPrivateChannel('orders.$orderId');
  }

  // Subscribe to user updates
  Future<void> subscribeToUser(int userId) async {
    await subscribeToPrivateChannel('user.$userId');
  }

  // Subscribe to commerce updates
  Future<void> subscribeToCommerce(int commerceId) async {
    await subscribeToPrivateChannel('commerce.$commerceId');
  }

  // Subscribe to delivery updates
  Future<void> subscribeToDelivery(int deliveryAgentId) async {
    await subscribeToPrivateChannel('delivery.$deliveryAgentId');
  }

  // Subscribe to order chat
  Future<void> subscribeToOrderChat(int orderId) async {
    await subscribeToPresenceChannel('chat.$orderId');
  }

  // Disconnect
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _isConnected = false;
    _reconnectAttempts = 0;
    _subscribedChannels.clear();
    _logger.i('WebSocket disconnected');
  }

  // Get subscribed channels
  Set<String> get subscribedChannels => Set.from(_subscribedChannels);
} 