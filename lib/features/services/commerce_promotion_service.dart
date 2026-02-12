import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommercePromotionService {
  static String get baseUrl => AppConfig.apiUrl;
  static final Logger _logger = Logger();

  // Obtener todas las promociones del comercio
  static Future<List<Map<String, dynamic>>> getPromotions({
    String? status,
    String? type,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$baseUrl/api/commerce/promotions').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else if (response.statusCode == 404) {
        throw Exception('Error al obtener promociones: endpoint no disponible (404)');
      } else {
        throw Exception('Error al obtener promociones: ${response.statusCode}');
      }
    } catch (e) {
      _logger.w('Error al obtener promociones: $e');
      rethrow;
    }
  }

  // Obtener una promoción específica
  static Future<Map<String, dynamic>> getPromotion(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/promotions/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al obtener promoción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener promoción: $e');
    }
  }

  // Crear nueva promoción
  static Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/commerce/promotions'),
      );

      request.headers.addAll(headers);

      // Agregar campos de texto
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Agregar imagen si existe
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al crear promoción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear promoción: $e');
    }
  }

  // Actualizar promoción
  static Future<Map<String, dynamic>> updatePromotion(int id, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/commerce/promotions/$id'),
      );

      request.headers.addAll(headers);

      // Agregar método PUT
      request.fields['_method'] = 'PUT';

      // Agregar campos de texto
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Agregar imagen si existe
      if (imageFile != null) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al actualizar promoción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar promoción: $e');
    }
  }

  // Eliminar promoción
  static Future<void> deletePromotion(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/commerce/promotions/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar promoción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar promoción: $e');
    }
  }

  // Activar/desactivar promoción
  static Future<Map<String, dynamic>> togglePromotionStatus(int id) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/commerce/promotions/$id/toggle'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al cambiar estado de promoción: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cambiar estado de promoción: $e');
    }
  }

  // Obtener estadísticas de promociones
  static Future<Map<String, dynamic>> getPromotionStats() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commerce/promotions/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else if (response.statusCode == 404) {
        throw Exception('Error al obtener estadísticas de promociones: endpoint no disponible (404)');
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.w('Error al obtener estadísticas de promociones: $e');
      rethrow;
    }
  }

  // Obtener promociones activas
  static Future<List<Map<String, dynamic>>> getActivePromotions() async {
    return getPromotions(status: 'active');
  }

  // Obtener promociones inactivas
  static Future<List<Map<String, dynamic>>> getInactivePromotions() async {
    return getPromotions(status: 'inactive');
  }

  // Obtener promociones por tipo
  static Future<List<Map<String, dynamic>>> getPromotionsByType(String type) async {
    return getPromotions(type: type);
  }

  // Obtener promociones expiradas
  static Future<List<Map<String, dynamic>>> getExpiredPromotions() async {
    return getPromotions(status: 'expired');
  }

  // Obtener promociones próximas a expirar
  static Future<List<Map<String, dynamic>>> getExpiringSoonPromotions() async {
    return getPromotions(status: 'expiring_soon');
  }
}
