import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zonix/app/fcm_hooks.dart';
import 'package:zonix/app/notification_navigation.dart';

final Logger _fcmLogger = Logger();

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

/// ID del canal de notificaciones (sonido + vibración).
const String fcmNotificationChannelId = 'zonix_eats_fcm';
const String fcmNotificationChannelName = 'Notificaciones Zonix Eats';
DateTime? _lastForegroundLocalNotificationAt;

/// true = usa res/raw/zonix_notification.mp3; false = sonido por defecto del sistema.
const bool _useCustomNotificationSound = true;

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

AndroidNotificationChannel _buildFcmChannel() {
  return const AndroidNotificationChannel(
    fcmNotificationChannelId,
    fcmNotificationChannelName,
    description: 'Notificaciones push de pedidos y mensajes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: _useCustomNotificationSound ? RawResourceAndroidNotificationSound('zonix_notification') : null,
  );
}

AndroidNotificationDetails _buildFcmNotificationDetails() {
  return const AndroidNotificationDetails(
    fcmNotificationChannelId,
    fcmNotificationChannelName,
    channelDescription: 'Notificaciones push de pedidos y mensajes',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    showWhen: true,
    sound: _useCustomNotificationSound ? RawResourceAndroidNotificationSound('zonix_notification') : null,
  );
}

/// Crea el canal de notificaciones con sonido y vibración (Android).
Future<void> _createFcmNotificationChannel() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;
  await androidPlugin.createNotificationChannel(_buildFcmChannel());
}

/// Muestra una notificación local con sonido, vibración y [payload] para navegación al tocar.
Future<void> _showFcmNotification({
  required String title,
  required String body,
  int id = 0,
  String? payload,
}) async {
  final details = NotificationDetails(android: _buildFcmNotificationDetails());
  await _localNotifications.show(id, title, body, details, payload: payload);
}

/// Acceso público para que NotificationService pueda mostrar notificación local con sonido
/// cuando llega un evento Pusher (backup cuando FCM no está disponible).
Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await _showFcmNotification(title: title, body: body, id: id, payload: payload);
}

/// Inicializa notificaciones locales (canal con sonido y vibración).
Future<void> initLocalNotifications() async {
  if (kIsWeb) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.isNotEmpty) {
        navigateFromNotificationPayload(response.payload);
      } else {
        navigateFromNotificationPayload(null);
      }
    },
  );
  await _createFcmNotificationChannel();
}

/// Handler de mensajes FCM en segundo plano (debe ser función top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _fcmLogger.i('FCM background: ${message.messageId}');

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: android));
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(_buildFcmChannel());
  }
  final title = message.notification?.title ?? message.data['title'] ?? 'Zonix Eats';
  final body = message.notification?.body ?? message.data['body'] ?? 'Nueva notificación';
  final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
  await plugin.show(
    message.hashCode % 0x7FFFFFFF,
    title,
    body,
    NotificationDetails(android: _buildFcmNotificationDetails()),
    payload: payload,
  );
}

/// Solicita permiso de notificaciones, obtiene el token FCM y lo guarda en almacenamiento seguro.
Future<void> initFcmToken() async {
  if (kIsWeb) return;
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        _fcmLogger.w('FCM: permiso de notificaciones no concedido');
        return;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        _fcmLogger.w('FCM: permiso iOS no concedido');
        return;
      }
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: 'fcm_token', value: token);
      _fcmLogger.i('FCM token guardado');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        await _secureStorage.write(key: 'fcm_token', value: newToken);
        _fcmLogger.i('FCM token actualizado');
      }
    });
  } catch (e) {
    _fcmLogger.w('FCM init error: $e');
  }
}

/// Registra listeners FCM de foreground / opened app (llamar tras [Firebase.initializeApp]).
void registerFcmForegroundListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Zonix Eats';
    final body = message.notification?.body ?? message.data['body'] ?? 'Nueva notificación';
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    final now = DateTime.now();
    if (_lastForegroundLocalNotificationAt == null ||
        now.difference(_lastForegroundLocalNotificationAt!).inSeconds >= 2) {
      _showFcmNotification(
        title: title,
        body: body,
        id: message.hashCode % 0x7FFFFFFF,
        payload: payload,
      );
      _lastForegroundLocalNotificationAt = now;
    }
    onFcmForegroundUnreadBump?.call();
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigateFromRemoteMessageData(message.data);
  });
}
