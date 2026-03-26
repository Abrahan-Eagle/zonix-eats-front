import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/screens/delivery/qr_scanner_page.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';

class DeliveryOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryOrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryOrderDetailPage> createState() => _DeliveryOrderDetailPageState();
}

class _DeliveryOrderDetailPageState extends State<DeliveryOrderDetailPage> {
  bool _notifyingArrival = false;
  late Map<String, dynamic> _order;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;
  bool _pusherSubscribed = false;

  int _orderId(Map<String, dynamic> o) {
    final id = o['id'];
    if (id is int) return id;
    return int.parse(id.toString());
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribePusher());
  }

  @override
  void dispose() {
    _unsubscribePusher();
    super.dispose();
  }

  Future<void> _subscribePusher() async {
    if (!AppConfig.enablePusher || _pusherSubscribed || !mounted) return;
    final orderId = _orderId(_order);
    final channel = 'private-orders.$orderId';
    final ok = await PusherService.instance.subscribeToOrderChat(orderId);
    if (ok && mounted) {
      _pusherSub?.cancel();
      _pusherSub = PusherService.instance.eventStream.listen((event) {
        final eventName = event['eventName']?.toString() ?? '';
        final channelName = event['channelName']?.toString() ?? '';
        if (channelName == channel && eventName.contains('OrderStatusChanged') && mounted) {
          _reloadOrder();
        }
      });
      _pusherSubscribed = true;
    }
  }

  void _unsubscribePusher() {
    _pusherSub?.cancel();
    _pusherSub = null;
    if (_pusherSubscribed) {
      final orderId = _orderId(_order);
      PusherService.instance.unsubscribeFromChannel('private-orders.$orderId');
      _pusherSubscribed = false;
    }
  }

  Future<void> _reloadOrder() async {
    final service = context.read<DeliveryService>();
    final updated = await service.getOrderById(_orderId(_order));
    if (updated != null && mounted) {
      setState(() => _order = updated);
    }
  }

  Future<void> _openScanAndPop(BuildContext context, int orderId, String scanType) async {
    final navigator = Navigator.of(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => QrScannerPage(orderId: orderId, scanType: scanType),
      ),
    );
    if (ok == true && mounted) {
      navigator.pop(true);
    }
  }

  Future<void> _arrivedAndScan(int orderId) async {
    setState(() => _notifyingArrival = true);
    final service = context.read<DeliveryService>();
    final ok = await service.notifyArrived(orderId);
    if (!mounted) return;
    setState(() => _notifyingArrival = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente notificado. Escanea su QR.')),
      );
      _openScanAndPop(context, orderId, 'delivery');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al notificar llegada. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = order['status']?.toString() ?? '';
    final hasDelivery = order['order_delivery'] != null;
    final commerce = order['commerce'] as Map<String, dynamic>?;
    final commerceName = commerce?['name']?.toString() ?? 'Comercio';
    final commerceAddress = commerce?['address']?.toString() ?? '';
    final profile = order['profile'] as Map<String, dynamic>?;
    final user = profile?['user'] as Map<String, dynamic>?;
    final customerName = '${user?['name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    final customerPhone = profile?['phone']?.toString() ?? user?['phone']?.toString() ?? '';
    final deliveryAddress = order['delivery_address']?.toString() ?? order['shipping_address']?.toString() ?? 'Sin dirección';
    final total = _parseDouble(order['total']);
    final deliveryFee = _parseDouble(order['delivery_fee']);
    final subtotal = _parseDouble(order['subtotal']);
    final orderNumber = order['order_number']?.toString() ?? '#${order['id']}';
    final items = order['order_items'] as List? ?? [];
    final orderId = _orderId(order);
    final canScanPickup = status == 'processing' && hasDelivery;
    final canNotifyArrived = status == 'shipped' && hasDelivery;
    final notes = order['notes']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final etaMin = safeInt(order['estimated_delivery_time'], 0);
    final hasEta = etaMin > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden $orderNumber'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status, hasDelivery),
            if (hasEta) ...[
              const SizedBox(height: 12),
              Text(
                'ETA para el cliente: ~$etaMin min',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
              ),
            ],
            const SizedBox(height: 20),

            _buildSection(
              context,
              icon: Icons.store,
              title: 'Comercio',
              isDark: isDark,
              children: [
                _buildRow('Nombre', commerceName),
                if (commerceAddress.isNotEmpty) _buildRow('Dirección', commerceAddress),
              ],
            ),
            const SizedBox(height: 12),

            _buildSection(
              context,
              icon: Icons.person,
              title: 'Cliente',
              isDark: isDark,
              children: [
                if (customerName.isNotEmpty) _buildRow('Nombre', customerName),
                if (customerPhone.isNotEmpty) _buildRow('Teléfono', customerPhone),
                _buildRow('Dirección entrega', deliveryAddress),
              ],
            ),
            const SizedBox(height: 12),

            _buildSection(
              context,
              icon: Icons.shopping_bag,
              title: 'Productos (${items.length})',
              isDark: isDark,
              children: items.map<Widget>((item) {
                final product = item['product'] as Map<String, dynamic>?;
                final productName = product?['name']?.toString() ?? 'Producto';
                final qty = item['quantity']?.toString() ?? '1';
                final price = _parseDouble(item['price']);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${qty}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(productName)),
                      Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            if (notes.isNotEmpty) ...[
              _buildSection(
                context,
                icon: Icons.notes,
                title: 'Notas',
                isDark: isDark,
                children: [Text(notes)],
              ),
              const SizedBox(height: 12),
            ],

            _buildSection(
              context,
              icon: Icons.receipt_long,
              title: 'Resumen',
              isDark: isDark,
              children: [
                if (subtotal > 0) _buildRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                if (deliveryFee > 0) _buildRow('Delivery fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                const Divider(),
                _buildRow('Total', '\$${total.toStringAsFixed(2)}', bold: true),
              ],
            ),
            const SizedBox(height: 24),

            if (canScanPickup) ...[
              const Text(
                'En el comercio, pide el comerciante que muestre el código QR de recogida y escanéalo.',
                style: TextStyle(color: AppColors.grayDark, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openScanAndPop(context, orderId, 'pickup'),
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.white),
                  label: const Text('Escanear QR de recogida', style: TextStyle(color: AppColors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (canNotifyArrived) ...[
              const Text(
                'Cuando llegues al domicilio del cliente, toca el botón para notificarle y escanear su QR de entrega.',
                style: TextStyle(color: AppColors.grayDark, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _notifyingArrival ? null : () => _arrivedAndScan(orderId),
                  icon: _notifyingArrival
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.location_on, color: AppColors.white),
                  label: Text(
                    _notifyingArrival ? 'Notificando...' : 'Llegué al destino',
                    style: const TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status, bool hasDelivery) {
    final color = _statusColor(status, hasDelivery);
    final label = _statusLabel(status, hasDelivery);
    final icon = _statusIcon(status, hasDelivery);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMutedGray.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gray),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
          ),
        ],
      ),
    );
  }

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
        return hasDelivery ? 'Preparando — escanea QR en el comercio' : 'Preparando';
      case 'shipped':
        return hasDelivery ? 'En camino — notifica al llegar' : 'Disponible';
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

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Carga una orden por ID y muestra [DeliveryOrderDetailPage]. Usado desde FCM.
class DeliveryOrderDetailLoaderPage extends StatefulWidget {
  final int orderId;

  const DeliveryOrderDetailLoaderPage({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailLoaderPage> createState() => _DeliveryOrderDetailLoaderPageState();
}

class _DeliveryOrderDetailLoaderPageState extends State<DeliveryOrderDetailLoaderPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final service = context.read<DeliveryService>();
    final order = await service.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
      _error = order == null ? 'No se pudo cargar la orden' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orden')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Orden no encontrada'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }
    return DeliveryOrderDetailPage(order: _order!);
  }
}
