import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/screens/delivery/qr_scanner_page.dart';
import 'package:zonix/features/services/delivery_location_tracker.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';

class DeliveryOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryOrderDetailPage({super.key, required this.order});

  @override
  State<DeliveryOrderDetailPage> createState() => _DeliveryOrderDetailPageState();
}

class _DeliveryOrderDetailPageState extends State<DeliveryOrderDetailPage> {
  bool _notifyingArrival = false;
  late Map<String, dynamic> _order;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;
  bool _pusherSubscribed = false;

  // Map state
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _agentPosition;
  double? _routeDistanceKm;
  int? _routeEtaMin;
  bool _routeLoading = false;
  StreamSubscription<LatLng>? _gpsSub;
  DeliveryLocationTracker? _tracker;

  int _orderId(Map<String, dynamic> o) {
    final id = o['id'];
    if (id is int) return id;
    return int.parse(id.toString());
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribePusher();
      _initGpsAndRoute();
    });
  }

  @override
  void dispose() {
    _unsubscribePusher();
    _gpsSub?.cancel();
    _tracker?.dispose();
    super.dispose();
  }

  // --- Pusher ---

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
      PusherService.instance.unsubscribeFromChannel('private-orders.${_orderId(_order)}');
      _pusherSubscribed = false;
    }
  }

  Future<void> _reloadOrder() async {
    final service = context.read<DeliveryService>();
    final updated = await service.getOrderById(_orderId(_order));
    if (updated != null && mounted) {
      setState(() => _order = updated);
      _loadRoute();
    }
  }

  // --- GPS + Route ---

  void _initGpsAndRoute() {
    _tracker = DeliveryLocationTracker(context.read<DeliveryService>(), intervalSeconds: 20);
    _gpsSub = _tracker!.positionStream.listen((pos) {
      if (mounted) setState(() => _agentPosition = pos);
    });

    final status = _order['status']?.toString() ?? '';
    final hasDelivery = _order['order_delivery'] != null;
    if (hasDelivery && (status == 'processing' || status == 'shipped')) {
      _tracker!.start();
    }

    _tracker!.fetchNow().then((_) {
      if (mounted) _loadRoute();
    });
  }

  Future<void> _loadRoute() async {
    final dest = _currentDestination();
    if (dest == null || _agentPosition == null) return;
    setState(() => _routeLoading = true);

    try {
      final locService = LocationService();
      final result = await locService.calculateRoute(
        originLat: _agentPosition!.latitude,
        originLng: _agentPosition!.longitude,
        destinationLat: dest.latitude,
        destinationLng: dest.longitude,
      );
      if (!mounted) return;
      final polyline = result['polyline'] as List?;
      final points = <LatLng>[];
      if (polyline != null) {
        for (final p in polyline) {
          if (p is Map) {
            final lat = _dbl(p['lat']);
            final lng = _dbl(p['lng']);
            if (lat != 0 && lng != 0) points.add(LatLng(lat, lng));
          }
        }
      }
      setState(() {
        _routePoints = points;
        _routeDistanceKm = _dbl(result['distance']);
        _routeEtaMin = (result['duration'] is num) ? (result['duration'] as num).toInt() : null;
        _routeLoading = false;
      });
      _fitMap();
    } catch (e) {
      debugPrint('Route load error: $e');
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  LatLng? _currentDestination() {
    final status = _order['status']?.toString() ?? '';
    if (status == 'processing') {
      final commerce = _order['commerce'] as Map<String, dynamic>?;
      final lat = _dbl(commerce?['latitude']);
      final lng = _dbl(commerce?['longitude']);
      if (lat != 0 && lng != 0) return LatLng(lat, lng);
    }
    final lat = _dbl(_order['delivery_latitude']);
    final lng = _dbl(_order['delivery_longitude']);
    if (lat != 0 && lng != 0) return LatLng(lat, lng);
    return null;
  }

  void _fitMap() {
    final points = <LatLng>[];
    if (_agentPosition != null) points.add(_agentPosition!);
    final dest = _currentDestination();
    if (dest != null) points.add(dest);
    if (points.length >= 2) {
      try {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
      } catch (_) {}
    } else if (points.length == 1) {
      _mapController.move(points.first, 15);
    }
  }

  Future<void> _openGoogleMapsNav() async {
    final dest = _currentDestination();
    if (dest == null) return;
    final gNav = Uri.parse('google.navigation:q=${dest.latitude},${dest.longitude}&mode=d');
    if (await canLaunchUrl(gNav)) {
      await launchUrl(gNav);
    } else {
      final web = Uri.parse('${AppConfig.googleMapsDirUrl}&destination=${dest.latitude},${dest.longitude}');
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  // --- Actions ---

  Future<void> _openScanAndPop(BuildContext context, int orderId, String scanType) async {
    final navigator = Navigator.of(context);
    final ok = await Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => QrScannerPage(orderId: orderId, scanType: scanType)));
    if (ok == true && mounted) navigator.pop(true);
  }

  Future<void> _arrivedAndScan(int orderId) async {
    setState(() => _notifyingArrival = true);
    final service = context.read<DeliveryService>();
    final ok = await service.notifyArrived(orderId);
    if (!mounted) return;
    setState(() => _notifyingArrival = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente notificado. Escanea su QR.')));
      _openScanAndPop(context, orderId, 'delivery');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al notificar llegada. Intenta de nuevo.')));
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = order['status']?.toString() ?? '';
    final hasDelivery = order['order_delivery'] != null;
    final commerce = order['commerce'] as Map<String, dynamic>?;
    final commerceName = commerce?['business_name']?.toString() ?? commerce?['name']?.toString() ?? 'Comercio';
    final commerceAddress = commerce?['address']?.toString() ?? '';
    final profile = order['profile'] as Map<String, dynamic>?;
    final user = profile?['user'] as Map<String, dynamic>?;
    final customerName = '${user?['name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    final customerPhone = profile?['phone']?.toString() ?? user?['phone']?.toString() ?? '';
    final deliveryAddress = order['delivery_address']?.toString() ?? order['shipping_address']?.toString() ?? 'Sin dirección';
    final total = _dbl(order['total']);
    final deliveryFee = _dbl(order['delivery_fee']);
    final subtotal = _dbl(order['subtotal']);
    final orderNumber = order['order_number']?.toString() ?? '#${order['id']}';
    final items = order['order_items'] as List? ?? [];
    final orderId = _orderId(order);
    final canScanPickup = status == 'processing' && hasDelivery;
    final canNotifyArrived = status == 'shipped' && hasDelivery;
    final notes = order['notes']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final etaMin = safeInt(order['estimated_delivery_time'], 0);
    final hasEta = etaMin > 0;
    final showMap = hasDelivery && (status == 'processing' || status == 'shipped');
    final dest = _currentDestination();
    final isGoingToCommerce = status == 'processing';

    return Scaffold(
      appBar: AppBar(title: Text('Orden $orderNumber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status, hasDelivery),

            // --- Map section ---
            if (showMap) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _agentPosition ?? dest ?? const LatLng(10.16, -68.01),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(urlTemplate: AppConfig.osmTileUrl, userAgentPackageName: 'com.zonix.eats'),
                          if (_routePoints.length >= 2)
                            PolylineLayer(polylines: [
                              Polyline(points: _routePoints, color: AppColors.blue, strokeWidth: 4),
                            ]),
                          MarkerLayer(markers: [
                            if (_agentPosition != null)
                              Marker(
                                point: _agentPosition!,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                                  child: const Icon(Icons.delivery_dining, color: AppColors.white, size: 20),
                                ),
                              ),
                            if (dest != null)
                              Marker(
                                point: dest,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isGoingToCommerce ? AppColors.orange : AppColors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.white, width: 2),
                                  ),
                                  child: Icon(isGoingToCommerce ? Icons.store : Icons.person_pin_circle, color: AppColors.white, size: 20),
                                ),
                              ),
                          ]),
                        ],
                      ),
                      if (_routeLoading)
                        const Positioned(top: 8, right: 8, child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_routeDistanceKm != null)
                    _chipInfo(Icons.straighten, '${_routeDistanceKm!.toStringAsFixed(1)} km', AppColors.blue),
                  if (_routeEtaMin != null) ...[
                    const SizedBox(width: 8),
                    _chipInfo(Icons.timer, '~$_routeEtaMin min', AppColors.orange),
                  ],
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: dest != null ? _openGoogleMapsNav : null,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navegar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isGoingToCommerce ? 'Ruta hacia el comercio' : 'Ruta hacia el cliente',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
              ),
            ],

            if (hasEta) ...[
              const SizedBox(height: 12),
              Text(
                'ETA para el cliente: ~$etaMin min',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryText(context)),
              ),
            ],
            const SizedBox(height: 20),

            _buildSection(context, icon: Icons.store, title: 'Comercio', isDark: isDark, children: [
              _buildRow('Nombre', commerceName),
              if (commerceAddress.isNotEmpty) _buildRow('Dirección', commerceAddress),
            ]),
            const SizedBox(height: 12),

            _buildSection(context, icon: Icons.person, title: 'Cliente', isDark: isDark, children: [
              if (customerName.isNotEmpty) _buildRow('Nombre', customerName),
              if (customerPhone.isNotEmpty) _buildRow('Teléfono', customerPhone),
              _buildRow('Dirección entrega', deliveryAddress),
            ]),
            const SizedBox(height: 12),

            _buildSection(context, icon: Icons.shopping_bag, title: 'Productos (${items.length})', isDark: isDark, children: items.map<Widget>((item) {
              final product = item['product'] as Map<String, dynamic>?;
              final productName = product?['name']?.toString() ?? 'Producto';
              final qty = item['quantity']?.toString() ?? '1';
              final price = _dbl(item['price']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Text('${qty}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(productName)),
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ]),
              );
            }).toList()),
            const SizedBox(height: 12),

            if (notes.isNotEmpty) ...[
              _buildSection(context, icon: Icons.notes, title: 'Notas', isDark: isDark, children: [Text(notes)]),
              const SizedBox(height: 12),
            ],

            _buildSection(context, icon: Icons.receipt_long, title: 'Resumen', isDark: isDark, children: [
              if (subtotal > 0) _buildRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
              if (deliveryFee > 0) _buildRow('Delivery fee', '\$${deliveryFee.toStringAsFixed(2)}'),
              const Divider(),
              _buildRow('Total', '\$${total.toStringAsFixed(2)}', bold: true),
            ]),
            const SizedBox(height: 24),

            if (canScanPickup) ...[
              const Text('En el comercio, pide que muestre el código QR de recogida y escanéalo.', style: TextStyle(color: AppColors.grayDark, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openScanAndPop(context, orderId, 'pickup'),
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.white),
                  label: const Text('Escanear QR de recogida', style: TextStyle(color: AppColors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
            if (canNotifyArrived) ...[
              const Text('Cuando llegues al domicilio del cliente, toca el botón para notificarle y escanear su QR.', style: TextStyle(color: AppColors.grayDark, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _notifyingArrival ? null : () => _arrivedAndScan(orderId),
                  icon: _notifyingArrival
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.location_on, color: AppColors.white),
                  label: Text(_notifyingArrival ? 'Notificando...' : 'Llegué al destino', style: const TextStyle(color: AppColors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Helper widgets ---

  Widget _chipInfo(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildStatusHeader(String status, bool hasDelivery) {
    final color = _statusColor(status, hasDelivery);
    final label = _statusLabel(status, hasDelivery);
    final icon = _statusIcon(status, hasDelivery);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.grayDark : AppColors.grayLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textMutedGray.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: AppColors.gray), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text('$label:', style: const TextStyle(color: AppColors.gray, fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500))),
      ]),
    );
  }

  Color _statusColor(String status, bool hasDelivery) => switch (status) {
        'processing' => hasDelivery ? AppColors.orange : AppColors.textMutedGray,
        'shipped' => hasDelivery ? AppColors.blue : AppColors.orange,
        'delivered' => AppColors.green,
        'cancelled' => AppColors.red,
        _ => AppColors.textMutedGray,
      };

  String _statusLabel(String status, bool hasDelivery) => switch (status) {
        'processing' => hasDelivery ? 'Ir al comercio — escanea QR' : 'Preparando',
        'shipped' => hasDelivery ? 'En camino al cliente' : 'Disponible',
        'delivered' => 'Entregada',
        'cancelled' => 'Cancelada',
        _ => status,
      };

  IconData _statusIcon(String status, bool hasDelivery) => switch (status) {
        'processing' => hasDelivery ? Icons.store : Icons.restaurant,
        'shipped' => hasDelivery ? Icons.delivery_dining : Icons.assignment,
        'delivered' => Icons.check_circle,
        'cancelled' => Icons.cancel,
        _ => Icons.help_outline,
      };

  double _dbl(dynamic value) {
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orden')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error ?? 'Orden no encontrada'),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        ])),
      );
    }
    return DeliveryOrderDetailPage(order: _order!);
  }
}
