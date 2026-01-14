import 'package:flutter/foundation.dart';
import 'package:zonix/models/commerce.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

/// Servicio para gestión de comercios/restaurantes
/// 
/// NOTA: Este servicio solo maneja operaciones relacionadas con comercios.
/// Para productos de comercio, usar CommerceProductService.
/// Para órdenes de comercio, usar CommerceOrderService.
class CommerceService extends ChangeNotifier {
  static String get baseUrl => AppConfig.apiUrl;
  
  // Mock data for development (fallback only)
  static final List<Commerce> _mockCommerces = [
    Commerce(
      id: 1,
      name: 'Restaurante El Sabor',
      description: 'Comida tradicional venezolana',
      address: 'Av. Principal 123, Lima',
      phone: '+51 123 456 789',
      email: 'info@pizzaexpress.com',
      logo: 'assets/default_avatar.png',
      isActive: true,
      category: 'Restaurante',
      rating: 4.5,
      reviewCount: 156,
      openingHours: '10:00 - 22:00',
      deliveryFee: 5.0,
      deliveryTime: 30,
      minimumOrder: 15.0,
      paymentMethods: ['Efectivo', 'Tarjeta', 'Transferencia'],
      cuisines: ['Pizza', 'Italiana', 'Pasta'],
      location: {'lat': -12.0464, 'lng': -77.0428},
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Commerce(
      id: 2,
      name: 'Café Central',
      description: 'Café y pastelería artesanal',
      address: 'Jr. Sushi 456, Lima',
      phone: '+51 987 654 321',
      email: 'contact@sushimaster.com',
      logo: 'assets/default_avatar.png',
      isActive: true,
      category: 'Restaurante',
      rating: 4.8,
      reviewCount: 89,
      openingHours: '11:00 - 23:00',
      deliveryFee: 7.0,
      deliveryTime: 25,
      minimumOrder: 20.0,
      paymentMethods: ['Efectivo', 'Tarjeta'],
      cuisines: ['Sushi', 'Japonesa', 'Asiática'],
      location: {'lat': -12.0464, 'lng': -77.0428},
      createdAt: DateTime.now().subtract(Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Obtener todos los comercios/restaurantes
  Future<List<Commerce>> getCommerces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerces'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => Commerce.fromJson(json)).toList();
        }
        // Try alternative format
        if (data['data'] != null) {
          return (data['data'] as List).map((json) => Commerce.fromJson(json)).toList();
        }
        return [];
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 500));
        return _mockCommerces;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 500));
      return _mockCommerces;
    }
  }

  /// Obtener un comercio por ID
  Future<Commerce> getCommerceById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/restaurants/$id'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Commerce.fromJson(data['data']);
        }
        throw Exception('Commerce not found');
      } else {
        throw Exception('Error fetching commerce: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 300));
      try {
        return _mockCommerces.firstWhere((c) => c.id == id);
      } catch (_) {
        throw Exception('Error fetching commerce: $e');
      }
    }
  }

  /// Obtener estadísticas del comercio
  /// 
  /// NOTA: Usa el endpoint /api/commerce/dashboard para obtener estadísticas
  Future<Map<String, dynamic>> getCommerceStatistics(int commerceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/dashboard'),
        headers: await AuthHelper.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        // Return empty stats if dashboard not implemented yet
        return {
          'total_orders': 0,
          'total_revenue': 0.0,
          'average_order_value': 0.0,
          'total_products': 0,
          'active_products': 0,
        };
      } else {
        // Fallback to mock data if endpoint not available
        await Future.delayed(Duration(milliseconds: 600));
        return {
          'total_orders': 156,
          'total_revenue': 23450.0,
          'average_order_value': 150.32,
          'total_products': 45,
          'active_products': 38,
          'total_customers': 89,
          'repeat_customers': 67,
          'average_rating': 4.6,
          'total_reviews': 234,
          'monthly_growth': 12.5,
        };
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'total_orders': 156,
        'total_revenue': 23450.0,
        'average_order_value': 150.32,
        'total_products': 45,
        'active_products': 38,
      };
    }
  }
}
