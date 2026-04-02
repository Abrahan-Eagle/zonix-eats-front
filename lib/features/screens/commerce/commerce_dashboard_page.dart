import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/features/services/commerce_order_service.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/realtime_event_utils.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import '../../utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/screens/commerce/commerce_promotions_page.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/services/notification_service.dart';

class CommerceDashboardPage extends StatefulWidget {
  const CommerceDashboardPage({
    super.key,
    this.initialProfile,
    this.initialUnreadNotifications,
  });

  final dynamic initialProfile;
  final int? initialUnreadNotifications;

  @override
  State<CommerceDashboardPage> createState() => _CommerceDashboardPageState();
}

class _CommerceDashboardPageState extends State<CommerceDashboardPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentOrders = [];
  bool _commerceOpen = false;
  int _commerceId = 0;
  String _commerceStatus = 'approved';
  bool _pusherSubscribed = false;
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pusherSubscription?.cancel();
    if (_pusherSubscribed && _commerceId > 0) {
      PusherService.instance.unsubscribeFromChannel('private-commerce.$_commerceId');
    }
    super.dispose();
  }

  Future<void> _subscribeToCommerceUpdates() async {
    if (!AppConfig.enablePusher || _commerceId <= 0 || !mounted) return;
    final ok = await PusherService.instance.subscribeToCommerceChannel(_commerceId);
    
    if (ok && mounted) {
      _pusherSubscription?.cancel();
      _pusherSubscription = PusherService.instance.eventStream.listen((event) {
        final rawEventName =
            event['canonicalEventName']?.toString() ??
            event['eventName']?.toString() ??
            '';
        final eventName = RealtimeEventUtils.normalizeEventName(rawEventName);
        final channelName = event['channelName']?.toString() ?? '';

        if (channelName == 'private-commerce.$_commerceId') {
          if ((eventName.contains('OrderStatusChanged') ||
                  eventName.contains('OrderCreated') ||
                  eventName.contains('PaymentValidated')) &&
              mounted) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted) _loadData();
            });
          }
        }
      });
      _pusherSubscribed = true;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ProfileService().getMyProfile();
      if (profile == null) throw Exception('Perfil no encontrado');

      try {
        final commerceData = await CommerceDataService.getCommerceData();
        _commerceOpen = commerceData['open'] == true;
        _commerceId = commerceData['id'] ?? 0;
        _commerceStatus = (commerceData['status'] ?? 'approved').toString();
      } catch (_) {
        _commerceOpen = false;
        _commerceId = 0;
        _commerceStatus = 'approved';
      }

      if (!mounted) return;
      final commerceService = Provider.of<CommerceService>(context, listen: false);
      final stats = await commerceService.getCommerceStatistics(_commerceId);
      if (!mounted) return;
      List<dynamic> recent = stats['recent_orders'] as List<dynamic>? ?? [];
      if (recent.isEmpty) {
        final orders = await CommerceOrderService.getOrders(perPage: 5);
        if (!mounted) return;
        recent = orders.map((o) => {
          'id': o.id,
          'status': o.status,
          'total': o.total,
          'customer_name': o.customerName,
          'created_at': o.createdAt.toIso8601String(),
          'items_count': o.itemCount,
        }).toList();
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentOrders = recent;
          _loading = false;
        });
        _subscribeToCommerceUpdates();
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

  Future<void> _toggleCommerceOpen(bool value) async {
    try {
      await CommerceDataService.updateCommerceData({'open': value});
      if (mounted) {
        setState(() => _commerceOpen = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Comercio abierto' : 'Comercio cerrado'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'processing':
        return AppColors.orange;
      case 'shipped':
        return AppColors.blue;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.gray;
    }
  }

  String _statusText(String status) {
    const map = {
      'pending_payment': 'Pend. pago',
      'paid': 'Pagado',
      'processing': 'Preparando',
      'shipped': 'Enviado',
      'delivered': 'Entregado',
      'cancelled': 'Cancelado',
    };
    return map[status] ?? status;
  }

  /// Acepta total desde API como num o String (JSON suele devolver números como string).
  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
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
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return IconButton(
                icon: Badge(
                  label: Text(notificationService.unreadCount.toString()),
                  isLabelVisible: notificationService.unreadCount > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_commerceStatus != 'approved')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _commerceStatus == 'rejected'
                        ? AppColors.red.withValues(alpha: 0.1)
                        : _commerceStatus == 'suspended'
                            ? AppColors.orange.withValues(alpha: 0.1)
                            : AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _commerceStatus == 'rejected'
                          ? AppColors.red.withValues(alpha: 0.3)
                          : _commerceStatus == 'suspended'
                              ? AppColors.orange.withValues(alpha: 0.3)
                              : AppColors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _commerceStatus == 'rejected'
                            ? Icons.cancel_outlined
                            : _commerceStatus == 'suspended'
                                ? Icons.pause_circle_outline
                                : Icons.hourglass_top,
                        color: _commerceStatus == 'rejected'
                            ? AppColors.red
                            : _commerceStatus == 'suspended'
                                ? AppColors.orange
                                : AppColors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _commerceStatus == 'pending_review'
                              ? 'Tu comercio está en revisión. Puedes configurar todo mientras el administrador aprueba tu solicitud.'
                              : _commerceStatus == 'rejected'
                                  ? 'Tu solicitud fue rechazada. Contacta soporte para más información.'
                                  : 'Tu comercio está suspendido temporalmente.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _commerceOpen ? 'Comercio abierto' : 'Comercio cerrado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _commerceOpen ? AppColors.green : AppColors.red,
                      ),
                    ),
                    Switch(
                      value: _commerceOpen,
                      onChanged: _toggleCommerceOpen,
                      activeThumbColor: AppColors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pendientes',
                    value: '${_stats['pending_orders'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Órdenes hoy',
                    value: '${_stats['today_orders'] ?? 0}',
                    icon: Icons.receipt,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Ingresos hoy',
                    value: '\$${_parseNum(_stats['today_revenue']).toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Productos activos',
                    value: '${_stats['active_products'] ?? 0}',
                    icon: Icons.inventory,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Últimas órdenes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_recentOrders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppColors.gray),
                        SizedBox(height: 8),
                        Text(
                          'No hay órdenes recientes',
                          style: TextStyle(color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...(_recentOrders).map((o) {
                final order = o is Map ? o : {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      order['customer_name'] ?? 'Cliente',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '\$${_parseNum(order['total']).toStringAsFixed(2)} · ${_statusText(order['status'] ?? '')}',
                    ),
                    trailing: Chip(
                      label: Text(
                        _statusText(order['status'] ?? ''),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: _statusColor(order['status'] ?? ''),
                      labelStyle: const TextStyle(color: AppColors.white),
                    ),
                    onTap: () async {
                      final id = order['id'];
                      if (id != null) {
                        await Navigator.pushNamed(context, '/commerce/order/$id');
                        if (mounted) _loadData();
                      }
                    },
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    onTap: () => Navigator.pushNamed(context, '/commerce/chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person,
                    label: 'Mi perfil',
                    onTap: () => Navigator.pushNamed(context, '/commerce/profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.campaign,
                    label: 'Promociones',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommercePromotionsPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.orange, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
