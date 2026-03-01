import 'package:flutter/material.dart';

class DeliveryRoutesPage extends StatefulWidget {
  const DeliveryRoutesPage({super.key});

  @override
  State<DeliveryRoutesPage> createState() => _DeliveryRoutesPageState();
}

class _DeliveryRoutesPageState extends State<DeliveryRoutesPage> {
  bool _isLoading = true;
  String _selectedRouteType = 'Optimizada';
  final List<String> _routeTypes = ['Optimizada', 'Manual', 'Por Zona'];
  
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _pendingDeliveries = [];

  @override
  void initState() {
    super.initState();
    _loadRoutesData();
  }

  Future<void> _loadRoutesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos de rutas
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _routes = [
          {
            'id': 1,
            'name': 'Ruta Centro',
            'type': 'optimized',
            'status': 'active',
            'totalDeliveries': 5,
            'completedDeliveries': 2,
            'totalDistance': 12.5,
            'estimatedTime': 45,
            'totalEarnings': 8500.0,
            'deliveries': [
              {
                'id': 1,
                'orderNumber': 'ORD-001',
                'customerName': 'Juan Pérez',
                'address': 'San José Centro',
                'status': 'completed',
                'sequence': 1,
                'distance': 2.5,
                'estimatedTime': 8,
              },
              {
                'id': 2,
                'orderNumber': 'ORD-002',
                'customerName': 'María García',
                'address': 'Barrio Escalante',
                'status': 'completed',
                'sequence': 2,
                'distance': 1.8,
                'estimatedTime': 6,
              },
              {
                'id': 3,
                'orderNumber': 'ORD-003',
                'customerName': 'Carlos López',
                'address': 'Los Yoses',
                'status': 'pending',
                'sequence': 3,
                'distance': 2.2,
                'estimatedTime': 7,
              },
            ],
          },
          {
            'id': 2,
            'name': 'Ruta Heredia',
            'type': 'manual',
            'status': 'pending',
            'totalDeliveries': 3,
            'completedDeliveries': 0,
            'totalDistance': 8.3,
            'estimatedTime': 30,
            'totalEarnings': 5200.0,
            'deliveries': [
              {
                'id': 4,
                'orderNumber': 'ORD-004',
                'customerName': 'Ana Rodríguez',
                'address': 'Heredia Centro',
                'status': 'pending',
                'sequence': 1,
                'distance': 3.1,
                'estimatedTime': 10,
              },
            ],
          },
        ];
        
        _pendingDeliveries = [
          {
            'id': 5,
            'orderNumber': 'ORD-005',
            'customerName': 'Luis Martínez',
            'address': 'Alajuela Centro',
            'distance': 4.2,
            'estimatedTime': 12,
            'priority': 'high',
          },
          {
            'id': 6,
            'orderNumber': 'ORD-006',
            'customerName': 'Carmen Vega',
            'address': 'Cartago Centro',
            'distance': 5.8,
            'estimatedTime': 18,
            'priority': 'medium',
          },
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar rutas: $e')),
      );
    }
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    Color statusColor = route['status'] == 'active' ? Colors.green : Colors.orange;
    String statusText = route['status'] == 'active' ? 'En Progreso' : 'Pendiente';
    
    double progress = route['totalDeliveries'] > 0 
        ? route['completedDeliveries'] / route['totalDeliveries'] 
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre de ruta y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${route['completedDeliveries']}/${route['totalDeliveries']} entregas',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barra de progreso
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            
            const SizedBox(height: 12),
            
            // Métricas de la ruta
            Row(
              children: [
                Expanded(
                  child: _buildRouteMetric(
                    'Distancia',
                    '${route['totalDistance']} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildRouteMetric(
                    'Tiempo',
                    '${route['estimatedTime']} min',
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildRouteMetric(
                    'Ganancia',
                    '\$${route['totalEarnings'].toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lista de entregas en la ruta
            const Text(
              'Entregas en esta ruta:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ...route['deliveries'].map<Widget>((delivery) {
              Color deliveryStatusColor = delivery['status'] == 'completed' 
                  ? Colors.green 
                  : Colors.orange;
              IconData deliveryStatusIcon = delivery['status'] == 'completed' 
                  ? Icons.check_circle 
                  : Icons.schedule;
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${delivery['sequence']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery['orderNumber'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            delivery['customerName'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            delivery['address'],
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
                        Icon(
                          deliveryStatusIcon,
                          color: deliveryStatusColor,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${delivery['distance']} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                if (route['status'] == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startRoute(route),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Ruta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (route['status'] == 'active')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewRouteMap(route),
                      icon: const Icon(Icons.map),
                      label: const Text('Ver Mapa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editRoute(route),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
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

  Widget _buildRouteMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingDeliveryCard(Map<String, dynamic> delivery) {
    Color priorityColor = delivery['priority'] == 'high' ? Colors.red : Colors.orange;
    String priorityText = delivery['priority'] == 'high' ? 'Alta' : 'Media';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withValues(alpha: 0.2),
          child: Icon(
            Icons.local_shipping,
            color: priorityColor,
            size: 20,
          ),
        ),
        title: Text(
          delivery['orderNumber'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(delivery['customerName']),
            Text(
              delivery['address'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priorityText,
                style: TextStyle(
                  fontSize: 10,
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${delivery['distance']} km',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _addToRoute(delivery),
      ),
    );
  }

  void _startRoute(Map<String, dynamic> route) {
    setState(() {
      route['status'] = 'active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ruta ${route['name']} iniciada')),
    );
  }

  void _viewRouteMap(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abriendo mapa de ${route['name']}')),
    );
  }

  void _editRoute(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${route['name']}'),
        content: const Text('Funcionalidad de edición de rutas en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _addToRoute(Map<String, dynamic> delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar a Ruta'),
        content: Text('¿Agregar ${delivery['orderNumber']} a una ruta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${delivery['orderNumber']} agregado a ruta')),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _optimizeRoutes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Optimizando rutas...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        actions: [
          // Filtro de tipo de ruta
          PopupMenuButton<String>(
            onSelected: (String type) {
              setState(() {
                _selectedRouteType = type;
              });
              _loadRoutesData();
            },
            itemBuilder: (BuildContext context) {
              return _routeTypes.map((String type) {
                return PopupMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedRouteType),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutesData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Estadísticas rápidas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Rutas Activas',
                          '${_routes.where((r) => r['status'] == 'active').length}',
                          Icons.route,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Pendientes',
                          '${_routes.where((r) => r['status'] == 'pending').length}',
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Entregas',
                          '${_pendingDeliveries.length}',
                          Icons.local_shipping,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botón de optimización
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _optimizeRoutes,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Optimizar Rutas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Entregas pendientes
                if (_pendingDeliveries.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Entregas Pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Toca para agregar a ruta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _pendingDeliveries.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPendingDeliveryCard(_pendingDeliveries[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Lista de rutas
                Expanded(
                  child: _routes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay rutas disponibles',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _routes.length,
                          itemBuilder: (context, index) {
                            return _buildRouteCard(_routes[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nueva ruta')),
          );
        },
        child: const Icon(Icons.add),
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