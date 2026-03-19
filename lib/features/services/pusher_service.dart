import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

/// Servicio de Pusher Channels para eventos en tiempo casi real (Orders, chat, etc.)
///
/// Usa https://pusher.com para notificaciones, mensajes y chat.
class PusherService {
  // Singleton
  static PusherService? _instance;
  static PusherService get instance {
    _instance ??= PusherService._();
    return _instance!;
  }

  PusherService._();

  PusherChannelsFlutter? _pusher;
  bool _isConnected = false;
  bool _isInitialized = false;

  // Canales realmente suscritos en Pusher (socket).
  final Set<String> _subscribedChannels = {};

  /// Cuántas pantallas/servicios piden cada canal. Solo al llegar a 0 se hace unsubscribe real.
  /// Evita que al cerrar el chat se corte el canal que el detalle de orden sigue usando (y viceversa).
  final Map<String, int> _channelRefCount = {};

  // Stream para eventos de dominio (Orders, chat, notificaciones, etc.)
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Inicializa Pusher con credenciales desde `.env`
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _isConnected;
    }

    try {
      String pusherKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
      String pusherCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? 'mt1';

      if (pusherKey.isEmpty && !dotenv.isInitialized) {
        await dotenv.load(fileName: '.env');
        pusherKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
        pusherCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? 'mt1';
      }

      if (pusherKey.isEmpty) {
        // ignore: avoid_print
        print('❌ PUSHER_APP_KEY no configurada en .env de Zonix');
        _isInitialized = false;
        _isConnected = false;
        return false;
      }

      _pusher = PusherChannelsFlutter.getInstance();

      final authUrl = '${AppConfig.apiUrl}/api/broadcasting/auth';
      await _pusher!.init(
        apiKey: pusherKey,
        cluster: pusherCluster,
        authEndpoint: authUrl,
        onAuthorizer: _onAuthorizer,
        onConnectionStateChange: _handleConnectionStateChange,
        onError: _handleError,
        onEvent: _handleEvent,
        onSubscriptionSucceeded: _handleSubscriptionSucceeded,
        onSubscriptionError: _handleSubscriptionError,
        onDecryptionFailure: _handleDecryptionFailure,
        onMemberAdded: _handleMemberAdded,
        onMemberRemoved: _handleMemberRemoved,
      );

      await _pusher!.connect();

      _isInitialized = true;
      // ignore: avoid_print
      print('✅ PusherService (Zonix) inicializado correctamente');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error inicializando Pusher (Zonix): $e');
      _isInitialized = false;
      _isConnected = false;
      return false;
    }
  }

  /// Authorizer para canales privados
  Future<Map<String, dynamic>?> _onAuthorizer(String channelName, String socketId, dynamic options) async {
    try {
      final authHeaders = await AuthHelper.getAuthHeaders();
      final url = '${AppConfig.apiUrl}/api/broadcasting/auth';
      
      final headers = {
        ...authHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      final body = 'channel_name=${Uri.encodeComponent(channelName)}&socket_id=${Uri.encodeComponent(socketId)}';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = decoded is Map
            ? Map<String, dynamic>.from(Map.from(decoded))
            : <String, dynamic>{};
        final Map<String, dynamic> payload = data.containsKey('data') && data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        if (!payload.containsKey('auth')) {
          return null;
        }
        payload['shared_secret'] = payload['shared_secret'] ?? '';
        return payload;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Pusher authorizer error: $e');
      return null;
    }
  }

  /// Suscribirse al canal de chat de una orden
  Future<bool> subscribeToOrderChat(int orderId) async {
    final channelName = 'private-orders.$orderId';
    return subscribeToChannel(channelName);
  }

  /// Suscribirse al canal de usuario
  Future<bool> subscribeToUserChannel(int userId) async {
    final channelName = 'private-user.$userId';
    return subscribeToChannel(channelName);
  }

  /// Suscribirse al canal de comercio
  Future<bool> subscribeToCommerceChannel(int commerceId) async {
    final channelName = 'private-commerce.$commerceId';
    return subscribeToChannel(channelName);
  }


  /// Suscribirse a un canal genérico (con conteo de referencias).
  Future<bool> subscribeToChannel(String channelName) async {
    final prev = _channelRefCount[channelName] ?? 0;
    _channelRefCount[channelName] = prev + 1;

    if (prev > 0) {
      // Ya había un suscriptor: el socket sigue en este canal.
      return true;
    }

    try {
      if (_pusher == null || !_isInitialized) {
        final ok = await initialize();
        if (!ok) {
          _channelRefCount[channelName] = 0;
          _channelRefCount.remove(channelName);
          return false;
        }
      }

      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
      // ignore: avoid_print
      print('✅ Suscrito a canal Pusher: $channelName');
      return true;
    } catch (e) {
      _channelRefCount.remove(channelName);
      // ignore: avoid_print
      print('❌ Error suscribiendo a canal Pusher ($channelName): $e');
      return false;
    }
  }

  /// Libera una referencia al canal; solo desuscribe en Pusher cuando el contador llega a 0.
  Future<void> unsubscribeFromChannel(String channelName) async {
    final prev = _channelRefCount[channelName] ?? 0;
    if (prev <= 0) return;

    final next = prev - 1;
    if (next > 0) {
      _channelRefCount[channelName] = next;
      return;
    }

    _channelRefCount.remove(channelName);

    if (_pusher == null || !_subscribedChannels.contains(channelName)) return;

    try {
      await _pusher!.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
      // ignore: avoid_print
      print('✅ Desuscrito de canal Pusher: $channelName');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error desuscribiendo de canal Pusher ($channelName): $e');
    }
  }

  void _handleConnectionStateChange(String currentState, String? previousState) {
    // ignore: avoid_print
    print('🔄 Pusher (Zonix) connection: $previousState → $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void _handleEvent(PusherEvent event) {
    try {
      final dynamic raw = event.data;
      final Map<String, dynamic> data = raw == null
          ? <String, dynamic>{}
          : (raw is String
              ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
              : Map<String, dynamic>.from(raw as Map));

      if (data.isNotEmpty) {
        _eventController.add({
          'eventName': event.eventName,
          'channelName': event.channelName,
          'data': data,
        });
        
        // ignore: avoid_print
        print('📡 Event broadcasted to stream: ${event.eventName} on ${event.channelName}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error procesando evento Pusher (Zonix): $e');
    }
  }

  void _handleError(String message, int? code, dynamic e) {
    // ignore: avoid_print
    print('❌ Pusher (Zonix) error: $message (code: $code)');
    _isConnected = false;
  }

  void _handleSubscriptionSucceeded(String channelName, dynamic data) {
    // ignore: avoid_print
    print('✅ Pusher (Zonix) suscripción exitosa: $channelName');
  }

  void _handleSubscriptionError(String message, dynamic e) {
    // ignore: avoid_print
    print('❌ Pusher (Zonix) error de suscripción: $message');
  }

  void _handleDecryptionFailure(String event, String reason) {
    // ignore: avoid_print
    print('❌ Pusher (Zonix) fallo de descifrado: $event - $reason');
  }

  void _handleMemberAdded(String channelName, PusherMember member) {
    // ignore: avoid_print
    print('👤 Pusher (Zonix) miembro agregado: ${member.userId} en $channelName');
  }

  void _handleMemberRemoved(String channelName, PusherMember member) {
    // ignore: avoid_print
    print('👤 Pusher (Zonix) miembro removido: ${member.userId} de $channelName');
  }

  Future<void> disconnect() async {
    try {
      for (final channel in _subscribedChannels.toList()) {
        await _pusher?.unsubscribe(channelName: channel);
      }
      _subscribedChannels.clear();
      _channelRefCount.clear();
      await _pusher?.disconnect();
      _isConnected = false;
      _isInitialized = false;
      // ignore: avoid_print
      print('🛑 PusherService (Zonix): desconectado');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error desconectando Pusher (Zonix): $e');
    }
  }
}
