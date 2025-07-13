import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class ReviewService {
  // POST /api/buyer/reviews - Crear review
  Future<Map<String, dynamic>> createReview(Map<String, dynamic> reviewData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews');
      final response = await http.post(
        url,
        body: jsonEncode(reviewData),
        headers: headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al crear review');
        }
      } else {
        throw Exception('Error al crear review: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear review: $e');
    }
  }

  // GET /api/buyer/reviews/{reviewableId}/{reviewableType} - Listar reviews
  Future<List<Map<String, dynamic>>> getReviews(int reviewableId, String reviewableType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/$reviewableId/$reviewableType');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener reviews');
      }
    } else {
      throw Exception('Error al obtener reviews: ${response.statusCode}');
    }
  }

  // PUT /api/buyer/reviews/{reviewId} - Actualizar review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    double? rating,
    String? comment,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/$reviewId');
    
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;
    
    final response = await http.put(
      url,
      body: jsonEncode(body),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Error al actualizar review');
      }
    } else {
      throw Exception('Error al actualizar review: ${response.statusCode}');
    }
  }

  // DELETE /api/buyer/reviews/{reviewId} - Eliminar review
  Future<void> deleteReview(int reviewId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/$reviewId');
    final response = await http.delete(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Error al eliminar review');
      }
    } else {
      throw Exception('Error al eliminar review: ${response.statusCode}');
    }
  }

  // GET /api/buyer/reviews/{reviewableId}/{reviewableType}/can-review - Verificar si puede calificar
  Future<bool> canReview(int reviewableId, String reviewableType) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/reviews/$reviewableId/$reviewableType/can-review');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']?['can_review'] ?? false;
      } else {
        throw Exception(data['message'] ?? 'Error al verificar si puede calificar');
      }
    } else {
      throw Exception('Error al verificar si puede calificar: ${response.statusCode}');
    }
  }
} 