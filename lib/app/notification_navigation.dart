import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import 'package:zonix/features/screens/commerce/commerce_order_detail_page.dart';
import 'package:zonix/features/screens/delivery/delivery_order_detail_page.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_orders_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/utils/user_provider.dart';

/// Llave global para navegar desde callbacks sin context (ej. al tocar notificación FCM).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navega según el payload de la notificación (order_id, type: order|chat|commerce_order).
void navigateFromNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    return;
  }
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>?;
    if (data == null) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      return;
    }
    final orderId = data['order_id'] != null ? int.tryParse(data['order_id'].toString()) : null;
    final type = data['type']?.toString() ?? '';
    final ctx = navigatorKey.currentContext;
    final role = ctx != null
        ? Provider.of<UserProvider>(ctx, listen: false).userRole
        : '';

    if (orderId != null && orderId > 0) {
      if (type == 'commerce_order') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => CommerceOrderDetailPage(orderId: orderId),
        ));
      } else if (type == 'chat') {
        navigateToChatByRole(orderId, data);
      } else if (role == 'delivery_company') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => DeliveryCompanyOrdersPage(highlightOrderId: orderId),
        ));
      } else if (role == 'delivery_agent' || role == 'delivery') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => DeliveryOrderDetailLoaderPage(orderId: orderId),
        ));
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: orderId, order: null),
        ));
      }
    } else {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
    }
  } catch (_) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }
}

/// Abre la pantalla de chat correcta según el rol del usuario autenticado.
void navigateToChatByRole(int orderId, Map<String, dynamic> data) {
  final ctx = navigatorKey.currentContext;
  final role = ctx != null
      ? Provider.of<UserProvider>(ctx, listen: false).userRole
      : '';
  final senderName = data['sender_name']?.toString() ?? '';

  if (role == 'commerce') {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => CommerceChatMessagesPage(
        orderId: orderId,
        customerName: senderName.isNotEmpty ? senderName : 'Cliente',
      ),
    ));
  } else if (role == 'delivery_agent' || role == 'delivery') {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => CommerceChatMessagesPage(
        orderId: orderId,
        customerName: senderName.isNotEmpty ? senderName : 'Cliente',
      ),
    ));
  } else if (role == 'delivery_company') {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => DeliveryCompanyOrdersPage(highlightOrderId: orderId),
    ));
  } else {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => BuyerOrderChatPage(orderId: orderId),
    ));
  }
}

/// Navega desde un RemoteMessage (app abierta desde notificación en background/terminated).
void navigateFromRemoteMessageData(Map<String, dynamic> data) {
  if (data.isEmpty) {
    navigateFromNotificationPayload(null);
    return;
  }
  navigateFromNotificationPayload(jsonEncode(data));
}
