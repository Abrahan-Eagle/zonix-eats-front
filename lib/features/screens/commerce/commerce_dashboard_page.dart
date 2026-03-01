import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/features/services/commerce_order_service.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

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
      final profile = await ProfileService().getMyProfile();
      if (profile == null) throw Exception('Perfil no encontrado');

      try {
        final commerceData = await CommerceDataService.getCommerceData();
        _commerceOpen = commerceData['open'] == true;
        _commerceId = commerceData['id'] ?? 0;
      } catch (_) {
        _commerceOpen = false;
        _commerceId = 0;
      }

      final stats = await Provider.of<CommerceService>(context, listen: false)
          .getCommerceStatistics(_commerceId);
      List<dynamic> recent = stats['recent_orders'] as List<dynamic>? ?? [];
      if (recent.isEmpty) {
        final orders = await CommerceOrderService.getOrders(perPage: 5);
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    value: '\$${((_stats['today_revenue'] ?? 0.0) as num).toStringAsFixed(2)}',
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
                      '\$${((order['total'] ?? 0) as num).toStringAsFixed(2)} · ${_statusText(order['status'] ?? '')}',
                    ),
                    trailing: Chip(
                      label: Text(
                        _statusText(order['status'] ?? ''),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: _statusColor(order['status'] ?? ''),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      final id = order['id'];
                      if (id != null) {
                        Navigator.pushNamed(context, '/commerce/order/$id');
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
                    icon: Icons.receipt,
                    label: 'Ver Órdenes',
                    onTap: () => Navigator.pushNamed(context, '/commerce/orders'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.inventory,
                    label: 'Productos',
                    onTap: () => Navigator.pushNamed(context, '/commerce/products'),
                  ),
                ),
              ],
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
                    label: 'Perfil',
                    onTap: () => Navigator.pushNamed(context, '/commerce/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person,
                    label: 'Mi Perfil',
                    onTap: () => Navigator.pushNamed(context, '/commerce/profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.analytics,
                    label: 'Reportes',
                    onTap: () => Navigator.pushNamed(context, '/commerce/reports'),
                  ),
                ),
              ],
            ),
          ],
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
