import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class CommerceDeliveryZoneService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String get baseUrl => AppConfig.apiUrl;

  // Obtener todas las zonas de delivery del comercio
  static Future<List<Map<String, dynamic>>> getDeliveryZones({
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$baseUrl/commerce/delivery-zones').replace(queryParameters: queryParams);
      
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
      } else {
        throw Exception('Error al obtener zonas de delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener zonas de delivery: $e');
    }
  }

  // Obtener una zona específica
  static Future<Map<String, dynamic>> getDeliveryZone(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/delivery-zones/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al obtener zona de delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener zona de delivery: $e');
    }
  }

  // Crear nueva zona de delivery
  static Future<Map<String, dynamic>> createDeliveryZone(Map<String, dynamic> data) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/commerce/delivery-zones'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al crear zona de delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear zona de delivery: $e');
    }
  }

  // Actualizar zona de delivery
  static Future<Map<String, dynamic>> updateDeliveryZone(int id, Map<String, dynamic> data) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/commerce/delivery-zones/$id'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al actualizar zona de delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar zona de delivery: $e');
    }
  }

  // Eliminar zona de delivery
  static Future<void> deleteDeliveryZone(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/commerce/delivery-zones/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar zona de delivery: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar zona de delivery: $e');
    }
  }

  // Activar/desactivar zona de delivery
  static Future<Map<String, dynamic>> toggleDeliveryZoneStatus(int id) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/commerce/delivery-zones/$id/toggle'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al cambiar estado de zona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cambiar estado de zona: $e');
    }
  }

  // Obtener estadísticas de zonas de delivery
  static Future<Map<String, dynamic>> getDeliveryZoneStats() async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/delivery-zones/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Verificar si una dirección está en zona de delivery
  static Future<Map<String, dynamic>> checkDeliveryZone(double lat, double lng) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/commerce/delivery-zones/check'),
        headers: headers,
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al verificar zona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al verificar zona: $e');
    }
  }

  // Calcular tarifa de delivery para una dirección
  static Future<Map<String, dynamic>> calculateDeliveryFee(double lat, double lng) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/commerce/delivery-zones/calculate-fee'),
        headers: headers,
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Error al calcular tarifa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al calcular tarifa: $e');
    }
  }

  // Obtener zonas activas
  static Future<List<Map<String, dynamic>>> getActiveDeliveryZones() async {
    return getDeliveryZones(status: 'active');
  }

  // Obtener zonas inactivas
  static Future<List<Map<String, dynamic>>> getInactiveDeliveryZones() async {
    return getDeliveryZones(status: 'inactive');
  }

  // Obtener zonas por radio
  static Future<List<Map<String, dynamic>>> getDeliveryZonesByRadius(double radius) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/delivery-zones?radius=$radius'),
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
      } else {
        throw Exception('Error al obtener zonas por radio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener zonas por radio: $e');
    }
  }

  // Obtener zonas por tarifa
  static Future<List<Map<String, dynamic>>> getDeliveryZonesByFee(double minFee, double maxFee) async {
    final headers = await AuthHelper.getAuthHeaders();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/commerce/delivery-zones?min_fee=$minFee&max_fee=$maxFee'),
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
      } else {
        throw Exception('Error al obtener zonas por tarifa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener zonas por tarifa: $e');
    }
  }
} 