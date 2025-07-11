import 'package:flutter/material.dart';

class TransportFleetPage extends StatefulWidget {
  const TransportFleetPage({Key? key}) : super(key: key);

  @override
  State<TransportFleetPage> createState() => _TransportFleetPageState();
}

class _TransportFleetPageState extends State<TransportFleetPage> {
  bool _isLoading = true;
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Activos', 'En Mantenimiento', 'Fuera de Servicio'];
  
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos de la flota
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _vehicles = [
          {
            'id': 1,
            'plate': 'ABC-123',
            'model': 'Toyota Hiace',
            'year': 2020,
            'capacity': 12,
            'status': 'active',
            'statusText': 'Activo',
            'driver': 'Juan Pérez',
            'driverPhone': '+506 8888-8888',
            'currentLocation': 'San José Centro',
            'fuelLevel': 85,
            'lastMaintenance': DateTime.now().subtract(const Duration(days: 15)),
            'nextMaintenance': DateTime.now().add(const Duration(days: 15)),
            'totalDeliveries': 45,
            'totalDistance': 1250.5,
            'image': 'https://via.placeholder.com/150',
          },
          {
            'id': 2,
            'plate': 'XYZ-789',
            'model': 'Ford Transit',
            'year': 2019,
            'capacity': 15,
            'status': 'maintenance',
            'statusText': 'Mantenimiento',
            'driver': 'María García',
            'driverPhone': '+506 7777-7777',
            'currentLocation': 'Taller Central',
            'fuelLevel': 20,
            'lastMaintenance': DateTime.now().subtract(const Duration(days: 2)),
            'nextMaintenance': DateTime.now().add(const Duration(days: 28)),
            'totalDeliveries': 38,
            'totalDistance': 980.2,
            'image': 'https://via.placeholder.com/150',
          },
          {
            'id': 3,
            'plate': 'DEF-456',
            'model': 'Mercedes Sprinter',
            'year': 2021,
            'capacity': 18,
            'status': 'active',
            'statusText': 'Activo',
            'driver': 'Carlos López',
            'driverPhone': '+506 6666-6666',
            'currentLocation': 'Heredia Centro',
            'fuelLevel': 65,
            'lastMaintenance': DateTime.now().subtract(const Duration(days: 30)),
            'nextMaintenance': DateTime.now().add(const Duration(days: 0)),
            'totalDeliveries': 52,
            'totalDistance': 1450.8,
            'image': 'https://via.placeholder.com/150',
          },
          {
            'id': 4,
            'plate': 'GHI-789',
            'model': 'Nissan NV200',
            'year': 2018,
            'capacity': 8,
            'status': 'inactive',
            'statusText': 'Fuera de Servicio',
            'driver': 'Ana Rodríguez',
            'driverPhone': '+506 5555-5555',
            'currentLocation': 'Depósito',
            'fuelLevel': 0,
            'lastMaintenance': DateTime.now().subtract(const Duration(days: 60)),
            'nextMaintenance': DateTime.now().add(const Duration(days: 30)),
            'totalDeliveries': 25,
            'totalDistance': 650.3,
            'image': 'https://via.placeholder.com/150',
          },
        ];
        
        _drivers = [
          {
            'id': 1,
            'name': 'Juan Pérez',
            'phone': '+506 8888-8888',
            'license': 'B1-123456',
            'status': 'active',
            'statusText': 'Activo',
            'vehicle': 'ABC-123',
            'rating': 4.8,
            'totalDeliveries': 45,
            'totalDistance': 1250.5,
            'experience': '3 años',
            'image': 'https://via.placeholder.com/150',
          },
          {
            'id': 2,
            'name': 'María García',
            'phone': '+506 7777-7777',
            'license': 'B1-789012',
            'status': 'maintenance',
            'statusText': 'En Mantenimiento',
            'vehicle': 'XYZ-789',
            'rating': 4.6,
            'totalDeliveries': 38,
            'totalDistance': 980.2,
            'experience': '2 años',
            'image': 'https://via.placeholder.com/150',
          },
          {
            'id': 3,
            'name': 'Carlos López',
            'phone': '+506 6666-6666',
            'license': 'B1-345678',
            'status': 'active',
            'statusText': 'Activo',
            'vehicle': 'DEF-456',
            'rating': 4.9,
            'totalDeliveries': 52,
            'totalDistance': 1450.8,
            'experience': '4 años',
            'image': 'https://via.placeholder.com/150',
          },
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar flota: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_selectedFilter == 'Todos') {
      return _vehicles;
    }
    
    String statusFilter = '';
    switch (_selectedFilter) {
      case 'Activos':
        statusFilter = 'active';
        break;
      case 'En Mantenimiento':
        statusFilter = 'maintenance';
        break;
      case 'Fuera de Servicio':
        statusFilter = 'inactive';
        break;
    }
    
