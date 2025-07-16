import 'package:flutter/material.dart';
import '../../../models/commerce_order.dart';
import '../../../features/services/commerce_order_service.dart';
import 'commerce_order_detail_page.dart';

class CommerceOrdersPage extends StatefulWidget {
  const CommerceOrdersPage({Key? key}) : super(key: key);

  @override
  State<CommerceOrdersPage> createState() => _CommerceOrdersPageState();
}

class _CommerceOrdersPageState extends State<CommerceOrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<CommerceOrder>> _ordersFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  final List<String> _statusTabs = [
    'Todas',
    'Pendientes',
    'En Preparación',
    'Listas',
    'En Camino',
    'Entregadas',
    'Canceladas',
  ];

  final Map<String, String> _statusFilters = {
    'Todas': '',
    'Pendientes': 'pending_payment',
    'En Preparación': 'preparing',
    'Listas': 'ready',
    'En Camino': 'on_way',
    'Entregadas': 'delivered',
    'Canceladas': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _ordersFuture = CommerceOrderService.getOrders(
        status: _statusFilters[_statusTabs[_tabController.index]],
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _statsFuture = CommerceOrderService.getOrderStats();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _loadData();
  }

  Future<void> _updateOrderStatus(CommerceOrder order, String newStatus) async {
    setState(() { _loading = true; _error = null; });
    
    try {
      await CommerceOrderService.updateOrderStatus(order.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment': return 'Pendiente de Pago';
      case 'paid': return 'Pagado';
      case 'preparing': return 'En Preparación';
      case 'ready': return 'Listo';
      case 'on_way': return 'En Camino';
      case 'delivered': return 'Entregado';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment': return Colors.orange;
      case 'paid': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'on_way': return Colors.indigo;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Órdenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_orders'] ?? 0}',
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Pendientes',
                        '${stats['pending_orders'] ?? 0}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'En Preparación',
                        '${stats['preparing_orders'] ?? 0}',
                        Icons.restaurant,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Listas',
                        '${stats['ready_orders'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Entregadas',
                        '${stats['delivered_orders'] ?? 0}',
                        Icons.local_shipping,
                        Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Ingresos',
                        '\$${(stats['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() { _searchQuery = value; });
                _loadData();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ordenar por',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('Fecha')),
                      DropdownMenuItem(value: 'total', child: Text('Total')),
                      DropdownMenuItem(value: 'status', child: Text('Estado')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortBy = value!; });
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Orden',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortOrder,
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Descendente')),
                      DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
                    ],
                    onChanged: (value) {
                      setState(() { _sortOrder = value!; });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(CommerceOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Icon(
            _getOrderIcon(order.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Orden #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.customerName),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  order.isDelivery ? Icons.local_shipping : Icons.store,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  order.deliveryTypeText,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  '${order.itemCount} items',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommerceOrderDetailPage(order: order),
            ),
          );
          if (result == true) _refresh();
        },
      ),
    );
  }

  IconData _getOrderIcon(String status) {
    switch (status) {
      case 'pending_payment': return Icons.payment;
      case 'paid': return Icons.check_circle;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.done_all;
      case 'on_way': return Icons.local_shipping;
      case 'delivered': return Icons.delivery_dining;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Órdenes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((tab) => Tab(text: tab)).toList(),
          onTap: (index) {
            _loadData();
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatsCard(),
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<CommerceOrder>>(
                  future: _ordersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar órdenes',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No hay órdenes',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aún no has recibido órdenes',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final orders = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
} 