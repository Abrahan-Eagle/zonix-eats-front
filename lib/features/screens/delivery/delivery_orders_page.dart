import 'package:flutter/material.dart';
import 'package:zonix/features/services/delivery_service.dart';

class DeliveryOrdersPage extends StatefulWidget {
  @override
  _DeliveryOrdersPageState createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  final DeliveryService _deliveryService = DeliveryService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _deliveryService.getDeliveryOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'Todos') {
      return _orders;
    }
    
    String statusFilter = '';
    switch (_selectedFilter) {
      case 'Pendientes':
        statusFilter = 'pending';
        break;
      case 'En Progreso':
        statusFilter = 'in_progress';
        break;
      case 'Completadas':
        statusFilter = 'completed';
        break;
      case 'Canceladas':
        statusFilter = 'cancelled';
        break;
    }
    
    return _orders.where((order) => order['status'] == statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Órdenes de Delivery'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error: $_error'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: _filteredOrders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay órdenes disponibles',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = _filteredOrders[index];
                                  return _buildOrderCard(order);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Todos', 'Pendientes', 'En Progreso', 'Completadas', 'Canceladas'];
    
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green,
              backgroundColor: Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = _getStatusColor(order['status']);
    final statusText = _getStatusText(order['status']);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${order['order_number']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        order['customer_name'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfo('Restaurante', order['restaurant_name']),
                ),
                Expanded(
                  child: _buildOrderInfo('Total', '\$${order['total_amount'].toStringAsFixed(2)}'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfo('Dirección', order['delivery_address']),
                ),
                Expanded(
                  child: _buildOrderInfo('Distancia', '${order['distance'].toStringAsFixed(1)} km'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOrderInfo('Hora de Pedido', _formatDateTime(order['created_at'])),
                ),
                Expanded(
                  child: _buildOrderInfo('Tiempo Estimado', '${order['estimated_delivery_time']} min'),
                ),
              ],
            ),
            if (order['status'] == 'in_progress') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOrderInfo('Tiempo Restante', _calculateRemainingTime(order)),
                  ),
                  Expanded(
                    child: _buildOrderInfo('Conductor', order['driver_name'] ?? 'Asignando...'),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: Icon(Icons.info),
                    label: Text('Detalles'),
                  ),
                ),
                SizedBox(width: 8),
                if (order['status'] == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order),
                      icon: Icon(Icons.check),
                      label: Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (order['status'] == 'in_progress')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order),
                      icon: Icon(Icons.update),
                      label: Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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

  Widget _buildOrderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  String _calculateRemainingTime(Map<String, dynamic> order) {
    try {
      final created = DateTime.parse(order['created_at']);
      final estimatedMinutes = order['estimated_delivery_time'] ?? 30;
      final estimatedDelivery = created.add(Duration(minutes: estimatedMinutes));
      final now = DateTime.now();
      final remaining = estimatedDelivery.difference(now);
      
      if (remaining.isNegative) {
        return 'Atrasado';
      }
      
      final minutes = remaining.inMinutes;
      return '$minutes min';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de la Orden #${order['order_number']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cliente', order['customer_name']),
              _buildDetailRow('Teléfono', order['customer_phone']),
              _buildDetailRow('Restaurante', order['restaurant_name']),
              _buildDetailRow('Dirección', order['delivery_address']),
              _buildDetailRow('Total', '\$${order['total_amount'].toStringAsFixed(2)}'),
              _buildDetailRow('Estado', _getStatusText(order['status'])),
              _buildDetailRow('Distancia', '${order['distance'].toStringAsFixed(1)} km'),
              _buildDetailRow('Tiempo Estimado', '${order['estimated_delivery_time']} min'),
              _buildDetailRow('Hora de Pedido', order['created_at']),
              if (order['driver_name'] != null)
                _buildDetailRow('Conductor', order['driver_name']),
              if (order['notes'] != null && order['notes'].isNotEmpty)
                _buildDetailRow('Notas', order['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _acceptOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Aceptación'),
        content: Text('¿Estás seguro de que quieres aceptar la orden #${order['order_number']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatusToInProgress(order);
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatusToInProgress(Map<String, dynamic> order) async {
    try {
      await _deliveryService.updateOrderStatus(order['id'], 'in_progress');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orden aceptada exitosamente')),
      );
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar orden: $e')),
      );
    }
  }

  void _updateOrderStatus(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text('En Camino'),
              onTap: () => _updateStatus(order, 'in_progress'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Entregado'),
              onTap: () => _updateStatus(order, 'completed'),
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancelar'),
              onTap: () => _updateStatus(order, 'cancelled'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> order, String status) async {
    Navigator.pop(context);
    try {
      await _deliveryService.updateOrderStatus(order['id'], status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado exitosamente')),
      );
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    }
  }
} 