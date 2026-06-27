import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zonix_glasses/features/screens/notifications/notifications_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navega según payload genérico de notificación (`type` + `entity_id` opcional).
void navigateFromNotificationPayload(String? payload) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  if (payload == null || payload.isEmpty) {
    nav.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    return;
  }

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>?;
    if (data == null) {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      return;
    }
    // Scaffold: por ahora todas las notificaciones abren el centro de notificaciones.
    nav.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  } catch (_) {
    nav.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }
}

void navigateFromRemoteMessageData(Map<String, dynamic> data) {
  if (data.isEmpty) {
    navigateFromNotificationPayload(null);
    return;
  }
  navigateFromNotificationPayload(jsonEncode(data));
}
