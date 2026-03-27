import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../services/delivery_company_service.dart';
import '../../services/pusher_service.dart';
import '../../../helpers/auth_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

class DeliveryCompanyMapPage extends StatefulWidget {
  const DeliveryCompanyMapPage({super.key});

  @override
  State<DeliveryCompanyMapPage> createState() => _DeliveryCompanyMapPageState();
}

class _DeliveryCompanyMapPageState extends State<DeliveryCompanyMapPage> {
  final MapController _mapController = MapController();

  String _statusFilter = 'all';
  String _searchQuery = '';
  double _radiusKm = 10;
  LatLng? _headquarters;
  StreamSubscription<Map<String, dynamic>>? _pusherSub;
  String? _companyChannel;
  String? _companyName;
  int? _selectedAgentId;
  final Map<int, List<LatLng>> _routeCache = {};

  static const _radiusOptions = [1.0, 3.0, 5.0, 10.0, 20.0];

  static final _radiusToZoom = <double, double>{
    1.0: 15.5,
    3.0: 13.8,
    5.0: 13.0,
    10.0: 11.8,
    20.0: 10.5,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAgents();
      if (!mounted) return;
      _subscribePusher();
    });
  }

  @override
  void dispose() {
    _unsubscribePusher();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents({bool preloadRoutes = true}) async {
    final svc = context.read<DeliveryCompanyService>();
    if (svc.dashboardData.isEmpty) await svc.loadDashboard();

    _resolveHeadquarters(svc.dashboardData);

    await svc.loadAgentsForMap(
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
    if (!mounted) return;
    _moveToRadius();
    if (preloadRoutes) _preloadBusyRoutes(svc.mapAgents);
  }

  void _resolveHeadquarters(Map<String, dynamic> dashboard) {
    final company = dashboard['company'] as Map?;
    _companyName = company?['name']?.toString();
    final hq = company?['headquarters'] as Map?;
    if (hq != null) {
      final lat = safeDouble(hq['latitude']);
      final lng = safeDouble(hq['longitude']);
      if (lat != 0 && lng != 0) {
        _headquarters = LatLng(lat, lng);
      }
    }
  }

  void _moveToRadius() {
    if (_headquarters == null) return;
    final zoom = _radiusToZoom[_radiusKm] ?? 11.8;
    _mapController.move(_headquarters!, zoom);
  }

  void _preloadBusyRoutes(List<Map<String, dynamic>> agents) {
    for (final a in agents) {
      if (a['is_busy'] == true && a['destination'] is Map) {
        _loadRouteForAgent(a);
      }
    }
  }

  Future<List<LatLng>> _fetchRoute(double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/location/calculate-route'),
        headers: headers,
        body: jsonEncode({
          'origin_lat': fromLat,
          'origin_lng': fromLng,
          'destination_lat': toLat,
          'destination_lng': toLng,
          'mode': 'driving',
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data['success'] != true) return [];
      final polyline = data['data']?['polyline'];
      if (polyline == null || polyline is! List) return [];
      return polyline
          .map<LatLng>((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadRouteForAgent(Map<String, dynamic> agent) async {
    final agentId = safeInt(agent['id']);
    if (_routeCache.containsKey(agentId)) return;
    final dest = agent['destination'];
    if (dest == null || dest is! Map) return;
    final pts = await _fetchRoute(
      safeDouble(agent['current_latitude']),
      safeDouble(agent['current_longitude']),
      safeDouble(dest['latitude']),
      safeDouble(dest['longitude']),
    );
    if (pts.isNotEmpty && mounted) {
      setState(() => _routeCache[agentId] = pts);
    }
  }

  void _subscribePusher() {
    final svc = context.read<DeliveryCompanyService>();
    final companyId = (svc.dashboardData['company'] as Map?)?['id'];
    if (companyId == null) return;

    _companyChannel = 'private-company.$companyId';
    PusherService.instance.subscribeToChannel(_companyChannel!);

    _pusherSub?.cancel();
    _pusherSub = PusherService.instance.eventStream.listen((event) {
      if (!mounted) return;
      final eventName = event['eventName']?.toString() ?? '';
      final channelName = event['channelName']?.toString() ?? '';

      if (channelName == _companyChannel &&
          eventName.contains('DeliveryLocationUpdated')) {
        final rawData = event['data'];
        final Map<String, dynamic> data;
        if (rawData is String) {
          data = Map<String, dynamic>.from(jsonDecode(rawData));
        } else if (rawData is Map<String, dynamic>) {
          data = rawData;
        } else {
          return;
        }

        final agentId = safeInt(data['delivery_agent_id']);
        final loc = data['location'];
        if (agentId > 0 && loc is Map) {
          context.read<DeliveryCompanyService>().updateAgentLocation(
                agentId,
                safeDouble(loc['latitude']),
                safeDouble(loc['longitude']),
              );
        }
      }
    });
  }

  void _unsubscribePusher() {
    _pusherSub?.cancel();
    _pusherSub = null;
    if (_companyChannel != null) {
      PusherService.instance.unsubscribeFromChannel(_companyChannel!);
      _companyChannel = null;
    }
  }

  List<Map<String, dynamic>> _visibleAgents(List<Map<String, dynamic>> all) {
    var result = all.where((a) {
      final lat = safeDouble(a['current_latitude']);
      final lng = safeDouble(a['current_longitude']);
      return lat != 0 && lng != 0;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((a) => safeString(a['name']).toLowerCase().contains(q))
          .toList();
    }

    if (_headquarters != null) {
      result = result.where((a) {
        final d = _haversineKm(
          _headquarters!.latitude,
          _headquarters!.longitude,
          safeDouble(a['current_latitude']),
          safeDouble(a['current_longitude']),
        );
        return d <= _radiusKm;
      }).toList();
    }

    return result;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ─────────────────── BUILD ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Agentes'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.headerGradientStart(context),
              AppColors.headerGradientMid(context),
            ]),
          ),
        ),
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadAgents,
          ),
        ],
      ),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, svc, _) {
          if (svc.mapAgentsLoading && svc.mapAgents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (svc.mapAgentsError != null && svc.mapAgents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(svc.mapAgentsError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondaryText(context))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAgents,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final visible = _visibleAgents(svc.mapAgents);

          return Stack(
            children: [
              _buildMap(visible),
              _buildTopControls(visible.length, svc.mapAgents.length),
              _buildRadiusSlider(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> agents) {
    final markers = agents.map((a) {
      final lat = safeDouble(a['current_latitude']);
      final lng = safeDouble(a['current_longitude']);
      final isBusy = a['is_busy'] == true;
      final name = safeString(a['name']);

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 52,
        child: GestureDetector(
          onTap: () async {
            setState(() => _selectedAgentId = safeInt(a['id']));
            if (a['is_busy'] == true) await _loadRouteForAgent(a);
            if (!mounted) return;
            _showAgentSheet(a);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBusy ? AppColors.orange : AppColors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  name.length > 12 ? '${name.substring(0, 12)}…' : name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.delivery_dining,
                color: isBusy ? AppColors.orange : AppColors.green,
                size: 28,
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (_headquarters != null) {
      markers.insert(
        0,
        Marker(
          point: _headquarters!,
          width: 100,
          height: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  _companyName != null && _companyName!.length > 10
                      ? '${_companyName!.substring(0, 10)}…'
                      : _companyName ?? 'Sede',
                  style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.business, color: AppColors.blue, size: 28),
            ],
          ),
        ),
      );
    }

    // Destination markers for busy agents with routes
    for (final a in agents) {
      if (a['is_busy'] != true) continue;
      final dest = a['destination'];
      if (dest == null || dest is! Map) continue;
      final destLat = safeDouble(dest['latitude']);
      final destLng = safeDouble(dest['longitude']);
      if (destLat == 0 || destLng == 0) continue;
      final isSelected = safeInt(a['id']) == _selectedAgentId;
      markers.add(Marker(
        point: LatLng(destLat, destLng),
        width: 32,
        height: 32,
        child: Icon(
          Icons.flag_rounded,
          color: isSelected ? AppColors.red : AppColors.red.withAlpha(120),
          size: isSelected ? 32 : 24,
        ),
      ));
    }

    final circles = <CircleMarker>[];
    if (_headquarters != null) {
      circles.add(CircleMarker(
        point: _headquarters!,
        radius: _radiusKm * 1000,
        useRadiusInMeter: true,
        color: AppColors.blue.withAlpha(20),
        borderColor: AppColors.blue.withAlpha(80),
        borderStrokeWidth: 2,
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _headquarters ?? const LatLng(10.1579, -67.9972),
        initialZoom: _radiusToZoom[_radiusKm] ?? 11.8,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.osmTileUrl,
          userAgentPackageName: 'com.zonix.eats',
          maxZoom: 19,
        ),
        if (circles.isNotEmpty) CircleLayer(circles: circles),
        PolylineLayer(polylines: _buildRoutePolylines(agents)),
        MarkerLayer(markers: markers),
      ],
    );
  }

  List<Polyline> _buildRoutePolylines(List<Map<String, dynamic>> agents) {
    final polylines = <Polyline>[];
    for (final a in agents) {
      if (a['is_busy'] != true) continue;
      final dest = a['destination'];
      if (dest == null || dest is! Map) continue;
      final agentId = safeInt(a['id']);
      final agentLat = safeDouble(a['current_latitude']);
      final agentLng = safeDouble(a['current_longitude']);
      final destLat = safeDouble(dest['latitude']);
      final destLng = safeDouble(dest['longitude']);
      if (destLat == 0 || destLng == 0) continue;

      final isSelected = agentId == _selectedAgentId;
      final cachedRoute = _routeCache[agentId];
      final points = cachedRoute ?? [LatLng(agentLat, agentLng), LatLng(destLat, destLng)];

      polylines.add(Polyline(
        points: points,
        color: isSelected ? AppColors.orange : AppColors.orange.withAlpha(80),
        strokeWidth: isSelected ? 4.0 : 2.0,
      ));
    }
    return polylines;
  }

  Widget _buildTopControls(int visibleCount, int totalCount) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: (_isDark ? AppColors.grayDark : AppColors.white).withAlpha(230),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: AppColors.black12, blurRadius: 8),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Buscar agente…',
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: _isDark ? AppColors.black26 : AppColors.grayLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$visibleCount/$totalCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _filterChip('Todos', 'all'),
                      const SizedBox(width: 6),
                      _filterChip('Libres', 'available'),
                      const SizedBox(width: 6),
                      _filterChip('En mandado', 'busy'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadAgents(preloadRoutes: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : (_isDark ? AppColors.black26 : AppColors.grayLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.secondaryText(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: (_isDark ? AppColors.grayDark : AppColors.white).withAlpha(230),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: AppColors.black12, blurRadius: 8),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.radar, size: 20, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                '${_radiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Expanded(
                child: Slider(
                  value: _radiusOptions.indexOf(_radiusKm).toDouble(),
                  min: 0,
                  max: (_radiusOptions.length - 1).toDouble(),
                  divisions: _radiusOptions.length - 1,
                  label: '${_radiusKm.toStringAsFixed(0)} km',
                  activeColor: AppColors.blue,
                  onChanged: (v) {
                    setState(() {
                      _radiusKm = _radiusOptions[v.round()];
                      _moveToRadius();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── AGENT SHEET ───────────────────

  void _showAgentSheet(Map<String, dynamic> agent) {
    final name = safeString(agent['name']);
    final phone = safeString(agent['phone']);
    final isBusy = agent['is_busy'] == true;
    final vehicleType = safeString(agent['vehicle_type']);
    final rating = safeDouble(agent['rating']);
    final totalDeliveries = safeInt(agent['total_deliveries']);
    final orderId = agent['current_order_id'];
    final orderStatus = safeString(agent['current_order_status']);
    final lastUpdate = safeString(agent['last_location_update']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMutedGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        (isBusy ? AppColors.orange : AppColors.green).withAlpha(30),
                    child: Icon(
                      Icons.delivery_dining,
                      color: isBusy ? AppColors.orange : AppColors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isBusy ? AppColors.orange : AppColors.green)
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isBusy ? 'En mandado' : 'Libre',
                                style: TextStyle(
                                  color:
                                      isBusy ? AppColors.orange : AppColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (vehicleType.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(vehicleType,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText(context),
                                  )),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statChip(Icons.star, rating > 0 ? rating.toStringAsFixed(1) : '—', 'Rating'),
                  const SizedBox(width: 12),
                  _statChip(Icons.local_shipping, totalDeliveries.toString(), 'Entregas'),
                  if (lastUpdate.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    _statChip(Icons.access_time, _timeSince(lastUpdate), 'Últ. ubicación'),
                  ],
                ],
              ),
              if (isBusy && orderId != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orden #$orderId',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        orderStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildRoutePreview(agent),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (phone.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () =>
                            launchUrl(Uri.parse('tel:$phone')),
                      ),
                    ),
                  if (phone.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Centrar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        side: const BorderSide(color: AppColors.blue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final lat = safeDouble(agent['current_latitude']);
                        final lng = safeDouble(agent['current_longitude']);
                        if (lat != 0 && lng != 0) {
                          _mapController.move(LatLng(lat, lng), 16);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutePreview(Map<String, dynamic> agent) {
    final dest = agent['destination'];
    if (dest == null || dest is! Map) return const SizedBox.shrink();
    final agentLat = safeDouble(agent['current_latitude']);
    final agentLng = safeDouble(agent['current_longitude']);
    final destLat = safeDouble(dest['latitude']);
    final destLng = safeDouble(dest['longitude']);
    final destAddress = safeString(dest['address']);
    if (destLat == 0 || destLng == 0) return const SizedBox.shrink();

    final midLat = (agentLat + destLat) / 2;
    final midLng = (agentLng + destLng) / 2;
    final dist = _haversineKm(agentLat, agentLng, destLat, destLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.route, size: 16, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              'Ruta al destino (${dist.toStringAsFixed(1)} km)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        if (destAddress.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            destAddress,
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(midLat, midLng),
                initialZoom: dist > 10 ? 10 : (dist > 3 ? 12 : 14),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: 'com.zonix.eats',
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: _routeCache[safeInt(agent['id'])] ?? [LatLng(agentLat, agentLng), LatLng(destLat, destLng)],
                    color: AppColors.orange,
                    strokeWidth: 3,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(agentLat, agentLng),
                    width: 28,
                    height: 28,
                    child: const Icon(Icons.delivery_dining, color: AppColors.orange, size: 28),
                  ),
                  Marker(
                    point: LatLng(destLat, destLng),
                    width: 28,
                    height: 28,
                    child: const Icon(Icons.flag_rounded, color: AppColors.red, size: 28),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _isDark ? AppColors.black26 : AppColors.grayLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.secondaryText(context)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: AppColors.secondaryText(context))),
          ],
        ),
      ),
    );
  }

  String _timeSince(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '—';
    }
  }
}
