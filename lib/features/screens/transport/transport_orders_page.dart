import 'package:flutter/material.dart';

class TransportOrdersPage extends StatefulWidget {
  const TransportOrdersPage({super.key});

  @override
  State<TransportOrdersPage> createState() => _TransportOrdersPageState();
}

class _TransportOrdersPageState extends State<TransportOrdersPage> {
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Pendientes', 'En Progreso', 'Completados', 'Cancelados'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                const Text('Filtrar por: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filters.map((filter) {
                      return DropdownMenuItem(value: filter, child: Text(filter));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Orders List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20,
              itemBuilder: (context, index) {
                return _buildOrderCard(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAssignDriverDialog(context);
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrderCard(int index) {
    final orderStatus = ['Pendiente', 'En Progreso', 'Completado', 'Cancelado'][index % 4];
    final isUrgent = index % 5 == 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getStatusColor(orderStatus),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${1000 + index}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      orderStatus,
                      style: TextStyle(
                        color: _getStatusColor(orderStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (isUrgent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('URGENTE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restaurante: Pizza Express - Calle Principal 123',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cliente: Juan Pérez - Av. Libertad 456',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tiempo estimado: ${15 + (index % 30)} min',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '\$${(15 + index * 2).toDouble()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showOrderDetails(context, index);
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Ver Detalles'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAssignDriverDialog(context);
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Asignar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Progreso':
        return Colors.blue;
      case 'Completado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(BuildContext context, int orderIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Pedido #${1000 + orderIndex}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Estado', 'En Progreso'),
              _buildDetailRow('Restaurante', 'Pizza Express'),
              _buildDetailRow('Cliente', 'Juan Pérez'),
              _buildDetailRow('Teléfono', '+1234567890'),
              _buildDetailRow('Dirección', 'Av. Libertad 456, Ciudad'),
              _buildDetailRow('Tiempo Estimado', '25 minutos'),
              _buildDetailRow('Distancia', '2.5 km'),
              _buildDetailRow('Monto', '\$25.00'),
              const SizedBox(height: 16),
              const Text('Items del Pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildOrderItem('Pizza Margherita', '1x', '\$15.00'),
              _buildOrderItem('Bebida Cola', '2x', '\$5.00'),
              _buildOrderItem('Ensalada César', '1x', '\$5.00'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String quantity, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name)),
          Text(quantity),
          Text(price),
        ],
      ),
    );
  }

  void _showAssignDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Conductor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona un conductor disponible:'),
            const SizedBox(height: 16),
            _buildDriverOption('Carlos Rodríguez', 'Disponible', Icons.check_circle, Colors.green),
            _buildDriverOption('María González', 'En ruta', Icons.schedule, Colors.orange),
            _buildDriverOption('Luis Fernández', 'Disponible', Icons.check_circle, Colors.green),
            _buildDriverOption('Ana Martínez', 'Descanso', Icons.pause_circle, Colors.grey),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conductor asignado exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Asignar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverOption(String name, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(name),
      subtitle: Text(status),
      trailing: Radio<String>(
        value: name,
        groupValue: null,
        onChanged: (value) {},
      ),
    );
  }
} 