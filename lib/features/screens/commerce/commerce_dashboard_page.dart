import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/models/order.dart';

class CommerceDashboardPage extends StatefulWidget {
  const CommerceDashboardPage({Key? key}) : super(key: key);

  @override
  State<CommerceDashboardPage> createState() => _CommerceDashboardPageState();
}

class _CommerceDashboardPageState extends State<CommerceDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Order> _recentOrders = [];

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
      // Simular carga de datos del dashboard
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _stats = {
          'totalSales': 125000.0,
          'totalOrders': 45,
          'pendingOrders': 8,
          'completedOrders': 37,
          'averageOrderValue': 2777.78,
          'monthlyGrowth': 12.5,
        };
        
        _recentOrders = [
          Order(
            id: 1,
            status: 'pending',
            total: 15000.0,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            items: [],
          ),
          Order(
            id: 2,
            status: 'completed',
            total: 8500.0,
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            items: [],
          ),
          Order(
            id: 3,
            status: 'pending',
            total: 22000.0,
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            items: [],
          ),
        ];
        
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Order order) {
    Color statusColor = order.status == 'completed' 
        ? Colors.green 
        : order.status == 'pending' 
            ? Colors.orange 
            : Colors.red;
    
    String statusText = order.status == 'completed' 
        ? 'Completada' 
        : order.status == 'pending' 
            ? 'Pendiente' 
            : 'Cancelada';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            order.status == 'completed' 
                ? Icons.check_circle 
                : Icons.pending,
            color: statusColor,
          ),
        ),
        title: Text(
          'Orden #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₡${(order.total ?? 0.0).toStringAsFixed(2)}'),
            Text(
              '${order.createdAt?.day ?? 0}/${order.createdAt?.month ?? 0}/${order.createdAt?.year ?? 0} ${order.createdAt?.hour ?? 0}:${order.createdAt?.minute ?? 0}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            statusText,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: statusColor,
        ),
        onTap: () {
          // Navegar a detalles de la orden
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ver detalles de orden #${order.id}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                    // Resumen de métricas
                    const Text(
                      'Resumen del Día',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid de estadísticas
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Ventas Totales',
                          '₡${_stats['totalSales']?.toStringAsFixed(0) ?? '0'}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Órdenes',
                          '${_stats['totalOrders'] ?? 0}',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Pendientes',
                          '${_stats['pendingOrders'] ?? 0}',
                          Icons.pending,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Completadas',
                          '${_stats['completedOrders'] ?? 0}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Crecimiento mensual
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _stats['monthlyGrowth'] > 0 
                                  ? Icons.trending_up 
                                  : Icons.trending_down,
                              color: _stats['monthlyGrowth'] > 0 
                                  ? Colors.green 
                                  : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Crecimiento Mensual',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_stats['monthlyGrowth']?.toStringAsFixed(1) ?? '0'}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _stats['monthlyGrowth'] > 0 
                                          ? Colors.green 
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Órdenes recientes
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
                            // Navegar a todas las órdenes
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ver todas las órdenes')),
                            );
                          },
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Lista de órdenes recientes
                    ..._recentOrders.map((order) => _buildRecentOrderCard(order)),
                    
                    const SizedBox(height: 100), // Espacio para el FAB
                  ],
                ),
              ),
            ),
    );
  }
} 