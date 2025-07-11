import 'package:flutter/material.dart';
import 'package:zonix/features/services/transport_service.dart';

class TransportFleetPage extends StatefulWidget {
  @override
  _TransportFleetPageState createState() => _TransportFleetPageState();
}

class _TransportFleetPageState extends State<TransportFleetPage> {
  final TransportService _transportService = TransportService();
  List<Map<String, dynamic>> _fleet = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final fleet = await _transportService.getFleet();
      setState(() {
        _fleet = fleet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Flota'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(),
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
                        onPressed: _loadFleet,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFleet,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _fleet.length,
                    itemBuilder: (context, index) {
                      final vehicle = _fleet[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final statusColor = _getStatusColor(vehicle['status']);
    final fuelColor = _getFuelColor(vehicle['fuel_level']);

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
                        vehicle['vehicle_type'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        vehicle['license_plate'],
                        style: TextStyle(
                          fontSize: 16,
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
                    _getStatusText(vehicle['status']),
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
                  child: _buildInfoItem('Modelo', vehicle['model']),
                ),
                Expanded(
                  child: _buildInfoItem('Año', vehicle['year'].toString()),
                ),
                Expanded(
                  child: _buildInfoItem('Capacidad', vehicle['capacity']),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Conductor', vehicle['driver_name']),
                ),
                Expanded(
                  child: _buildInfoItem('Teléfono', vehicle['driver_phone']),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFuelIndicator(vehicle['fuel_level'], fuelColor),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem('Viajes', vehicle['total_trips'].toString()),
                ),
                Expanded(
                  child: _buildInfoItem('Distancia', '${vehicle['total_distance'].toStringAsFixed(1)} km'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRatingStars(vehicle['rating']),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem('Mantenimiento', vehicle['maintenance_due']),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showVehicleDetails(vehicle),
                    icon: Icon(Icons.info),
                    label: Text('Detalles'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditVehicleDialog(vehicle),
                    icon: Icon(Icons.edit),
                    label: Text('Editar'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(vehicle),
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
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
        ),
      ],
    );
  }

  Widget _buildFuelIndicator(int fuelLevel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Combustible',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: fuelLevel / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '$fuelLevel%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calificación',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            );
          })..addAll([
            SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'maintenance':
        return 'Mantenimiento';
      case 'inactive':
        return 'Inactivo';
      default:
        return 'Desconocido';
    }
  }

  Color _getFuelColor(int fuelLevel) {
    if (fuelLevel > 70) return Colors.green;
    if (fuelLevel > 30) return Colors.orange;
    return Colors.red;
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Vehículo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', vehicle['vehicle_type']),
              _buildDetailRow('Placa', vehicle['license_plate']),
              _buildDetailRow('Modelo', vehicle['model']),
              _buildDetailRow('Año', vehicle['year'].toString()),
              _buildDetailRow('Capacidad', vehicle['capacity']),
              _buildDetailRow('Conductor', vehicle['driver_name']),
              _buildDetailRow('Teléfono', vehicle['driver_phone']),
              _buildDetailRow('Estado', _getStatusText(vehicle['status'])),
              _buildDetailRow('Combustible', '${vehicle['fuel_level']}%'),
              _buildDetailRow('Total Viajes', vehicle['total_trips'].toString()),
              _buildDetailRow('Distancia Total', '${vehicle['total_distance'].toStringAsFixed(1)} km'),
              _buildDetailRow('Calificación', vehicle['rating'].toString()),
              _buildDetailRow('Mantenimiento', vehicle['maintenance_due']),
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

  void _showAddVehicleDialog() {
    // TODO: Implement add vehicle dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de agregar vehículo en desarrollo')),
    );
  }

  void _showEditVehicleDialog(Map<String, dynamic> vehicle) {
    // TODO: Implement edit vehicle dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de editar vehículo en desarrollo')),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el vehículo ${vehicle['license_plate']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVehicle(vehicle['id']);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await _transportService.deleteVehicle(vehicleId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo eliminado exitosamente')),
      );
      _loadFleet();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar vehículo: $e')),
      );
    }
  }
} 