import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class BuyerTrackingService {
  final Logger _logger = Logger();

  // GET /api/buyer/tracking/order/{orderId} - Obtener estado de la orden
  Future<Map<String, dynamic>> getOrderStatus(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/tracking/order/$orderId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al obtener estado de la orden');
        }
      } else {
        throw Exception('Error al obtener estado de la orden: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getOrderStatus: $e');
      throw Exception('Error al obtener estado de la orden: $e');
    }
  }

  // GET /api/buyer/tracking/delivery-agent/{orderId} - Obtener ubicación del agente de delivery
  Future<Map<String, dynamic>> getDeliveryAgentLocation(int orderId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/tracking/delivery-agent/$orderId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al obtener ubicación del agente');
        }
      } else {
        throw Exception('Error al obtener ubicación del agente: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getDeliveryAgentLocation: $e');
      throw Exception('Error al obtener ubicación del agente: $e');
    }
  }

  // PUT /api/buyer/tracking/order/{orderId}/status - Actualizar estado de la orden
  Future<bool> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/tracking/order/$orderId/status');
      
      final body = {
        'status': status,
        if (notes != null) 'notes': notes,
        if (metadata != null) 'metadata': metadata,
      };
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Error al actualizar estado de la orden: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en updateOrderStatus: $e');
      throw Exception('Error al actualizar estado de la orden: $e');
    }
  }
} 