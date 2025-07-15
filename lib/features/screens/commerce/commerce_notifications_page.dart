import 'package:flutter/material.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/models/notification_item.dart';
import 'package:zonix/features/services/websocket_service.dart';
import '../../../services/commerce_profile_service.dart';
import 'dart:async';

class CommerceNotificationsPage extends StatefulWidget {
  const CommerceNotificationsPage({Key? key}) : super(key: key);

  @override
  State<CommerceNotificationsPage> createState() => _CommerceNotificationsPageState();
}

class _CommerceNotificationsPageState extends State<CommerceNotificationsPage> {
  late Future<List<NotificationItem>> _notificationsFuture;
  StreamSubscription? _wsSubscription;
  final CommerceProfileService _profileService = CommerceProfileService();
  int? _commerceId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _initWebSocket();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _loadNotifications() {
    if (!mounted) return;
    setState(() {
      _notificationsFuture = NotificationService().getNotificationItems();
    });
  }

  Future<void> _initWebSocket() async {
    try {
      final profile = await _profileService.fetchProfile();
      _commerceId = profile.id;
      await WebSocketService().connect();
      await WebSocketService().subscribeToCommerce(_commerceId!);
      _wsSubscription = WebSocketService().messageStream?.listen((event) {
        if (event['type'] == 'order_created' || event['type'] == 'order_status_changed' || event['type'] == 'payment_validated' || event['type'] == 'notification') {
          _loadNotifications();
          if (mounted && event['type'] == 'notification') {
            final title = event['data']?['title'] ?? 'Nueva notificación';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(title)),
            );
          }
        }
      });
    } catch (e) {
      // Ignorar errores de conexión
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: RefreshIndicator(
        onRefresh: () async => _loadNotifications(),
        child: FutureBuilder<List<NotificationItem>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay notificaciones'));
            }
            final notifications = snapshot.data!;
            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    '${n.receivedAt.hour.toString().padLeft(2, '0')}:${n.receivedAt.minute.toString().padLeft(2, '0')}\n${n.receivedAt.day}/${n.receivedAt.month}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 