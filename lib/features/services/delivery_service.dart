import 'package:flutter/foundation.dart';
import 'package:zonix/models/order.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class DeliveryService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Error fetching delivery orders: ${response.statusCode}');
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
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifyListeners();
          return;
        }
        throw Exception('Error updating order status: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating order status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get available orders for delivery
  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/available-orders'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching available orders: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return _mockDeliveryOrders.where((order) => 
        order.status == 'ready' || order.status == 'confirmed'
      ).toList();
    }
  }

  // Get orders assigned to delivery agent
  Future<List<Order>> getAssignedOrders(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/assigned-orders/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching assigned orders: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      return _mockDeliveryOrders.where((order) => 
        order.deliveryAgentId == deliveryAgentId
      ).toList();
    }
  }

  // Accept order for delivery
  Future<Order> acceptOrder(int orderId, int deliveryAgentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/accept'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'notes': ''}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Order.fromJson(data['data']);
        }
        throw Exception('Error accepting order: Invalid response');
      } else {
        throw Exception('Error accepting order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  // Update delivery status
  Future<Order> updateDeliveryStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/status'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Order.fromJson(data['data']);
        }
        throw Exception('Error updating delivery status: Invalid response');
      } else {
        throw Exception('Error updating delivery status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery status: $e');
    }
  }

  // Get delivery history
  Future<List<Order>> getDeliveryHistory(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/history/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Order.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Error fetching delivery history: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
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
    }
  }

  // Get delivery earnings
  Future<Map<String, dynamic>> getDeliveryEarnings(int deliveryAgentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/api/delivery/earnings/$deliveryAgentId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery earnings: Invalid response');
      } else {
        throw Exception('Error fetching delivery earnings: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
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
        'today_earnings': totalEarnings * 0.3,
        'weekly_earnings': totalEarnings * 0.7,
        'monthly_earnings': totalEarnings,
        'delivery_fees': deliveredOrders.map((o) => o.deliveryFee).toList(),
        'delivery_dates': deliveredOrders.map((o) => o.createdAt.toIso8601String()).toList(),
      };
    }
  }

  // Get delivery routes
  Future<List<Map<String, dynamic>>> getDeliveryRoutes(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/routes/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error fetching delivery routes: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
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
    }
  }

  // Update delivery location
  Future<void> updateDeliveryLocation(int deliveryAgentId, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/location/update'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error updating delivery location: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error updating delivery location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery location: $e');
    }
  }

  // Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStatistics(int deliveryAgentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/delivery/statistics/$deliveryAgentId'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Error fetching delivery statistics: Invalid response');
      } else {
        throw Exception('Error fetching delivery statistics: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
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
    }
  }

  // Report delivery issue
  Future<void> reportDeliveryIssue(int orderId, String issue, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery/orders/$orderId/report-issue'),
        headers: await AuthHelper.getAuthHeaders(),
        body: jsonEncode({
          'issue': issue,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return;
        }
        throw Exception('Error reporting delivery issue: ${data['message'] ?? 'Unknown error'}');
      } else {
        throw Exception('Error reporting delivery issue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reporting delivery issue: $e');
    }
  }
} 