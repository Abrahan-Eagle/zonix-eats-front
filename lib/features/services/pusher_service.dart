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

  // Canales suscritos (por ejemplo: profile.{id}, orders.{id}, etc.)
  final Set<String> _subscribedChannels = {};

  // Callback genérico para eventos de órdenes u otros eventos de dominio
  Function(String eventName, Map<String, dynamic> data)? _onDomainEvent;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Inicializa Pusher con credenciales desde `.env`
  /// Variables esperadas:
  /// - PUSHER_APP_KEY
  /// - PUSHER_APP_CLUSTER
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _isConnected;
    }

    try {
      final pusherKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
      final pusherCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? 'mt1';

      if (pusherKey.isEmpty) {
        // No rompemos la app si no está configurado: simplemente no conectamos
        // y dejamos que la app funcione solo con HTTP.
        // El dev verá este log en consola.
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

  /// Authorizer para canales privados (envía Bearer token a /api/broadcasting/auth)
  Future<Map<String, dynamic>?> _onAuthorizer(String channelName, String socketId, dynamic options) async {
    try {
      final authHeaders = await AuthHelper.getAuthHeaders();
      final headers = {
        ...authHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/broadcasting/auth'),
        headers: headers,
        body: 'channel_name=${Uri.encodeComponent(channelName)}&socket_id=${Uri.encodeComponent(socketId)}',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Pusher authorizer error: $e');
      return null;
    }
  }

  /// Suscribirse al canal de chat de una orden (private-order.{orderId})
  /// Para recibir mensajes en tiempo real vía Pusher.
  Future<bool> subscribeToOrderChat(
    int orderId, {
    required Function(String eventName, Map<String, dynamic> data) onNewMessage,
  }) async {
    final channelName = 'private-order.$orderId';
    return subscribeToChannel(channelName, onDomainEvent: onNewMessage);
  }

  /// Suscribirse a un canal genérico
  Future<bool> subscribeToChannel(
    String channelName, {
    required Function(String eventName, Map<String, dynamic> data) onDomainEvent,
  }) async {
    try {
      if (_pusher == null || !_isInitialized) {
        final ok = await initialize();
        if (!ok) return false;
      }

      _onDomainEvent = onDomainEvent;

      if (_subscribedChannels.contains(channelName)) {
        return true;
      }

      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
      // ignore: avoid_print
      print('✅ Suscrito a canal Pusher: $channelName');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error suscribiendo a canal Pusher ($channelName): $e');
      return false;
    }
  }

  /// Suscribirse a un canal de perfil para recibir eventos de órdenes/notificaciones
  ///
  /// Ejemplo de canal: `profile.{profileId}` o `user.{userId}` según definas en backend.
  Future<bool> subscribeToProfileChannel(
    String channelName, {
    required Function(String eventName, Map<String, dynamic> data) onDomainEvent,
  }) async {
    try {
      if (_pusher == null || !_isInitialized) {
        final ok = await initialize();
        if (!ok) return false;
      }

      _onDomainEvent = onDomainEvent;

      if (_subscribedChannels.contains(channelName)) {
        // ignore: avoid_print
        print('⚠️ Ya suscrito a canal Pusher: $channelName');
        return true;
      }

      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
      // ignore: avoid_print
      print('✅ Suscrito a canal Pusher: $channelName');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error suscribiendo a canal Pusher ($channelName): $e');
      return false;
    }
  }

  /// Desuscribirse de un canal Pusher
  Future<void> unsubscribeFromChannel(String channelName) async {
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

  /// Manejar cambios de estado de conexión
  void _handleConnectionStateChange(String currentState, String? previousState) {
    // ignore: avoid_print
    print('🔄 Pusher (Zonix) connection: $previousState → $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  /// Manejar eventos recibidos
  void _handleEvent(PusherEvent event) {
    // ignore: avoid_print
    print('📨 Pusher (Zonix) event: ${event.eventName} en ${event.channelName}');

    try {
      final dynamic raw = event.data;
      final Map<String, dynamic> data = raw == null
          ? <String, dynamic>{}
          : (raw is String
              ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
              : Map<String, dynamic>.from(raw as Map));

      if (_onDomainEvent != null && data.isNotEmpty) {
        _onDomainEvent!(event.eventName, data);
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error procesando evento Pusher (Zonix): $e');
    }
  }

  /// Manejar errores
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

  /// Desconectar completamente de Pusher
  Future<void> disconnect() async {
    try {
      for (final channel in _subscribedChannels.toList()) {
        await _pusher?.unsubscribe(channelName: channel);
      }
      _subscribedChannels.clear();
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

