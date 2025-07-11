import 'package:flutter/material.dart';
import 'package:zonix/models/order.dart';

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({Key? key}) : super(key: key);

  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  bool _isLoading = true;
  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Pendientes', 'En Camino', 'Entregadas'];
  
  List<Map<String, dynamic>> _deliveryOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveryOrders();
  }

  Future<void> _loadDeliveryOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos de entregas
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _deliveryOrders = [
          {
            'id': 1,
            'orderNumber': 'ORD-001',
            'customerName': 'Juan Pérez',
            'address': 'San José, Costa Rica',
            'phone': '+506 8888-8888',
            'status': 'pending',
            'statusText': 'Pendiente',
            'total': 15000.0,
            'items': ['Hamburguesa Clásica', 'Coca Cola'],
            'estimatedTime': '30 min',
            'distance': '2.5 km',
            'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
          },
          {
            'id': 2,
            'orderNumber': 'ORD-002',
            'customerName': 'María García',
            'address': 'Heredia, Costa Rica',
            'phone': '+506 7777-7777',
            'status': 'in_progress',
            'statusText': 'En Camino',
            'total': 8500.0,
            'items': ['Pizza Margherita'],
            'estimatedTime': '15 min',
            'distance': '1.8 km',
            'createdAt': DateTime.now().subtract(const Duration(minutes: 25)),
          },
          {
            'id': 3,
            'orderNumber': 'ORD-003',
            'customerName': 'Carlos López',
            'address': 'Alajuela, Costa Rica',
            'phone': '+506 6666-6666',
            'status': 'delivered',
            'statusText': 'Entregada',
            'total': 22000.0,
            'items': ['Hamburguesa Clásica', 'Papas Fritas', 'Tarta de Chocolate'],
            'estimatedTime': '0 min',
            'distance': '3.2 km',
            'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
          },
          {
            'id': 4,
            'orderNumber': 'ORD-004',
            'customerName': 'Ana Rodríguez',
            'address': 'Cartago, Costa Rica',
            'phone': '+506 5555-5555',
            'status': 'pending',
            'statusText': 'Pendiente',
            'total': 12000.0,
            'items': ['Pizza Margherita', 'Agua Mineral'],
            'estimatedTime': '45 min',
            'distance': '4.1 km',
            'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
          },
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar entregas: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'Todas') {
      return _deliveryOrders;
    }
    
    String statusFilter = '';
    switch (_selectedFilter) {
      case 'Pendientes':
        statusFilter = 'pending';
        break;
      case 'En Camino':
        statusFilter = 'in_progress';
        break;
      case 'Entregadas':
        statusFilter = 'delivered';
        break;
    }
    
    return _deliveryOrders.where((order) => order['status'] == statusFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor = _getStatusColor(order['status']);
    IconData statusIcon = _getStatusIcon(order['status']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con número de orden y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['orderNumber'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        order['statusText'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información del cliente
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order['phone'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _callCustomer(order['phone']),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Dirección
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['address'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.navigation, color: Colors.blue),
                  onPressed: () => _navigateToAddress(order['address']),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Items del pedido
            Text(
              'Items: ${order['items'].join(', ')}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Información de entrega y total
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ₡${order['total'].toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Distancia: ${order['distance']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tiempo: ${order['estimatedTime']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${order['createdAt'].hour}:${order['createdAt'].minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            if (order['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startDelivery(order),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Entrega'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(order),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            
            if (order['status'] == 'in_progress')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsDelivered(order),
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar Entregada'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactCustomer(order),
                      icon: const Icon(Icons.message),
                      label: const Text('Contactar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _callCustomer(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Llamando a $phone')),
    );
  }

  void _navigateToAddress(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando a $address')),
    );
  }

  void _startDelivery(Map<String, dynamic> order) {
    setState(() {
      order['status'] = 'in_progress';
      order['statusText'] = 'En Camino';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrega ${order['orderNumber']} iniciada')),
    );
  }

  void _rejectOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Entrega'),
        content: const Text('¿Estás seguro de que quieres rechazar esta entrega?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _deliveryOrders.remove(order);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Entrega ${order['orderNumber']} rechazada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _markAsDelivered(Map<String, dynamic> order) {
    setState(() {
      order['status'] = 'delivered';
      order['statusText'] = 'Entregada';
      order['estimatedTime'] = '0 min';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrega ${order['orderNumber']} completada')),
    );
  }

  void _contactCustomer(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contactando a ${order['customerName']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Estadísticas rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pendientes',
                          '${_deliveryOrders.where((o) => o['status'] == 'pending').length}',
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'En Camino',
                          '${_deliveryOrders.where((o) => o['status'] == 'in_progress').length}',
                          Icons.delivery_dining,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Entregadas',
                          '${_deliveryOrders.where((o) => o['status'] == 'delivered').length}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de entregas
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay entregas disponibles',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_filteredOrders[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 