import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import 'package:zonix/features/utils/user_provider.dart';

class DeliveryRoutesPage extends StatefulWidget {
  const DeliveryRoutesPage({super.key});

  @override
  State<DeliveryRoutesPage> createState() => _DeliveryRoutesPageState();
}

class _DeliveryRoutesPageState extends State<DeliveryRoutesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final d = context.read<DeliveryService>();
    await d.loadRoutes();
    if (!mounted) return;
    await syncDeliverySessionAfterApi(context, d);
  }

  String _parseAddress(dynamic addr) {
    if (addr == null) return 'Sin dirección';
    final s = addr.toString();
    if (s.isEmpty) return 'Sin dirección';
    try {
      final map = json.decode(s);
      if (map is Map) {
        return map['address']?.toString() ??
            map['street']?.toString() ??
            s;
      }
    } catch (_) {}
    return s;
  }

  double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return AppColors.orange;
      case 'shipped':
        return AppColors.blue;
      case 'delivered':
        return AppColors.green;
      default:
        return AppColors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Asignada';
      case 'shipped':
        return 'En camino';
      case 'delivered':
        return 'Entregada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas activas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadData()),
        ],
      ),
      body: Consumer<DeliveryService>(
        builder: (context, service, _) {
          if (service.routesLoading && service.routesList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.routesError != null && service.routesList.isEmpty) {
            return _buildErrorState(service.routesError!);
          }
          if (service.routesList.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.routesList.length,
              itemBuilder: (context, index) {
                return _buildRouteCard(service.routesList[index], isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, bool isDark) {
    final order = route['order'] as Map<String, dynamic>?;
    final orderNumber = order?['order_number']?.toString() ??
        route['order_number']?.toString() ??
        '#${route['order_id'] ?? route['id']}';
    final commerceName = order?['commerce_name']?.toString() ??
        route['commerce_name']?.toString() ??
        'Comercio';
    final deliveryAddress = _parseAddress(
        order?['delivery_address'] ?? route['delivery_address']);
    final estimatedTime = safeInt(route['estimated_time']);
    final distance = _parseNum(route['total_distance']);
    final status = route['status']?.toString() ?? 'assigned';
    final total = _parseNum(order?['total'] ?? route['total']);
    final sColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.grayDark : null,
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
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.route, color: sColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden $orderNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        commerceName,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(Icons.location_on, 'Entregar en', deliveryAddress),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _metricChip(
                    Icons.timer_outlined,
                    '$estimatedTime min',
                    AppColors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricChip(
                    Icons.straighten,
                    '${distance.toStringAsFixed(1)} km',
                    AppColors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricChip(
                    Icons.attach_money,
                    '\$${total.toStringAsFixed(2)}',
                    AppColors.green,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText(context)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _metricChip(IconData icon, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.grayLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 64, color: AppColors.secondaryText(context)),
          const SizedBox(height: 16),
          Text(
            'No tienes rutas activas',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
