import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class TrackingService {
  // GET /api/buyer/orders/{orderId}/tracking - Obtener tracking de la orden
  Future<Map<String, dynamic>> getOrderTracking(int orderId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/orders/$orderId/tracking');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Error al obtener tracking');
      }
    } else {
      throw Exception('Error al obtener tracking: ${response.statusCode}');
    }
  }

  // POST /api/buyer/orders/{orderId}/tracking/location - Actualizar ubicación de entrega
  Future<void> updateDeliveryLocation(int orderId, double latitude, double longitude) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/orders/$orderId/tracking/location');
    final response = await http.post(
      url,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al actualizar ubicación');
      }
    } else {
      throw Exception('Error al actualizar ubicación: ${response.statusCode}');
    }
  }

  // Método para obtener el estado actual de la orden
  Future<String> getOrderStatus(int orderId) async {
    try {
      final tracking = await getOrderTracking(orderId);
      return tracking['status'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Método para obtener la ubicación del delivery
  Future<Map<String, double>?> getDeliveryLocation(int orderId) async {
    try {
      final tracking = await getOrderTracking(orderId);
      final location = tracking['delivery_location'];
      if (location != null) {
        return {
          'latitude': (location['latitude'] is String)
              ? double.tryParse(location['latitude']) ?? 0.0
              : (location['latitude'] is int)
                  ? (location['latitude'] as int).toDouble()
                  : (location['latitude'] is double)
                      ? location['latitude']
                      : 0.0,
          'longitude': (location['longitude'] is String)
              ? double.tryParse(location['longitude']) ?? 0.0
              : (location['longitude'] is int)
                  ? (location['longitude'] as int).toDouble()
                  : (location['longitude'] is double)
                      ? location['longitude']
                      : 0.0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Método para obtener el tiempo estimado de llegada
  Future<String?> getEstimatedArrival(int orderId) async {
    try {
      final tracking = await getOrderTracking(orderId);
      return tracking['estimated_arrival'];
    } catch (e) {
      return null;
    }
  }

  // Método para obtener información del delivery
  Future<Map<String, dynamic>?> getDeliveryInfo(int orderId) async {
    try {
      final tracking = await getOrderTracking(orderId);
      return tracking['delivery_info'];
    } catch (e) {
      return null;
    }
  }
} 