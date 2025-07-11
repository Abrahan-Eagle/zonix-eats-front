import 'package:zonix/models/order.dart';
import 'package:zonix/features/services/auth/api_service.dart';

class TransportService {
  final ApiService _apiService = ApiService();
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockFleet = [
    {
      'id': 1,
      'vehicle_type': 'Camión',
      'license_plate': 'ABC-123',
      'model': 'Ford Transit',
      'year': 2022,
      'capacity': '2 toneladas',
      'driver_name': 'Juan Pérez',
      'driver_phone': '+51 123 456 789',
      'status': 'active',
      'current_location': {'lat': -12.0464, 'lng': -77.0428},
      'fuel_level': 85,
      'maintenance_due': '2024-02-15',
      'total_trips': 156,
      'total_distance': 12500.5,
      'rating': 4.7,
    },
    {
      'id': 2,
      'vehicle_type': 'Furgoneta',
      'license_plate': 'XYZ-789',
      'model': 'Mercedes Sprinter',
      'year': 2021,
      'capacity': '1.5 toneladas',
      'driver_name': 'María González',
      'driver_phone': '+51 987 654 321',
      'status': 'maintenance',
      'current_location': {'lat': -12.0464, 'lng': -77.0428},
      'fuel_level': 45,
      'maintenance_due': '2024-01-20',
      'total_trips': 89,
      'total_distance': 7800.2,
      'rating': 4.5,
    },
    {
      'id': 3,
      'vehicle_type': 'Moto',
      'license_plate': 'MOT-456',
      'model': 'Honda CG 150',
      'year': 2023,
      'capacity': '50 kg',
      'driver_name': 'Carlos Rodríguez',
      'driver_phone': '+51 456 789 123',
      'status': 'active',
      'current_location': {'lat': -12.0464, 'lng': -77.0428},
      'fuel_level': 90,
      'maintenance_due': '2024-03-10',
      'total_trips': 234,
      'total_distance': 8900.8,
      'rating': 4.8,
    },
  ];

  static final List<Map<String, dynamic>> _mockTransportOrders = [
    {
      'id': 1,
      'order_number': 'TR-001',
      'vehicle_id': 1,
      'driver_name': 'Juan Pérez',
      'origin': 'Almacén Central',
      'destination': 'Tienda Centro',
      'cargo_type': 'Productos alimenticios',
      'weight': '500 kg',
      'status': 'in_transit',
      'estimated_delivery': '2024-01-15T14:30:00',
      'actual_delivery': null,
      'distance': 25.5,
      'fuel_cost': 45.0,
      'created_at': '2024-01-15T10:00:00',
    },
    {
      'id': 2,
      'order_number': 'TR-002',
      'vehicle_id': 2,
      'driver_name': 'María González',
      'origin': 'Almacén Norte',
      'destination': 'Tienda Sur',
      'cargo_type': 'Electrónicos',
      'weight': '300 kg',
      'status': 'completed',
      'estimated_delivery': '2024-01-15T16:00:00',
      'actual_delivery': '2024-01-15T15:45:00',
      'distance': 18.2,
      'fuel_cost': 32.0,
      'created_at': '2024-01-15T12:00:00',
    },
    {
      'id': 3,
      'order_number': 'TR-003',
      'vehicle_id': 3,
      'driver_name': 'Carlos Rodríguez',
      'origin': 'Almacén Este',
      'destination': 'Cliente VIP',
      'cargo_type': 'Documentos urgentes',
      'weight': '2 kg',
      'status': 'pending',
      'estimated_delivery': '2024-01-15T18:00:00',
      'actual_delivery': null,
      'distance': 8.5,
      'fuel_cost': 15.0,
      'created_at': '2024-01-15T16:00:00',
    },
  ];

