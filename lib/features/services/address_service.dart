import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

class AddressService {
  final Logger _logger = Logger();

  // GET /api/buyer/addresses - Obtener direcciones del usuario
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener direcciones: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getUserAddresses: $e');
      throw Exception('Error al obtener direcciones: $e');
    }
  }

  // POST /api/buyer/addresses - Crear nueva dirección
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> addressData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(addressData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al crear dirección');
        }
      } else {
        throw Exception('Error al crear dirección: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en createAddress: $e');
      throw Exception('Error al crear dirección: $e');
    }
  }

  // PUT /api/buyer/addresses/{addressId} - Actualizar dirección
  Future<Map<String, dynamic>> updateAddress(int addressId, Map<String, dynamic> addressData) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses/$addressId');
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(addressData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Error al actualizar dirección');
        }
      } else {
        throw Exception('Error al actualizar dirección: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en updateAddress: $e');
      throw Exception('Error al actualizar dirección: $e');
    }
  }

  // DELETE /api/buyer/addresses/{addressId} - Eliminar dirección
  Future<bool> deleteAddress(int addressId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses/$addressId');
      
      final response = await http.delete(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Error al eliminar dirección: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en deleteAddress: $e');
      throw Exception('Error al eliminar dirección: $e');
    }
  }

  // POST /api/buyer/addresses/{addressId}/default - Establecer dirección por defecto
  Future<bool> setDefaultAddress(int addressId) async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses/$addressId/default');
      
      final response = await http.post(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Error al establecer dirección por defecto: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en setDefaultAddress: $e');
      throw Exception('Error al establecer dirección por defecto: $e');
    }
  }

  // GET /api/buyer/addresses/default - Obtener dirección por defecto
  Future<Map<String, dynamic>?> getDefaultAddress() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/api/buyer/addresses/default');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
        return null;
      } else {
        throw Exception('Error al obtener dirección por defecto: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error en getDefaultAddress: $e');
      throw Exception('Error al obtener dirección por defecto: $e');
    }
  }
} 