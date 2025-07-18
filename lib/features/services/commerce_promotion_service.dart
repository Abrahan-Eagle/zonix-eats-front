import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommercePromotionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String get baseUrl => AppConfig.apiUrl;
  static final Logger _logger = Logger();

  // Datos mock para cuando el backend no esté disponible
  static List<Map<String, dynamic>> get _mockPromotions => [
    {
      'id': 1,
      'title': 'Descuento 20% en Pizzas',
      'description': 'Obtén 20% de descuento en todas las pizzas',
      'discount_type': 'percentage',
      'discount_value': 20.0,
      'status': 'active',
      'start_date': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      'end_date': DateTime.now().add(Duration(days: 10)).toIso8601String(),
      'image': 'assets/default_avatar.png',
      'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
    },
    {
      'id': 2,
      'title': '2x1 en Hamburguesas',
      'description': 'Lleva dos hamburguesas por el precio de una',
      'discount_type': 'buy_one_get_one',
      'discount_value': 50.0,
      'status': 'active',
      'start_date': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      'end_date': DateTime.now().add(Duration(days: 15)).toIso8601String(),
      'image': 'assets/default_avatar.png',
      'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 3,
      'title': 'Envío Gratis',
      'description': 'Envío gratis en pedidos superiores a \$30',
      'discount_type': 'free_shipping',
      'discount_value': 5.0,
      'status': 'inactive',
      'start_date': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
      'end_date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'image': 'assets/default_avatar.png',
      'created_at': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
    },
  ];

  static Map<String, dynamic> get _mockStats => {
    'total_promotions': 3,
    'active_promotions': 2,
    'inactive_promotions': 1,
    'expired_promotions': 0,
    'total_revenue': 1500.0,
    'promotions_revenue': 300.0,
  };

  // Obtener todas las promociones del comercio
  static Future<List<Map<String, dynamic>>> getPromotions({
    String? status,
    String? type,
    String? sortBy,
    String? sortOrder,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('${baseUrl}/commerce/promotions').replace(queryParameters: queryParams);
      
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
        _logger.w('Endpoint de promociones no encontrado (404), usando datos mock');
        return _mockPromotions;
      } else {
        throw Exception('Error al obtener promociones: ${response.statusCode}');
      }
    } catch (e) {
      _logger.w('Error al obtener promociones, usando datos mock: $e');
      return _mockPromotions;
    }
  }

  // Obtener una promoción específica
  static Future<Map<String, dynamic>> getPromotion(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/promotions/$id'),
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/commerce/promotions'),
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/commerce/promotions/$id'),
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/commerce/promotions/$id'),
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/commerce/promotions/$id/toggle'),
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
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/promotions/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else if (response.statusCode == 404) {
        _logger.w('Endpoint de estadísticas de promociones no encontrado (404), usando datos mock');
        return _mockStats;
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      _logger.w('Error al obtener estadísticas de promociones, usando datos mock: $e');
      return _mockStats;
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