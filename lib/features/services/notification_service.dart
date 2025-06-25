import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/notification_item.dart';
import 'dart:convert';

class NotificationService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'notifications';

  // Guardar una notificación
  static Future<void> saveNotification(NotificationItem notification) async {
    final list = await getNotifications();
    list.insert(0, notification); // Insertar al inicio (más reciente primero)
    final jsonList = list.map((n) => n.toJson()).toList();
    await _storage.write(key: _key, value: jsonEncode(jsonList));
  }

  // Obtener todas las notificaciones
  static Future<List<NotificationItem>> getNotifications() async {
    final jsonString = await _storage.read(key: _key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => NotificationItem.fromJson(e)).toList();
  }

  // Limpiar historial
  static Future<void> clearNotifications() async {
    await _storage.delete(key: _key);
  }
}
