import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class BuyerReviewService {
  final Logger _logger = Logger();

  // POST /api/buyer/reviews/restaurant - Calificar restaurante
  Future<Map<String, dynamic>> rateRestaurant({
    required int commerceId,
    required double rating,
    required String comment,
    Map<String, dynamic>? criteria,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/restaurant');
      
      final body = {
        'commerce_id': commerceId,
        'rating': rating,
        'comment': comment,
        if (criteria != null) 'criteria': criteria,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al calificar restaurante');
        }
      } else {
        throw Exception('Error al calificar restaurante: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en rateRestaurant: $e');
      throw Exception('Error al calificar restaurante: $e');
    }
  }

  // POST /api/buyer/reviews/delivery-agent - Calificar agente de delivery
  Future<Map<String, dynamic>> rateDeliveryAgent({
    required int agentId,
    required double rating,
    required String comment,
    Map<String, dynamic>? criteria,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/delivery-agent');
      
      final body = {
        'agent_id': agentId,
        'rating': rating,
        'comment': comment,
        if (criteria != null) 'criteria': criteria,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al calificar agente de delivery');
        }
      } else {
        throw Exception('Error al calificar agente de delivery: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en rateDeliveryAgent: $e');
      throw Exception('Error al calificar agente de delivery: $e');
    }
  }

  // GET /api/buyer/reviews/restaurant/{commerceId} - Obtener calificaciones de restaurante
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    int commerceId, {
    int? page,
    int? limit,
    String? sortBy,
    String? order,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (order != null) queryParams['order'] = order;

      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/restaurant/$commerceId')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          
          // Verificar si la respuesta es una lista
          if (responseData is List) {
            return List<Map<String, dynamic>>.from(responseData);
          }
          // Si es un Map, verificar si tiene una propiedad 'reviews' o similar
          else if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('reviews') && responseData['reviews'] is List) {
              return List<Map<String, dynamic>>.from(responseData['reviews']);
            }
            // Si no tiene 'reviews', devolver una lista vacía
            return [];
          }
          // Si no es ni List ni Map, devolver lista vacía
          return [];
        }
        return [];
      } else {
        throw Exception('Error al obtener calificaciones del restaurante: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getRestaurantReviews: $e');
      // En caso de error, devolver lista vacía en lugar de lanzar excepción
      return [];
    }
  }

  // GET /api/buyer/reviews/delivery-agent/{agentId} - Obtener calificaciones de agente de delivery
  Future<List<Map<String, dynamic>>> getDeliveryAgentReviews(
    int agentId, {
    int? page,
    int? limit,
    String? sortBy,
    String? order,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (order != null) queryParams['order'] = order;

      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/delivery-agent/$agentId')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener calificaciones del agente: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getDeliveryAgentReviews: $e');
      throw Exception('Error al obtener calificaciones del agente: $e');
    }
  }
} 