  // Get fleet vehicles
  Future<List<Map<String, dynamic>>> getFleet() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/fleet');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return _mockFleet;
    } catch (e) {
      throw Exception('Error fetching fleet: $e');
    }
  }

  // Get vehicle by ID
  Future<Map<String, dynamic>> getVehicleById(int id) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/fleet/$id');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final vehicle = _mockFleet.firstWhere((v) => v['id'] == id);
      return vehicle;
    } catch (e) {
      throw Exception('Error fetching vehicle: $e');
    }
  }

  // Add new vehicle
  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/transport/fleet', vehicleData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final newVehicle = {
        ...vehicleData,
        'id': _mockFleet.length + 1,
        'total_trips': 0,
        'total_distance': 0.0,
        'rating': 0.0,
      };
      _mockFleet.add(newVehicle);
      return newVehicle;
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  // Update vehicle
  Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> vehicleData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/transport/fleet/$id', vehicleData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockFleet.indexWhere((v) => v['id'] == id);
      if (index != -1) {
        _mockFleet[index] = {..._mockFleet[index], ...vehicleData};
        return _mockFleet[index];
      }
      throw Exception('Vehicle not found');
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  // Delete vehicle
  Future<void> deleteVehicle(int id) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.delete('/transport/fleet/$id');
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      _mockFleet.removeWhere((v) => v['id'] == id);
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  // Get transport orders
  Future<List<Map<String, dynamic>>> getTransportOrders() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/orders');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockTransportOrders;
    } catch (e) {
      throw Exception('Error fetching transport orders: $e');
    }
  }

  // Get transport order by ID
  Future<Map<String, dynamic>> getTransportOrderById(int id) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/orders/$id');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final order = _mockTransportOrders.firstWhere((o) => o['id'] == id);
      return order;
    } catch (e) {
      throw Exception('Error fetching transport order: $e');
    }
  }

  // Create transport order
  Future<Map<String, dynamic>> createTransportOrder(Map<String, dynamic> orderData) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/transport/orders', orderData);
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final newOrder = {
        ...orderData,
        'id': _mockTransportOrders.length + 1,
        'order_number': 'TR-${(_mockTransportOrders.length + 1).toString().padLeft(3, '0')}',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      _mockTransportOrders.add(newOrder);
      return newOrder;
    } catch (e) {
      throw Exception('Error creating transport order: $e');
    }
  }

  // Update transport order status
  Future<Map<String, dynamic>> updateTransportOrderStatus(int id, String status) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/transport/orders/$id/status', {'status': status});
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockTransportOrders.indexWhere((o) => o['id'] == id);
      if (index != -1) {
        _mockTransportOrders[index]['status'] = status;
        if (status == 'completed') {
          _mockTransportOrders[index]['actual_delivery'] = DateTime.now().toIso8601String();
        }
        return _mockTransportOrders[index];
      }
      throw Exception('Transport order not found');
    } catch (e) {
      throw Exception('Error updating transport order status: $e');
    }
  }

  // Get transport analytics
  Future<Map<String, dynamic>> getTransportAnalytics() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/analytics');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_vehicles': _mockFleet.length,
        'active_vehicles': _mockFleet.where((v) => v['status'] == 'active').length,
        'total_orders': _mockTransportOrders.length,
        'completed_orders': _mockTransportOrders.where((o) => o['status'] == 'completed').length,
        'total_distance': 23450.5,
        'total_fuel_cost': 1250.0,
        'average_delivery_time': 45,
        'on_time_deliveries': 89,
        'late_deliveries': 12,
        'fuel_efficiency': 85.2,
        'maintenance_alerts': 3,
        'monthly_performance': [
          {'month': 'Enero', 'orders': 45, 'distance': 1250.5, 'cost': 450.0},
          {'month': 'Febrero', 'orders': 52, 'distance': 1380.2, 'cost': 520.0},
          {'month': 'Marzo', 'orders': 48, 'distance': 1290.8, 'cost': 480.0},
        ],
        'vehicle_performance': _mockFleet.map((v) => {
          'vehicle': v['license_plate'],
          'trips': v['total_trips'],
          'distance': v['total_distance'],
          'rating': v['rating'],
        }).toList(),
      };
    } catch (e) {
      throw Exception('Error fetching transport analytics: $e');
    }
  }

  // Get maintenance schedule
  Future<List<Map<String, dynamic>>> getMaintenanceSchedule() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/maintenance');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockFleet.map((v) => {
        'vehicle_id': v['id'],
        'license_plate': v['license_plate'],
        'vehicle_type': v['vehicle_type'],
        'maintenance_due': v['maintenance_due'],
        'last_maintenance': '2024-01-01',
        'next_maintenance': v['maintenance_due'],
        'status': DateTime.parse(v['maintenance_due']).isBefore(DateTime.now()) ? 'overdue' : 'scheduled',
      }).toList();
    } catch (e) {
      throw Exception('Error fetching maintenance schedule: $e');
    }
  }

  // Update vehicle location
  Future<void> updateVehicleLocation(int vehicleId, double lat, double lng) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/transport/update-location', {
      //   'vehicle_id': vehicleId,
      //   'latitude': lat,
      //   'longitude': lng,
      // });
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      final index = _mockFleet.indexWhere((v) => v['id'] == vehicleId);
      if (index != -1) {
        _mockFleet[index]['current_location'] = {'lat': lat, 'lng': lng};
      }
    } catch (e) {
      throw Exception('Error updating vehicle location: $e');
    }
  }

  // Get driver performance
  Future<Map<String, dynamic>> getDriverPerformance(int driverId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/transport/drivers/$driverId/performance');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return {
        'driver_id': driverId,
        'driver_name': 'Juan Pérez',
        'total_trips': 156,
        'completed_trips': 142,
        'total_distance': 12500.5,
        'average_rating': 4.7,
        'total_reviews': 89,
        'on_time_deliveries': 138,
        'late_deliveries': 4,
        'fuel_efficiency': 85.2,
        'safety_score': 92.5,
        'monthly_performance': [
          {'month': 'Enero', 'trips': 45, 'distance': 1250.5, 'rating': 4.8},
          {'month': 'Febrero', 'trips': 52, 'distance': 1380.2, 'rating': 4.6},
          {'month': 'Marzo', 'trips': 48, 'distance': 1290.8, 'rating': 4.7},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching driver performance: $e');
    }
  }
} 