    return _vehicles.where((vehicle) => vehicle['status'] == statusFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    Color statusColor = _getStatusColor(vehicle['status']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con placa y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle['plate'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vehicle['statusText'],
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
            
            // Información del vehículo
            Row(
              children: [
                // Imagen del vehículo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    vehicle['image'],
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.directions_car, color: Colors.grey),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Detalles del vehículo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['model'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Año: ${vehicle['year']} • Capacidad: ${vehicle['capacity']} personas',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Conductor
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            vehicle['driver'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green, size: 16),
                            onPressed: () => _callDriver(vehicle['driverPhone']),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ubicación actual
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vehicle['currentLocation'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.navigation, color: Colors.blue, size: 16),
                  onPressed: () => _trackVehicle(vehicle),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Métricas del vehículo
            Row(
              children: [
                Expanded(
                  child: _buildVehicleMetric(
                    'Combustible',
                    '${vehicle['fuelLevel']}%',
                    Icons.local_gas_station,
                    vehicle['fuelLevel'] > 20 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildVehicleMetric(
                    'Entregas',
                    '${vehicle['totalDeliveries']}',
                    Icons.delivery_dining,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildVehicleMetric(
                    'Distancia',
                    '${vehicle['totalDistance'].toStringAsFixed(0)} km',
                    Icons.straighten,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mantenimiento
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próximo Mantenimiento',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${vehicle['nextMaintenance'].day}/${vehicle['nextMaintenance'].month}/${vehicle['nextMaintenance'].year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vehicle['nextMaintenance'].difference(DateTime.now()).inDays <= 7)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '¡URGENTE!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewVehicleDetails(vehicle),
                    icon: const Icon(Icons.info),
                    label: const Text('Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scheduleMaintenance(vehicle),
                    icon: const Icon(Icons.build),
                    label: const Text('Mantenimiento'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
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

  Widget _buildVehicleMetric(String title, String value, IconData icon, Color color) {
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

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    Color statusColor = _getStatusColor(driver['status']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(driver['image']),
          onBackgroundImageError: (exception, stackTrace) {
            // Handle error
          },
          child: driver['image'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text(
          driver['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Licencia: ${driver['license']}'),
            Text('Vehículo: ${driver['vehicle']}'),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${driver['rating']} • ${driver['experience']}'),
              ],
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
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                driver['statusText'],
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${driver['totalDeliveries']} entregas',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _viewDriverDetails(driver),
      ),
    );
  }

  void _callDriver(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Llamando a $phone')),
    );
  }

  void _trackVehicle(Map<String, dynamic> vehicle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rastreando ${vehicle['plate']}')),
    );
  }

  void _viewVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${vehicle['plate']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modelo: ${vehicle['model']}'),
            Text('Año: ${vehicle['year']}'),
            Text('Capacidad: ${vehicle['capacity']} personas'),
            Text('Conductor: ${vehicle['driver']}'),
            Text('Estado: ${vehicle['statusText']}'),
            Text('Combustible: ${vehicle['fuelLevel']}%'),
            Text('Total entregas: ${vehicle['totalDeliveries']}'),
            Text('Distancia total: ${vehicle['totalDistance'].toStringAsFixed(0)} km'),
          ],
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

  void _scheduleMaintenance(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agendar Mantenimiento'),
        content: Text('¿Agendar mantenimiento para ${vehicle['plate']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mantenimiento agendado para ${vehicle['plate']}')),
              );
            },
            child: const Text('Agendar'),
          ),
        ],
      ),
    );
  }

  void _viewDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${driver['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Licencia: ${driver['license']}'),
            Text('Teléfono: ${driver['phone']}'),
            Text('Vehículo: ${driver['vehicle']}'),
            Text('Calificación: ${driver['rating']}/5'),
            Text('Experiencia: ${driver['experience']}'),
            Text('Total entregas: ${driver['totalDeliveries']}'),
            Text('Distancia total: ${driver['totalDistance'].toStringAsFixed(0)} km'),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFleetData,
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
                          'Activos',
                          '${_vehicles.where((v) => v['status'] == 'active').length}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Mantenimiento',
                          '${_vehicles.where((v) => v['status'] == 'maintenance').length}',
                          Icons.build,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Conductores',
                          '${_drivers.length}',
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Conductores
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Conductores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Toca para ver detalles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildDriverCard(_drivers[index]),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de vehículos
                Expanded(
                  child: _filteredVehicles.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay vehículos disponibles',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredVehicles.length,
                          itemBuilder: (context, index) {
                            return _buildVehicleCard(_filteredVehicles[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregar nuevo vehículo')),
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