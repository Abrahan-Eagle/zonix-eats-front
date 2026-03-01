import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.order,
  });

  final int orderId;
  final Order? order;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  double? _deliveryLat;
  double? _deliveryLng;
  bool _trackingSubscribed = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      _loadOrder();
    } else {
      _loading = false;
      _subscribeToTracking();
    }
  }

  @override
  void dispose() {
    if (_trackingSubscribed) {
      PusherService.instance.unsubscribeFromChannel('private-order.${widget.orderId}');
    }
    super.dispose();
  }

  void _subscribeToTracking() {
    if (_order == null || _trackingSubscribed) return;
    final s = _order!.status;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'processing') {
      PusherService.instance.subscribeToOrderChat(
        widget.orderId,
        onNewMessage: (eventName, data) {
          if (eventName.contains('DeliveryLocationUpdated')) {
            final lat = double.tryParse(data['latitude']?.toString() ?? '');
            final lng = double.tryParse(data['longitude']?.toString() ?? '');
            if (lat != null && lng != null && mounted) {
              setState(() {
                _deliveryLat = lat;
                _deliveryLng = lng;
              });
            }
          }
          if (eventName.contains('OrderStatusChanged')) {
            _loadOrder();
          }
        },
      );
      _trackingSubscribed = true;
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await OrderService().getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
        _subscribeToTracking();
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

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    String? paymentMethod;
    String? referenceNumber;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UploadProofDialog(),
    );
    if (result == null || !mounted) return;

    paymentMethod = result['method'];
    referenceNumber = result['ref'];
    if (paymentMethod == null || paymentMethod.isEmpty ||
        referenceNumber == null || referenceNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes ingresar método de pago y número de referencia')),
        );
      }
      return;
    }

    setState(() => _updating = true);
    try {
      await OrderService().uploadPaymentProof(
        widget.orderId,
        file.path,
        'jpeg',
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
      );
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante subido correctamente'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: const Text('¿Estás seguro de que deseas cancelar esta orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await OrderService().cancelOrder(widget.orderId, reason: 'Cancelación por usuario');
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden cancelada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base/storage/$path' : '$base/storage/$path';
  }

  bool get _canCancel {
    if (_order == null) return false;
    if (_order!.status != 'pending_payment') return false;
    final limit = _order!.createdAt.add(const Duration(minutes: 5));
    return DateTime.now().isBefore(limit);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de orden')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de orden')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error ?? 'Orden no encontrada', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${order.id}'),
        backgroundColor: AppColors.headerGradientStart(context),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat con el comercio',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyerOrderChatPage(
                    orderId: order.id,
                    commerceName: order.commerce?['business_name']?.toString() ?? 'Comercio',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _updating
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrder,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(order),
                    const SizedBox(height: 16),
                    _buildProductsCard(order),
                    const SizedBox(height: 16),
                    _buildTotalsCard(order),
                    if (order.deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAddressCard(order),
                    ],
                    if (_isTrackableStatus(order.status)) ...[
                      const SizedBox(height: 16),
                      _buildTrackingCard(order),
                    ],
                    if (order.status == 'pending_payment') ...[
                      const SizedBox(height: 24),
                      _buildPendingPaymentActions(order),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(order.status)),
              ),
              child: Text(
                order.statusText,
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.productImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productImage.startsWith('http')
                                ? item.productImage
                                : _imageUrl(item.productImage),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fastfood),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.secondaryText(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TotalRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
            if (order.deliveryFee > 0)
              _TotalRow('Envío', '\$${order.deliveryFee.toStringAsFixed(2)}'),
            const Divider(height: 20),
            _TotalRow('Total', '\$${order.total.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirección de entrega',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentActions(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pendiente de pago',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _uploadProof,
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir comprobante de pago'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentButton(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar orden'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  bool _isTrackableStatus(String status) {
    return status == 'shipped' || status == 'out_for_delivery' || status == 'processing' || status == 'paid';
  }

  Widget _buildTrackingCard(Order order) {
    final hasLocation = _deliveryLat != null && _deliveryLng != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: AppColors.green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Seguimiento de entrega',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasLocation)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: OsmMapWidget(
                    center: LatLng(_deliveryLat!, _deliveryLng!),
                    zoom: 15.0,
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Esperando ubicación del repartidor...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Ver en Google Maps'),
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps?q=$_deliveryLat,$_deliveryLng',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'pending_payment':
        return Colors.orange;
      case 'paid':
      case 'processing':
      case 'shipped':
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _TotalRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.green : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadProofDialog extends StatefulWidget {
  const _UploadProofDialog();

  @override
  State<_UploadProofDialog> createState() => _UploadProofDialogState();
}

class _UploadProofDialogState extends State<_UploadProofDialog> {
  final _refController = TextEditingController();
  String _selectedMethod = 'transferencia';

  static const List<String> _methods = [
    'efectivo',
    'transferencia',
    'tarjeta',
    'pago_movil',
    'otro',
  ];

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subir comprobante'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa los datos del pago realizado:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(_methodLabel(m))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMethod = v ?? 'transferencia'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Número de referencia / transacción',
                border: OutlineInputBorder(),
                hintText: 'Ej: REF123456',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final ref = _refController.text.trim();
            if (ref.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa número de referencia')),
              );
              return;
            }
            Navigator.pop(context, {'method': _selectedMethod, 'ref': ref});
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      case 'pago_movil':
        return 'Pago móvil';
      default:
        return m;
    }
  }
}
