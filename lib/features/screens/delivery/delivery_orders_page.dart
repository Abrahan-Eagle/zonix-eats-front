import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/notification_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/realtime_event_utils.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/widgets/app_skeleton.dart';
import 'package:zonix/features/screens/delivery/delivery_order_detail_page.dart';
import 'package:zonix/features/screens/delivery/qr_scanner_page.dart';

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({super.key});

  @override
  DeliveryOrdersPageState createState() => DeliveryOrdersPageState();
}

class DeliveryOrdersPageState extends State<DeliveryOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWorking = false;
  bool _loadingWorking = true;

  bool _pusherSubscribed = false;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;
  String? _pusherChannel;
  Timer? _debounceTimer;
  /// Tras [_loadAll] manual o bootstrap; evita segundo refresh si Pusher dispara por el mismo cambio (~aceptar orden).
  DateTime? _lastOrdersLoadAt;

  /// Evita dos cargas en paralelo (aceptar orden + Pusher / doble listener): una sola ronda de GET.
  Future<void>? _loadAllInFlight;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapDeliveryTab());
  }

  Future<void> _bootstrapDeliveryTab() async {
    if (!mounted) return;
    final d = context.read<DeliveryService>();
    // Show cached orders instantly while bootstrap runs
    await d.loadCachedOrders();
    await d.getMyAgentId();
    if (!mounted) return;
    await syncDeliverySessionAfterApi(context, d);
    if (!mounted) return;
    if (!context.read<UserProvider>().isAuthenticated) return;
    await _loadAll();
    if (!mounted) return;
    if (!context.read<UserProvider>().isAuthenticated) return;
    await _loadWorkingStatus();
    if (!mounted) return;
    await _subscribeToPusher();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _pusherSub?.cancel();
    if (_pusherSubscribed && _pusherChannel != null) {
      PusherService.instance.unsubscribeFromChannel(_pusherChannel!);
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_loadAllInFlight != null) {
      return _loadAllInFlight!;
    }
    _loadAllInFlight = _loadAllImpl();
    try {
      await _loadAllInFlight!;
    } finally {
      _loadAllInFlight = null;
    }
  }

  Future<void> _loadAllImpl() async {
    if (!mounted) return;
    final d = context.read<DeliveryService>();
    try {
      await Future.wait([d.loadMyOrders(), d.loadAvailableOrders()]);
      _lastOrdersLoadAt = DateTime.now();
    } catch (e) {
      debugPrint('Error cargando órdenes delivery: $e');
    }
    if (!mounted) return;
    await syncDeliverySessionAfterApi(context, d);
  }

  static const _debounceCoalesceWindow = Duration(milliseconds: 750);

  void _debouncedLoadAll() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final last = _lastOrdersLoadAt;
      if (last != null && DateTime.now().difference(last) < _debounceCoalesceWindow) {
        return;
      }
      _loadAll();
    });
  }

  Future<void> _loadWorkingStatus() async {
    final service = context.read<DeliveryService>();
    try {
      final working = await service.getWorkingStatus();
      if (mounted) setState(() { _isWorking = working; _loadingWorking = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingWorking = false; });
    }
  }

  Future<void> _toggleWorking(bool value) async {
    final service = context.read<DeliveryService>();
    setState(() { _isWorking = value; });
    final ok = await service.updateWorking(value);
    if (!ok && mounted) {
      setState(() { _isWorking = !value; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar disponibilidad')),
      );
    }
  }

  Future<void> _subscribeToPusher() async {
    if (!AppConfig.enablePusher || _pusherSubscribed || !mounted) return;
    try {
      final service = context.read<DeliveryService>();
      final agentId = await service.getMyAgentId();
      if (agentId == null || !mounted) return;

      final channel = 'private-delivery.$agentId';
      _pusherChannel = channel;
      final ok = await PusherService.instance.subscribeToChannel(channel);
      if (ok && mounted) {
        _pusherSub?.cancel();
        _pusherSub = PusherService.instance.eventStream.listen((event) {
          final rawEventName =
              event['canonicalEventName']?.toString() ??
              event['eventName']?.toString() ??
              '';
          final eventName = RealtimeEventUtils.normalizeEventName(rawEventName);
          final channelName = event['channelName']?.toString() ?? '';
          if (channelName != channel) return;
          if (eventName.contains('OrderStatusChanged')) {
            HapticFeedback.lightImpact();
            _debouncedLoadAll();
          }
        });
        _pusherSubscribed = true;
      }
    } catch (e) {
      debugPrint('Error suscribiendo Pusher delivery: $e');
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar orden'),
        content: Text('¿Aceptar la orden #${order['order_number'] ?? order['id']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Aceptar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = context.read<DeliveryService>();
    try {
      final orderId = order['id'] is int ? order['id'] as int : int.parse(order['id'].toString());
      await service.acceptOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden aceptada')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  int _orderId(Map<String, dynamic> order) {
    final id = order['id'];
    if (id is int) return id;
    return int.parse(id.toString());
  }

  Future<void> _openScanQr(Map<String, dynamic> order, String scanType) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => QrScannerPage(orderId: _orderId(order), scanType: scanType),
      ),
    );
    if (mounted) _loadAll();
  }

  Future<void> _arrivedAndScan(Map<String, dynamic> order) async {
    final service = context.read<DeliveryService>();
    final ok = await service.notifyArrived(_orderId(order));
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente notificado. Escanea su QR.')),
      );
      _openScanQr(order, 'delivery');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al notificar llegada.')),
      );
    }
  }

  Future<void> _goToDetail(Map<String, dynamic> order) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DeliveryOrderDetailPage(order: order),
      ),
    );
    if (mounted) _loadAll();
  }

  // --- Status helpers ---

  Color _statusColor(String status, bool hasDelivery) {
    switch (status) {
      case 'processing':
        return hasDelivery ? AppColors.orange : AppColors.textMutedGray;
      case 'shipped':
        return hasDelivery ? AppColors.blue : AppColors.orange;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.textMutedGray;
    }
  }

  String _statusLabel(String status, bool hasDelivery) {
    switch (status) {
      case 'processing':
        return 'Preparando';
      case 'shipped':
        return hasDelivery ? 'En camino' : 'Disponible';
      case 'delivered':
        return 'Entregada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status, bool hasDelivery) {
    switch (status) {
      case 'processing':
        return hasDelivery ? Icons.qr_code_2 : Icons.restaurant;
      case 'shipped':
        return hasDelivery ? Icons.delivery_dining : Icons.assignment;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis entregas'),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notifService, _) => IconButton(
              icon: Badge(
                label: Text(notifService.unreadCount.toString()),
                isLabelVisible: notifService.unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadAll()),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Mis órdenes'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildWorkingToggle(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildMyOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.grayLight,
        border: Border(bottom: BorderSide(color: AppColors.textMutedGray.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(
            _isWorking ? Icons.delivery_dining : Icons.pause_circle_outline,
            color: _isWorking ? AppColors.green : AppColors.textMutedGray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isWorking ? 'Disponible para entregas' : 'No disponible',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isWorking ? AppColors.green : AppColors.textMutedGray,
              ),
            ),
          ),
          if (_loadingWorking)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: _isWorking,
              onChanged: _toggleWorking,
              activeThumbColor: AppColors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab() {
    return Consumer<DeliveryService>(
      builder: (context, service, _) {
        if (service.isLoading && service.availableOrdersMaps.isEmpty) {
          return AppSkeleton.list(count: 4, cardHeight: 160);
        }
        if (service.error != null && service.availableOrdersMaps.isEmpty) {
          return _buildErrorState(service.error!, () => service.loadAvailableOrders());
        }
        if (service.availableOrdersMaps.isEmpty) {
          return _buildEmptyState('No hay órdenes disponibles', Icons.inbox);
        }
        return RefreshIndicator(
          onRefresh: () => service.loadAvailableOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.availableOrdersMaps.length,
            itemBuilder: (context, index) {
              final order = service.availableOrdersMaps[index];
              return _buildAvailableCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyOrdersTab() {
    return Consumer<DeliveryService>(
      builder: (context, service, _) {
        if (service.isLoading && service.myOrders.isEmpty) {
          return AppSkeleton.list(count: 4, cardHeight: 180);
        }
        if (service.error != null && service.myOrders.isEmpty) {
          return _buildErrorState(service.error!, () => service.loadMyOrders());
        }
        if (service.myOrders.isEmpty) {
          return _buildEmptyState('No tienes órdenes asignadas', Icons.delivery_dining);
        }
        return RefreshIndicator(
          onRefresh: () => service.loadMyOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.myOrders.length,
            itemBuilder: (context, index) {
              final order = service.myOrders[index];
              return _buildMyOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> order) {
    final commerce = order['commerce'] as Map<String, dynamic>?;
    final commerceName = commerce?['name']?.toString() ?? 'Comercio';
    final address = order['delivery_address']?.toString() ?? order['shipping_address']?.toString() ?? 'Sin dirección';
    final total = _parseDouble(order['total']);
    final orderNumber = order['order_number']?.toString() ?? '#${order['id']}';
    final itemCount = (order['order_items'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment, color: AppColors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Orden $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(commerceName, style: const TextStyle(color: AppColors.gray, fontSize: 14)),
                    ],
                  ),
                ),
                _buildStatusChip('Disponible', AppColors.orange),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.store, 'Recoger en', commerceName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Entregar en', address),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoRow(Icons.shopping_bag, 'Productos', '$itemCount items')),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(order),
                icon: const Icon(Icons.check, color: AppColors.white, size: 24),
                label: const Text('Aceptar orden', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final hasDelivery = order['order_delivery'] != null;
    final commerce = order['commerce'] as Map<String, dynamic>?;
    final commerceName = commerce?['name']?.toString() ?? 'Comercio';
    final profile = order['profile'] as Map<String, dynamic>?;
    final user = profile?['user'] as Map<String, dynamic>?;
    final customerName = '${user?['name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    final address = order['delivery_address']?.toString() ?? order['shipping_address']?.toString() ?? 'Sin dirección';
    final total = _parseDouble(order['total']);
    final orderNumber = order['order_number']?.toString() ?? '#${order['id']}';
    final canScanPickup = status == 'processing' && hasDelivery;
    final canNotifyArrived = status == 'shipped' && hasDelivery;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _goToDetail(order),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor(status, hasDelivery).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_statusIcon(status, hasDelivery), color: _statusColor(status, hasDelivery)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Orden $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (customerName.isNotEmpty)
                        Text(customerName, style: const TextStyle(color: AppColors.gray, fontSize: 14)),
                    ],
                  ),
                ),
                _buildStatusChip(_statusLabel(status, hasDelivery), _statusColor(status, hasDelivery)),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.store, 'Comercio', commerceName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Dirección', address),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoRow(Icons.access_time, 'Creada', _formatDate(order['created_at']?.toString() ?? ''))),
                Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (canScanPickup)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _openScanQr(order, 'pickup'),
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.white, size: 24),
                  label: const Text('Escanear QR recogida', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else if (canNotifyArrived)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _arrivedAndScan(order),
                  icon: const Icon(Icons.location_on, color: AppColors.white, size: 24),
                  label: const Text('Llegué al destino', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _goToDetail(order),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver detalle', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMutedGray),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text('Error: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: retry, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
