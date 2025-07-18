import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'package:zonix/models/order.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeliveryService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  
  // Mock data for development
  static final List<Order> _mockDeliveryOrders = [
    Order(
      id: 1,
      userId: 1,
      commerceId: 1,
      deliveryAgentId: 1,
      orderNumber: 'ORD-001',
      status: 'out_for_delivery',
      subtotal: 38.0,
      deliveryFee: 5.0,
      tax: 2.85,
      total: 45.85,
      paymentMethod: 'Tarjeta',
      paymentStatus: 'paid',
      deliveryAddress: 'Av. Lima 123, Lima',
      deliveryLocation: {'lat': -12.0464, 'lng': -77.0428},
      specialInstructions: 'Sin cebolla por favor',
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 15)),
      createdAt: DateTime.now().subtract(Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
      items: [
        OrderItem(
          id: 1,
          orderId: 1,
          productId: 1,
          productName: 'Pizza Margherita',
          productImage: 'assets/default_avatar.png',
          price: 18.0,
          quantity: 1,
          total: 18.0,
        ),
        OrderItem(
          id: 2,
          orderId: 1,
          productId: 2,
          productName: 'Pizza Pepperoni',
          productImage: 'assets/default_avatar.png',
          price: 20.0,
          quantity: 1,
          total: 20.0,
        ),
      ],
    ),
    Order(
      id: 2,
      userId: 2,
      commerceId: 2,
      deliveryAgentId: 1,
      orderNumber: 'ORD-002',
      status: 'ready',
      subtotal: 25.0,
      deliveryFee: 7.0,
      tax: 1.88,
      total: 33.88,
      paymentMethod: 'Efectivo',
      paymentStatus: 'pending',
      deliveryAddress: 'Jr. Comercio 456, Lima',
      deliveryLocation: {'lat': -12.0464, 'lng': -77.0428},
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 25)),
      createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
      items: [
        OrderItem(
          id: 3,
          orderId: 2,
          productId: 3,
          productName: 'Sushi California Roll',
          productImage: 'assets/default_avatar.png',
          price: 25.0,
          quantity: 1,
          total: 25.0,
        ),
      ],
    ),
    Order(
      id: 3,
      userId: 3,
      commerceId: 1,
      deliveryAgentId: 1,
      orderNumber: 'ORD-003',
      status: 'delivered',
      subtotal: 42.0,
      deliveryFee: 5.0,
      tax: 3.15,
      total: 50.15,
      paymentMethod: 'Tarjeta',
      paymentStatus: 'paid',
      deliveryAddress: 'Av. Arequipa 789, Lima',
      deliveryLocation: {'lat': -12.0464, 'lng': -77.0428},
      estimatedDeliveryTime: DateTime.now().subtract(Duration(minutes: 45)),
      actualDeliveryTime: DateTime.now().subtract(Duration(minutes: 30)),
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
      items: [
        OrderItem(
          id: 4,
          orderId: 3,
          productId: 1,
          productName: 'Pizza Margherita',
          productImage: 'assets/default_avatar.png',
          price: 18.0,
          quantity: 2,
          total: 36.0,
        ),
        OrderItem(
          id: 5,
          orderId: 3,
          productId: 2,
          productName: 'Pizza Pepperoni',
          productImage: 'assets/default_avatar.png',
          price: 20.0,
          quantity: 1,
          total: 20.0,
        ),
      ],
    ),
  ];

  // Get delivery orders (for DeliveryOrdersPage)
  Future<List<Map<String, dynamic>>> getDeliveryOrders() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 600));
        return _mockDeliveryOrders.map((order) => order.toJson()).toList();
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      return _mockDeliveryOrders.map((order) => order.toJson()).toList();
    }
  }

  // Update order status (for DeliveryOrdersPage)
  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.put('/delivery/orders/$orderId/status', {'status': status});
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      final index = _mockDeliveryOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = _mockDeliveryOrders[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          actualDeliveryTime: status == 'delivered' ? DateTime.now() : null,
        );
        _mockDeliveryOrders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get available orders for delivery
  Future<List<Order>> getAvailableOrders() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/available-orders');
      // return (response['data'] as List).map((json) => Order.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return _mockDeliveryOrders.where((order) => 
        order.status == 'ready' || order.status == 'confirmed'
      ).toList();
    } catch (e) {
      throw Exception('Error fetching available orders: $e');
    }
  }

  // Get orders assigned to delivery agent
  Future<List<Order>> getAssignedOrders(int deliveryAgentId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/assigned-orders/$deliveryAgentId');
      // return (response['data'] as List).map((json) => Order.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockDeliveryOrders.where((order) => 
        order.deliveryAgentId == deliveryAgentId
      ).toList();
    } catch (e) {
      throw Exception('Error fetching assigned orders: $e');
    }
  }

  // Accept order for delivery
  Future<Order> acceptOrder(int orderId, int deliveryAgentId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/delivery/accept-order', {
      //   'order_id': orderId,
      //   'delivery_agent_id': deliveryAgentId,
      // });
      // return Order.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final index = _mockDeliveryOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = _mockDeliveryOrders[index].copyWith(
          deliveryAgentId: deliveryAgentId,
          status: 'out_for_delivery',
          updatedAt: DateTime.now(),
        );
        _mockDeliveryOrders[index] = updatedOrder;
        return updatedOrder;
      }
      throw Exception('Order not found');
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  // Update delivery status
  Future<Order> updateDeliveryStatus(int orderId, String status) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.put('/delivery/update-status', {
      //   'order_id': orderId,
      //   'status': status,
      // });
      // return Order.fromJson(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final index = _mockDeliveryOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = _mockDeliveryOrders[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          actualDeliveryTime: status == 'delivered' ? DateTime.now() : null,
        );
        _mockDeliveryOrders[index] = updatedOrder;
        return updatedOrder;
      }
      throw Exception('Order not found');
    } catch (e) {
      throw Exception('Error updating delivery status: $e');
    }
  }

  // Get delivery history
  Future<List<Order>> getDeliveryHistory(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/history/$deliveryAgentId', {
      //   'start_date': startDate?.toIso8601String(),
      //   'end_date': endDate?.toIso8601String(),
      // });
      // return (response['data'] as List).map((json) => Order.fromJson(json)).toList();
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var orders = _mockDeliveryOrders.where((order) => 
        order.deliveryAgentId == deliveryAgentId && 
        (order.status == 'delivered' || order.status == 'cancelled')
      ).toList();
      
      if (startDate != null) {
        orders = orders.where((order) => order.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        orders = orders.where((order) => order.createdAt.isBefore(endDate)).toList();
      }
      
      return orders;
    } catch (e) {
      throw Exception('Error fetching delivery history: $e');
    }
  }

  // Get delivery earnings
  Future<Map<String, dynamic>> getDeliveryEarnings(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/earnings/$deliveryAgentId', {
      //   'start_date': startDate?.toIso8601String(),
      //   'end_date': endDate?.toIso8601String(),
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final deliveredOrders = _mockDeliveryOrders.where((order) => 
        order.deliveryAgentId == deliveryAgentId && 
        order.status == 'delivered'
      ).toList();
      
      double totalEarnings = 0;
      int totalDeliveries = deliveredOrders.length;
      double averageDeliveryTime = 0;
      
      for (var order in deliveredOrders) {
        totalEarnings += order.deliveryFee;
        if (order.actualDeliveryTime != null) {
          final deliveryTime = order.actualDeliveryTime!.difference(order.createdAt).inMinutes;
          averageDeliveryTime += deliveryTime;
        }
      }
      
      averageDeliveryTime = totalDeliveries > 0 ? averageDeliveryTime / totalDeliveries : 0;
      
      return {
        'total_earnings': totalEarnings,
        'total_deliveries': totalDeliveries,
        'average_delivery_time': averageDeliveryTime,
        'today_earnings': totalEarnings * 0.3, // Mock: 30% of total
        'weekly_earnings': totalEarnings * 0.7, // Mock: 70% of total
        'monthly_earnings': totalEarnings,
        'delivery_fees': deliveredOrders.map((o) => o.deliveryFee).toList(),
        'delivery_dates': deliveredOrders.map((o) => o.createdAt.toIso8601String()).toList(),
      };
    } catch (e) {
      throw Exception('Error fetching delivery earnings: $e');
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes(int deliveryAgentId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/routes/$deliveryAgentId');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      return [
        {
          'id': 1,
          'name': 'Ruta Centro',
          'orders': [1, 2],
          'estimated_time': 45,
          'total_distance': 8.5,
          'status': 'active',
          'start_location': {'lat': -12.0464, 'lng': -77.0428},
          'end_location': {'lat': -12.0464, 'lng': -77.0428},
        },
        {
          'id': 2,
          'name': 'Ruta Norte',
          'orders': [3],
          'estimated_time': 30,
          'total_distance': 5.2,
          'status': 'completed',
          'start_location': {'lat': -12.0464, 'lng': -77.0428},
          'end_location': {'lat': -12.0464, 'lng': -77.0428},
        },
      ];
    } catch (e) {
      throw Exception('Error fetching delivery routes: $e');
    }
  }

  // Update delivery location
  Future<void> updateDeliveryLocation(int deliveryAgentId, double lat, double lng) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/delivery/update-location', {
      //   'delivery_agent_id': deliveryAgentId,
      //   'latitude': lat,
      //   'longitude': lng,
      // });
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      // In a real implementation, this would update the delivery agent's location
    } catch (e) {
      throw Exception('Error updating delivery location: $e');
    }
  }

  // Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStatistics(int deliveryAgentId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/delivery/statistics/$deliveryAgentId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_deliveries': 156,
        'completed_deliveries': 142,
        'cancelled_deliveries': 14,
        'total_earnings': 2340.0,
        'average_rating': 4.7,
        'total_reviews': 89,
        'on_time_deliveries': 138,
        'late_deliveries': 4,
        'average_delivery_time': 28,
        'total_distance': 1250.5,
        'fuel_efficiency': 85.2,
        'customer_satisfaction': 92.5,
        'weekly_performance': [
          {'day': 'Lunes', 'deliveries': 12, 'earnings': 180.0},
          {'day': 'Martes', 'deliveries': 15, 'earnings': 225.0},
          {'day': 'Miércoles', 'deliveries': 18, 'earnings': 270.0},
          {'day': 'Jueves', 'deliveries': 14, 'earnings': 210.0},
          {'day': 'Viernes', 'deliveries': 22, 'earnings': 330.0},
          {'day': 'Sábado', 'deliveries': 25, 'earnings': 375.0},
          {'day': 'Domingo', 'deliveries': 20, 'earnings': 300.0},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching delivery statistics: $e');
    }
  }

  // Report delivery issue
  Future<void> reportDeliveryIssue(int orderId, String issue, String description) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/delivery/report-issue', {
      //   'order_id': orderId,
      //   'issue': issue,
      //   'description': description,
      // });
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      // In a real implementation, this would create a support ticket
    } catch (e) {
      throw Exception('Error reporting delivery issue: $e');
    }
  }
} 