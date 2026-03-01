import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_notification_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceNotificationsPage extends StatefulWidget {
  const CommerceNotificationsPage({super.key});

  @override
  State<CommerceNotificationsPage> createState() =>
      _CommerceNotificationsPageState();
}

class _CommerceNotificationsPageState extends State<CommerceNotificationsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = CommerceNotificationService();
      final list = await service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              try {
                final service = CommerceNotificationService();
                await service.markAllAsRead();
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todas marcadas como leídas'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              } catch (_) {}
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay notificaciones'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, i) {
                  final n = _notifications[i] is Map
                      ? _notifications[i] as Map
                      : <String, dynamic>{};
                  return ListTile(
                    leading: Icon(
                      _iconForType(n['type']?.toString()),
                      color: n['read_at'] == null ? AppColors.blue : Colors.grey,
                    ),
                    title: Text(n['title'] ?? 'Notificación'),
                    subtitle: Text(n['body'] ?? ''),
                    isThreeLine: true,
                    onTap: () async {
                      final id = n['id'];
                      if (id != null) {
                        try {
                          final service = CommerceNotificationService();
                          await service.markAsRead(id);
                          await _loadData();
                        } catch (_) {}
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'order':
        return Icons.receipt;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }
}
