import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:zonix/features/screens/orders/buyer_order_chat_page.dart';
import 'package:zonix/features/screens/orders/delivery_detail_page.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/widgets/payment_timeline.dart';
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
  Map<String, dynamic>? _deliveryAgent;
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;

  static const Color _primary = AppColors.blue;
  static const Color _accent = AppColors.amber;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _subscribeToTracking();
    _loadInitialTracking();
    if (_isTrackableStatus(widget.order.status)) {
      _loadDeliveryAgent();
    }
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    if (_trackingSubscribed) {
      PusherService.instance
          .unsubscribeFromChannel('private-orders.${widget.orderId}');
    }
    super.dispose();
  }

  Future<void> _subscribeToTracking() async {
    if (_order == null || _trackingSubscribed) {
      return;
    }
    final s = _order!.status;
    if (s == 'shipped' ||
        s == 'out_for_delivery' ||
        s == 'processing' ||
        s == 'paid' ||
        s == 'pending_payment') {
      final ok = await PusherService.instance.subscribeToOrderChat(widget.orderId);
      
      if (ok && mounted) {
        _pusherSubscription?.cancel();
        _pusherSubscription = PusherService.instance.eventStream.listen((event) {
          final eventName = event['eventName']?.toString() ?? '';
          final channelName = event['channelName']?.toString() ?? '';
          final eventData = event['data'] is Map<String, dynamic>
              ? event['data'] as Map<String, dynamic>
              : <String, dynamic>{};

          if (channelName == 'private-orders.${widget.orderId}') {
            if (eventName.contains('DeliveryLocationUpdated')) {
              final lat = double.tryParse(eventData['latitude']?.toString() ?? '');
              final lng = double.tryParse(eventData['longitude']?.toString() ?? '');
              if (lat != null && lng != null && mounted) {
                setState(() {
                  _deliveryLat = lat;
                  _deliveryLng = lng;
                });
                _recalculateRoute(lat, lng);
              }
            }
            if ((eventName.contains('OrderStatusChanged') ||
                 eventName.contains('PaymentValidated')) && mounted) {
              _refreshOrder();
            }
          }
        });
        _trackingSubscribed = true;
      }
    }
  }

  Future<void> _loadInitialTracking() async {
    if (_order == null || !_isTrackableStatus(_order!.status)) {
      return;
    }
    try {
      final data = await OrderService().getOrderTracking(widget.orderId);
      final lat = data['latitude'] is double
          ? data['latitude'] as double
          : (data['latitude'] != null
              ? double.tryParse(data['latitude'].toString())
              : null);
      final lng = data['longitude'] is double
          ? data['longitude'] as double
          : (data['longitude'] != null
              ? double.tryParse(data['longitude'].toString())
              : null);
      final clat = data['customer_latitude'] is double
          ? data['customer_latitude'] as double
          : (data['customer_latitude'] != null
              ? double.tryParse(data['customer_latitude'].toString())
              : null);
      final clng = data['customer_longitude'] is double
          ? data['customer_longitude'] as double
          : (data['customer_longitude'] != null
              ? double.tryParse(data['customer_longitude'].toString())
              : null);
      List<LatLng> route = [];
      final routeRaw = data['route_to_customer'];
      if (routeRaw is List) {
        for (final p in routeRaw) {
          if (p is Map) {
            final plat = (p['lat'] is num)
                ? (p['lat'] as num).toDouble()
                : double.tryParse(p['lat']?.toString() ?? '');
            final plng = (p['lng'] is num)
                ? (p['lng'] as num).toDouble()
                : double.tryParse(p['lng']?.toString() ?? '');
            if (plat != null && plng != null) {
              route.add(LatLng(plat, plng));
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          if (lat != null) {
            _deliveryLat = lat;
          }
          if (lng != null) {
            _deliveryLng = lng;
          }
          if (clat != null) {
            _customerLat = clat;
          }
          if (clng != null) {
            _customerLng = clng;
          }
          if (route.isNotEmpty) {
            _routePoints = route;
          }
        });
      }
    } catch (_) {}
  }

  bool _isTrackableStatus(String s) =>
      s == 'shipped' ||
      s == 'out_for_delivery' ||
      s == 'processing' ||
      s == 'paid';

  Future<void> _refreshOrder() async {
    try {
      final order = await OrderService().getOrderById(widget.orderId);
      if (mounted) {
        setState(() => _order = order);
        if (_isTrackableStatus(order.status)) {
          if (!_trackingSubscribed) _subscribeToTracking();
          if (_deliveryAgent == null) _loadDeliveryAgent();
          _loadInitialTracking();
        }
      }
    } catch (_) {}
  }

  Future<void> _recalculateRoute(double agentLat, double agentLng) async {
    if (_customerLat == null || _customerLng == null) return;
    try {
      final result = await LocationService().calculateRoute(
        originLat: agentLat,
        originLng: agentLng,
        destinationLat: _customerLat!,
        destinationLng: _customerLng!,
      );
      final polyline = result['polyline'] as List?;
      if (polyline != null && mounted) {
        final points = <LatLng>[];
        for (final p in polyline) {
          if (p is Map) {
            final plat = (p['lat'] is num) ? (p['lat'] as num).toDouble() : double.tryParse(p['lat']?.toString() ?? '');
            final plng = (p['lng'] is num) ? (p['lng'] as num).toDouble() : double.tryParse(p['lng']?.toString() ?? '');
            if (plat != null && plng != null) points.add(LatLng(plat, plng));
          }
        }
        if (points.length >= 2 && mounted) {
          setState(() => _routePoints = points);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDeliveryAgent() async {
    try {
      final data =
          await OrderService().getDeliveryAgentForOrder(widget.orderId);
      if (mounted) {
        setState(() => _deliveryAgent = data);
      }
    } catch (_) {}
  }

  int _progressStep(Order order) {
    final s = order.status.toLowerCase();
    switch (s) {
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
      case 'on_way':
        return 2;
      case 'delivered':
        return 3;
      default:
        // Fallback por si el backend envía otro valor (ej. "en camino")
        if (s.contains('camino') ||
            s.contains('shipped') ||
            s.contains('delivery')) {
          return 2;
        }
        if (s.contains('prepar') ||
            s.contains('process') ||
            s.contains('ready')) {
          return 1;
        }
        if (s.contains('entreg') || s.contains('delivered')) {
          return 3;
        }
        return 0;
    }
  }

  String _etaMessage(Order order) {
    if (order.status == 'pending_payment' || order.status == 'pending') {
      return 'Sube tu comprobante de pago para que el comercio confirme tu orden.';
    }
    if (order.status == 'processing' || order.status == 'preparing') {
      return 'Se está preparando tu pedido';
    }
    if (order.status == 'shipped' || order.status == 'out_for_delivery') {
      if (order.isPickup) return 'Tu pedido está listo para recoger';
      final m = order.estimatedDeliveryMinutes;
      if (m != null && m > 0) return 'Llegada estimada en ~$m min';
      return 'Tu pedido va en camino';
    }
    if (order.status == 'delivered') {
      return order.isPickup ? '¡Pedido recogido!' : '¡Pedido entregado!';
    }
    return order.isPickup ? 'Tu pedido se está preparando' : 'Tu pedido está en camino';
  }

  String _etaTime(Order order) {
    final m = order.estimatedDeliveryMinutes;
    if (m != null && m > 0) {
      return '~$m';
    }
    return 'Calculando...';
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http')) {
      return path;
    }
    final base = AppConfig.apiUrl.replaceAll('/api', '');
    return path.startsWith('/') ? '$base$path' : '$base/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.cardBg(context) : AppColors.white;
    final primary = isDark ? AppColors.accentButton(context) : _primary;
    final borderColor =
        isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.grayLight;
    final backgroundLight =
        isDark ? AppColors.backgroundDark : AppColors.grayLight;
    final textPrimary = AppColors.primaryText(context);
    final textSecondary = AppColors.secondaryText(context);

    final order = _order ?? widget.order;
    final orderNumber =
        order.orderNumber.isNotEmpty ? order.orderNumber : '${order.id}';

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
                context, orderNumber, primary, textPrimary, textSecondary),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOrder,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusSection(order, surfaceColor, borderColor,
                          primary, textPrimary, textSecondary),
                      if (order.status == 'pending_payment' ||
                          order.status == 'pending') ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          child: PaymentTimeline(
                            currentStep: PaymentTimeline.stepFromOrder(
                              status: order.status,
                              approvedForPayment: order.approvedForPayment,
                              hasPaymentProof: order.paymentProof != null && order.paymentProof!.isNotEmpty,
                              isPaymentValidated: order.paymentValidatedAt != null,
                            ),
                            createdAt: order.createdAt,
                            compact: true,
                          ),
                        ),
                        _buildPendingPaymentCard(context, order, surfaceColor,
                            borderColor, primary, textPrimary),
                      ],
                      if (order.isDeliveryOrder) ...[
                        _buildMapSection(
                            order, primary, surfaceColor, borderColor, isDark),
                        _buildDeliveryPersonCard(surfaceColor, borderColor,
                            primary, textPrimary, textSecondary),
                      ],
                      if (order.isPickup)
                        _buildPickupInfoCard(order, surfaceColor, borderColor,
                            primary, textPrimary, textSecondary),
                      _buildAddressCard(order, surfaceColor, borderColor,
                          textPrimary, textSecondary),
                      _buildOrderSummary(order, surfaceColor, borderColor,
                          primary, textPrimary, textSecondary),
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

  Widget _buildHeader(BuildContext context, String orderNumber, Color primary,
      Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.black26
            : AppColors.white.withValues(alpha: 0.9),
        border: Border(
            bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.1))),
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
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary),
                ),
                Text(
                  'Orden #$orderNumber',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HelpAndFAQPage(),
                ),
              );
            },
            icon: Icon(Icons.help_outline, color: primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Order order, Color surfaceColor, Color borderColor,
      Color primary, Color textPrimary, Color textSecondary) {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.statusText.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step >= 2
                          ? (order.isPickup ? 'Listo para recoger' : '¡Ya casi llega!')
                          : (step == 1 ? 'En preparación' : 'Recibido'),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _etaMessage(order),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _etaTime(order),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  ),
                  Text(
                    order.isPickup ? 'TIEMPO EST.' : 'LLEGADA EST.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressBar(step, primary, textSecondary, order),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentCard(BuildContext context, Order order,
      Color surfaceColor, Color borderColor, Color primary, Color textPrimary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pendiente de pago',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sube tu comprobante de pago y elige el método de pago en la pantalla de detalle.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailPage(
                      orderId: order.id,
                      order: order,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text('Subir comprobante de pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, Color primary, Color textMuted, Order order) {
    final labels = order.isPickup
        ? const ['RECIBIDO', 'PREPARACIÓN', 'LISTO', 'RECOGIDO']
        : const ['RECIBIDO', 'PREPARACIÓN', 'EN CAMINO', 'ENTREGADO'];
    final icons = order.isPickup
        ? const [Icons.check, Icons.restaurant, Icons.storefront, Icons.shopping_bag]
        : const [Icons.check, Icons.restaurant, Icons.two_wheeler, Icons.inventory_2];
    Widget circle(int i) {
      final done = i < currentStep;
      final active = i == currentStep;
      return Container(
        width: active ? 40 : 32,
        height: active ? 40 : 32,
        decoration: BoxDecoration(
          color: done || active ? primary : textMuted.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          boxShadow: active
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.3), blurRadius: 8)
                ]
              : null,
        ),
        child: Icon(icons[i],
            size: active ? 20 : 16,
            color: (done || active) ? AppColors.white : textMuted),
      );
    }

    // Etiquetas: completados y activo en primary; pendientes en textMuted
    Color labelColor(int i) => (i <= currentStep) ? primary : textMuted;
    return Row(
      children: [
        Column(children: [
          circle(0),
          const SizedBox(height: 6),
          Text(labels[0],
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: labelColor(0)))
        ]),
        Expanded(
            child: Center(
                child: Container(
                    height: 2,
                    color: currentStep > 0
                        ? primary
                        : textMuted.withValues(alpha: 0.3)))),
        Column(children: [
          circle(1),
          const SizedBox(height: 6),
          Text(labels[1],
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: labelColor(1)))
        ]),
        Expanded(
            child: Center(
                child: Container(
                    height: 2,
                    color: currentStep > 1
                        ? primary
                        : textMuted.withValues(alpha: 0.3)))),
        Column(children: [
          circle(2),
          const SizedBox(height: 6),
          Text(labels[2],
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: labelColor(2)))
        ]),
        Expanded(
            child: Center(
                child: Container(
                    height: 2,
                    color: currentStep > 2
                        ? primary
                        : textMuted.withValues(alpha: 0.3)))),
        Column(children: [
          circle(3),
          const SizedBox(height: 6),
          Text(labels[3],
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: labelColor(3)))
        ]),
      ],
    );
  }

  Widget _buildMapSection(Order order, Color primary, Color surfaceColor,
      Color borderColor, bool isDark) {
    final hasLocation = _deliveryLat != null && _deliveryLng != null;
    final hasDestination = _customerLat != null && _customerLng != null;
    final center = hasLocation
        ? LatLng(_deliveryLat!, _deliveryLng!)
        : (hasDestination
            ? LatLng(_customerLat!, _customerLng!)
            : const LatLng(19.4326, -99.1332));
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
        color: AppColors.green,
        size: 32,
      ));
    }
    List<LatLng>? polyline;
    if (_routePoints.isNotEmpty) {
      polyline = _routePoints;
    } else if (hasLocation && hasDestination) {
      polyline = [
        LatLng(_deliveryLat!, _deliveryLng!),
        LatLng(_customerLat!, _customerLng!)
      ];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grayDark : AppColors.grayLight,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black26, blurRadius: 8)
                            ],
                          ),
                          child: Text(
                            'Tu repartidor está cerca',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, fontWeight: FontWeight.bold),
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
                      Icon(Icons.map_outlined,
                          size: 48, color: primary.withValues(alpha: 0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'Esperando ubicación del repartidor...',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Botón para ir a la pantalla "Tu repartidor" (vista separada). No duplica contenido.
  Widget _buildDeliveryPersonCard(Color surfaceColor, Color borderColor,
      Color primary, Color textPrimary, Color textSecondary) {
    final order = _order ?? widget.order;
    final commerceName = order.commerce?['name']?.toString() ?? 'Comercio';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DeliveryDetailPage(
                        orderId: widget.orderId,
                        commerceName: commerceName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining, color: primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Ver tu repartidor',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: textSecondary),
                  ],
                ),
              ),
            ),
            IconButton(
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
              style: IconButton.styleFrom(
                  backgroundColor: primary.withValues(alpha: 0.15),
                  foregroundColor: primary),
              icon: const Icon(Icons.chat_bubble_outline, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupInfoCard(Order order, Color surfaceColor,
      Color borderColor, Color primary, Color textPrimary, Color textSecondary) {
    final commerceName = order.commerceName.isNotEmpty
        ? order.commerceName
        : 'el comercio';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.storefront, color: primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Retiro en tienda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recoge tu pedido en $commerceName cuando esté listo.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Order order, Color surfaceColor, Color borderColor,
      Color textPrimary, Color textSecondary) {
    final address = order.isPickup
        ? (order.commerceAddress.isNotEmpty
            ? order.commerceAddress
            : (order.commerceName.isNotEmpty ? order.commerceName : '—'))
        : (order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress);
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.grayDark
                  : AppColors.grayLight,
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
                  order.isPickup ? 'RECOGER EN' : 'DIRECCIÓN DE ENTREGA',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order, Color surfaceColor, Color borderColor,
      Color primary, Color textPrimary, Color textSecondary) {
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
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
          ),
          const Divider(height: 1),
          ...order.items.map((item) {
            final img = item.productImage.isNotEmpty
                ? _imageUrl(item.productImage)
                : null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img != null
                        ? Image.network(img,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(56))
                        : _placeholder(56),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x ${item.productName}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                        if (item.specialInstructions != null &&
                            item.specialInstructions!.isNotEmpty)
                          Text(
                            item.specialInstructions!,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white.withValues(alpha: 0.05)
                : AppColors.grayLight,
            child: Column(
              children: [
                _summaryRow('Subtotal', order.subtotal, textSecondary),
                const SizedBox(height: 10),
                _summaryRow(
                  order.isPickup ? 'Retiro en tienda' : 'Costo de envío',
                  order.deliveryFee,
                  textSecondary,
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    Text('\$${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primary)),
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
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: textSecondary)),
        Text('\$${value.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: textSecondary)),
      ],
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.borderLight,
      child: Icon(Icons.person, color: AppColors.gray, size: size * 0.5),
    );
  }
}
