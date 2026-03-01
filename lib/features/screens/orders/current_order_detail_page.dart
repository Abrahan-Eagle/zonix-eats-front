import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/orders/delivery_detail_page.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:latlong2/latlong.dart';

/// Pantalla "Detalle del Pedido" para **pedidos actuales** (en curso).
/// Template: status, progreso, mapa, repartidor, dirección, resumen. Dark/Light.
class CurrentOrderDetailPage extends StatefulWidget {
  const CurrentOrderDetailPage({
    super.key,
    required this.orderId,
    required this.order,
  });

  final int orderId;
  final Order order;

  @override
  State<CurrentOrderDetailPage> createState() => _CurrentOrderDetailPageState();
}

class _CurrentOrderDetailPageState extends State<CurrentOrderDetailPage> {
  Order? _order;
  double? _deliveryLat;
  double? _deliveryLng;
  double? _customerLat;
  double? _customerLng;
  List<LatLng> _routePoints = [];
  bool _trackingSubscribed = false;

  static const Color _primary = Color(0xFF3399FF);
  static const Color _accent = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _subscribeToTracking();
    _loadInitialTracking();
  }

  @override
  void dispose() {
    if (_trackingSubscribed) {
      PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    }
    super.dispose();
  }

  void _subscribeToTracking() {
    if (_order == null || _trackingSubscribed) return;
    final s = _order!.status;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'processing' || s == 'paid') {
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
          if (eventName.contains('OrderStatusChanged') && mounted) {
            _refreshOrder();
          }
        },
      );
      _trackingSubscribed = true;
    }
  }

  Future<void> _loadInitialTracking() async {
    if (_order == null || !_isTrackableStatus(_order!.status)) return;
    try {
      final data = await OrderService().getOrderTracking(widget.orderId);
      final lat = data['latitude'] is double ? data['latitude'] as double : (data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null);
      final lng = data['longitude'] is double ? data['longitude'] as double : (data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null);
      final clat = data['customer_latitude'] is double ? data['customer_latitude'] as double : (data['customer_latitude'] != null ? double.tryParse(data['customer_latitude'].toString()) : null);
      final clng = data['customer_longitude'] is double ? data['customer_longitude'] as double : (data['customer_longitude'] != null ? double.tryParse(data['customer_longitude'].toString()) : null);
      List<LatLng> route = [];
      final routeRaw = data['route_to_customer'];
      if (routeRaw is List) {
        for (final p in routeRaw) {
          if (p is Map) {
            final plat = (p['lat'] is num) ? (p['lat'] as num).toDouble() : double.tryParse(p['lat']?.toString() ?? '');
            final plng = (p['lng'] is num) ? (p['lng'] as num).toDouble() : double.tryParse(p['lng']?.toString() ?? '');
            if (plat != null && plng != null) route.add(LatLng(plat, plng));
          }
        }
      }
      if (mounted) {
        setState(() {
          if (lat != null) _deliveryLat = lat;
          if (lng != null) _deliveryLng = lng;
          if (clat != null) _customerLat = clat;
          if (clng != null) _customerLng = clng;
          if (route.isNotEmpty) _routePoints = route;
        });
      }
    } catch (_) {}
  }

  bool _isTrackableStatus(String s) =>
      s == 'shipped' || s == 'out_for_delivery' || s == 'processing' || s == 'paid';

  Future<void> _refreshOrder() async {
    try {
      final order = await OrderService().getOrderById(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (_) {}
  }

  int _progressStep(Order order) {
    switch (order.status) {
      case 'pending_payment':
      case 'pending':
      case 'paid':
        return 0;
      case 'processing':
      case 'preparing':
      case 'ready':
        return 1;
      case 'shipped':
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  String _etaMessage(Order order) {
    if (order.status == 'shipped' || order.status == 'out_for_delivery') {
      return 'Tu pedido aterrizará en 8-12 min';
    }
    if (order.status == 'processing' || order.status == 'preparing') {
      return 'Se está preparando tu pedido';
    }
    return 'Tu pedido está en camino';
  }

  String _etaTime(Order order) {
    final t = order.estimatedDeliveryTime;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardBg(context) : Colors.white;
    final primary = isDark ? AppColors.accentButton(context) : _primary;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final backgroundLight = isDark ? const Color(0xFF0f1923) : const Color(0xFFf5f7f8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    final order = _order ?? widget.order;
    final orderNumber = order.orderNumber.isNotEmpty ? order.orderNumber : '${order.id}';

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, orderNumber, primary, textPrimary, textSecondary),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOrder,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusSection(order, surfaceColor, borderColor, primary, textPrimary, textSecondary),
                      _buildMapSection(order, primary, surfaceColor, borderColor, isDark),
                      _buildDeliveryPersonCard(surfaceColor, borderColor, primary, textPrimary, textSecondary),
                      _buildAddressCard(order, surfaceColor, borderColor, textPrimary, textSecondary),
                      _buildOrderSummary(order, surfaceColor, borderColor, primary, textPrimary, textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String orderNumber, Color primary, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del Pedido',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                Text(
                  'Orden #$orderNumber',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: ayuda/soporte
            },
            icon: Icon(Icons.help_outline, color: primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Order order, Color surfaceColor, Color borderColor, Color primary, Color textPrimary, Color textSecondary) {
    final step = _progressStep(order);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.statusText.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: _accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step >= 2 ? '¡Ya casi llega!' : (step == 1 ? 'En preparación' : 'Recibido'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _etaMessage(order),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _etaTime(order),
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
                  ),
                  Text(
                    'LLEGADA EST.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressBar(step, primary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, Color primary, Color textMuted) {
    const labels = ['RECIBIDO', 'PREPARACIÓN', 'EN CAMINO', 'ENTREGADO'];
    const icons = [Icons.check, Icons.restaurant, Icons.two_wheeler, Icons.inventory_2];
    Widget circle(int i) {
      final done = i < currentStep;
      final active = i == currentStep;
      return Container(
        width: active ? 40 : 32,
        height: active ? 40 : 32,
        decoration: BoxDecoration(
          color: done || active ? primary : textMuted.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          boxShadow: active ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: Icon(icons[i], size: active ? 20 : 16, color: (done || active) ? Colors.white : textMuted),
      );
    }
    return Row(
      children: [
        Column(children: [circle(0), const SizedBox(height: 6), Text(labels[0], style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: currentStep == 0 ? primary : textMuted))]),
        Expanded(child: Center(child: Container(height: 2, color: currentStep > 0 ? primary : textMuted.withValues(alpha: 0.3)))),
        Column(children: [circle(1), const SizedBox(height: 6), Text(labels[1], style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: currentStep == 1 ? primary : textMuted))]),
        Expanded(child: Center(child: Container(height: 2, color: currentStep > 1 ? primary : textMuted.withValues(alpha: 0.3)))),
        Column(children: [circle(2), const SizedBox(height: 6), Text(labels[2], style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: currentStep == 2 ? primary : textMuted))]),
        Expanded(child: Center(child: Container(height: 2, color: currentStep > 2 ? primary : textMuted.withValues(alpha: 0.3)))),
        Column(children: [circle(3), const SizedBox(height: 6), Text(labels[3], style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: currentStep == 3 ? primary : textMuted))]),
      ],
    );
  }

  Widget _buildMapSection(Order order, Color primary, Color surfaceColor, Color borderColor, bool isDark) {
    final hasLocation = _deliveryLat != null && _deliveryLng != null;
    final hasDestination = _customerLat != null && _customerLng != null;
    final center = hasLocation
        ? LatLng(_deliveryLat!, _deliveryLng!)
        : (hasDestination ? LatLng(_customerLat!, _customerLng!) : const LatLng(19.4326, -99.1332));
    final markers = <Marker>[];
    if (hasLocation) {
      markers.add(MapMarker.create(
        point: LatLng(_deliveryLat!, _deliveryLng!),
        iconData: Icons.two_wheeler,
        color: primary,
        size: 36,
      ));
    }
    if (hasDestination) {
      markers.add(MapMarker.create(
        point: LatLng(_customerLat!, _customerLng!),
        iconData: Icons.location_on,
        color: Colors.green,
        size: 32,
      ));
    }
    List<LatLng>? polyline;
    if (_routePoints.isNotEmpty) {
      polyline = _routePoints;
    } else if (hasLocation && hasDestination) {
      polyline = [LatLng(_deliveryLat!, _deliveryLng!), LatLng(_customerLat!, _customerLng!)];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            border: Border.all(color: borderColor),
          ),
          child: hasLocation
              ? Stack(
                  children: [
                    OsmMapWidget(
                      center: center,
                      zoom: 14,
                      height: 220,
                      markers: markers.isEmpty ? null : markers,
                      polylinePoints: polyline,
                      polylineColor: primary,
                      polylineStrokeWidth: 4,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: Text(
                            'Tu repartidor está cerca',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: primary.withValues(alpha: 0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'Esperando ubicación del repartidor...',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonCard(Color surfaceColor, Color borderColor, Color primary, Color textPrimary, Color textSecondary) {
    final order = _order ?? widget.order;
    final commerceName = order.commerce?['name']?.toString() ?? 'Comercio';
    const deliveryName = 'Repartidor asignado';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeliveryDetailPage(
                  orderId: widget.orderId,
                  deliveryName: deliveryName,
                  deliveryRating: '4.8',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: primary.withValues(alpha: 0.15),
                      child: Icon(Icons.delivery_dining, color: primary, size: 32),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: Colors.white),
                            const SizedBox(width: 2),
                            Text('4.8', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu repartidor', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary)),
                      Text(deliveryName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BuyerOrderChatPage(
                          orderId: widget.orderId,
                          commerceName: commerceName,
                        ),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(backgroundColor: primary.withValues(alpha: 0.15), foregroundColor: primary),
                  icon: const Icon(Icons.chat_bubble_outline, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(Order order, Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final address = order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIRECCIÓN DE ENTREGA',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order, Color surfaceColor, Color borderColor, Color primary, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Resumen de la Orden',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ),
          const Divider(height: 1),
          ...order.items.map((item) {
            final img = item.productImage.isNotEmpty ? _imageUrl(item.productImage) : null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img != null
                        ? Image.network(img, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(56))
                        : _placeholder(56),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x ${item.productName}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        if (item.specialInstructions != null && item.specialInstructions!.isNotEmpty)
                          Text(
                            item.specialInstructions!,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            child: Column(
              children: [
                _summaryRow('Subtotal', order.subtotal, textSecondary),
                const SizedBox(height: 10),
                _summaryRow('Costo de envío', order.deliveryFee, textSecondary),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                    Text('\$${order.total.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textSecondary)),
        Text('\$${value.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textSecondary)),
      ],
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: Icon(Icons.restaurant, color: Colors.grey.shade600, size: size * 0.5),
    );
  }
}
