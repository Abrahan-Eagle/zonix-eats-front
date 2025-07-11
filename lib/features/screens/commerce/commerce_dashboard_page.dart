import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_service.dart';
import 'package:zonix/models/commerce.dart';
import 'package:zonix/models/order.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';

class CommerceDashboardPage extends StatefulWidget {
  const CommerceDashboardPage({Key? key}) : super(key: key);

  @override
  State<CommerceDashboardPage> createState() => _CommerceDashboardPageState();
}

class _CommerceDashboardPageState extends State<CommerceDashboardPage> {
  bool _isLoading = true;
  final CommerceService _commerceService = CommerceService();
  Commerce? _commerce;
  List<Order> _recentOrders = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load commerce data (assuming commerce ID 1 for demo)
      _commerce = await _commerceService.getCommerceById(1);
      
      // Load statistics
      _statistics = await _commerceService.getCommerceStatistics(1);
      
      // Load recent orders
      _recentOrders = await _commerceService.getOrdersByCommerce(1);
      _recentOrders = _recentOrders.take(5).toList(); // Get only 5 most recent
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status),
          ),
        ),
        title: Text(
          'Orden ${order.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${order.total.toStringAsFixed(2)}'),
            Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            order.statusText,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: _getStatusColor(order.status),
        ),
        onTap: () {
          _showOrderDetails(order);
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.purple;
      case 'ready':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'ready':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'confirmed':
        return Icons.confirmation_number;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Orden ${order.orderNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estado: ${order.statusText}'),
              Text('Total: \$${order.total.toStringAsFixed(2)}'),
              Text('Dirección: ${order.deliveryAddress}'),
              Text('Método de pago: ${order.paymentMethod}'),
              if (order.specialInstructions != null)
                Text('Instrucciones: ${order.specialInstructions}'),
              const SizedBox(height: 16),
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.productName)),
                    Text('x${item.quantity}'),
                    Text('\$${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order);
            },
            child: const Text('Actualizar Estado'),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(Order order) {
    final statuses = ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'];
    final currentIndex = statuses.indexOf(order.status);
    final nextStatus = currentIndex < statuses.length - 1 ? statuses[currentIndex + 1] : order.status;
    
    _commerceService.updateOrderStatus(order.id, nextStatus).then((_) {
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a: ${Order.fromJson({'status': nextStatus}).statusText}')),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_commerce?.name ?? 'Dashboard'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Commerce Info
                    if (_commerce != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(_commerce!.logo),
                                onBackgroundImageError: (_, __) {},
                                child: _commerce!.logo.isEmpty ? Text(_commerce!.name[0]) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _commerce!.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _commerce!.category,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text(' ${_commerce!.rating.toStringAsFixed(1)} (${_commerce!.reviewCount})'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Statistics
                    const Text(
                      'Estadísticas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Órdenes Totales',
                          '${_statistics['total_orders'] ?? 0}',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Ingresos',
                          '\$${(_statistics['total_revenue'] ?? 0.0).toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Valor Promedio',
                          '\$${(_statistics['average_order_value'] ?? 0.0).toStringAsFixed(0)}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Productos',
                          '${_statistics['total_products'] ?? 0}',
                          Icons.inventory,
                          Colors.purple,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Orders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Órdenes Recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to orders page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Navegando a órdenes...')),
                            );
                          },
                          child: const Text('Ver Todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_recentOrders.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No hay órdenes recientes',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._recentOrders.map((order) => _buildRecentOrderCard(order)),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to inventory
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navegando a inventario...')),
                              );
                            },
                            icon: const Icon(Icons.inventory),
                            label: const Text('Inventario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to reports
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navegando a reportes...')),
                              );
                            },
                            icon: const Icon(Icons.analytics),
                            label: const Text('Reportes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 