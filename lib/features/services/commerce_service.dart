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
        throw Exception('Error al obtener comercios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
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
      rethrow;
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
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
