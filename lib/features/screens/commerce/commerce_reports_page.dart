import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/commerce_analytics_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceReportsPage extends StatefulWidget {
  const CommerceReportsPage({super.key});

  @override
  State<CommerceReportsPage> createState() => _CommerceReportsPageState();
}

class _CommerceReportsPageState extends State<CommerceReportsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _products = {};
  String _period = 'month';

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
      final analytics = Provider.of<CommerceAnalyticsService>(context, listen: false);
      final overview = await analytics.getOverview();
      final products = await analytics.getProducts();

      if (mounted) {
        setState(() {
          _overview = overview;
          _products = products;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
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
        title: const Text('Reportes'),
        actions: [
          DropdownButton<String>(
            value: _period,
            items: const [
              DropdownMenuItem(value: 'today', child: Text('Hoy')),
              DropdownMenuItem(value: 'week', child: Text('Semana')),
              DropdownMenuItem(value: 'month', child: Text('Mes')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _period = v);
              _loadData();
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
              Text(
                'Resumen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Ventas totales',
                      value: '\$${((_overview['total_sales'] ?? 0) as num).toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Órdenes',
                      value: '${_overview['total_orders'] ?? 0}',
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
                      label: 'Ticket promedio',
                      value: '\$${((_overview['average_order_value'] ?? 0) as num).toStringAsFixed(2)}',
                      icon: Icons.shopping_cart,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Crecimiento %',
                      value: '${((_overview['growth_rate'] ?? 0) as num).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: (_overview['growth_rate'] ?? 0) as num >= 0
                          ? AppColors.green
                          : AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Clientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total clientes',
                      value: '${_overview['customer_count'] ?? 0}',
                      icon: Icons.people,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Recurrentes',
                      value: '${_overview['repeat_customers'] ?? 0}',
                      icon: Icons.repeat,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildOrdersByStatus(),
              const SizedBox(height: 24),
              _buildTopProducts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersByStatus() {
    final raw = _overview['orders_by_status'];
    Map<String, dynamic> byStatus;
    if (raw is Map<String, dynamic>) {
      byStatus = raw;
    } else {
      // Cuando no hay órdenes, el backend puede devolver una lista vacía ([]),
      // lo que hace que el cast a Map falle. En ese caso simplemente no mostramos nada.
      return const SizedBox.shrink();
    }
    if (byStatus.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Órdenes por estado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: byStatus.entries.map((e) {
                final status = e.key.toString();
                final count = (e.value ?? 0) as num;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_statusLabel(status)),
                      Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
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

  Widget _buildTopProducts() {
    final top = _products['top_products'] as List<dynamic>? ?? [];
    if (top.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5 productos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top.length > 5 ? 5 : top.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = top[i] is Map ? top[i] as Map : {};
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(p['name'] ?? 'Producto'),
                trailing: Text(
                  '${p['total_quantity'] ?? p['quantity'] ?? 0} vendidos',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
        ),
      ],
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
