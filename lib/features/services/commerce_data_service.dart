import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class CommerceDataService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  // static const String baseUrl = 'http://192.168.0.102:8000/api';

  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
final Logger _logger = Logger();

  // Obtener datos del comercio
  static Future<Map<String, dynamic>> getCommerceData() async {
     final headers = await AuthHelper.getAuthHeaders();

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/buyer/profiles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Buscar el perfil del usuario actual y su comercio asociado
        final userProfile = data.firstWhere(
          (profile) => profile['user_id'] != null,
          orElse: () => throw Exception('Perfil no encontrado'),
        );
        
        if (userProfile['commerce'] != null) {
          return userProfile['commerce'];
        } else {
          throw Exception('No se encontró comercio asociado');
        }
      } else {
        throw Exception('Error al obtener datos del comercio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener datos del comercio: $e');
    }
  }

  // Actualizar datos del comercio
  static Future<Map<String, dynamic>> updateCommerceData(Map<String, dynamic> data) async {
    try {
            // Primero obtener el perfil actual
      final profileResponse = await http.get(
        Uri.parse('$baseUrl/api/buyer/profiles'),
        headers: headers,
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Error al obtener perfil: ${profileResponse.statusCode}');
      }

      final profiles = jsonDecode(profileResponse.body);
      final userProfile = profiles.firstWhere(
        (profile) => profile['user_id'] != null,
        orElse: () => throw Exception('Perfil no encontrado'),
      );

      final profileId = userProfile['id'];
      
      // Actualizar el perfil con los datos del comercio
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/profiles/$profileId'),
        headers: headers,
        body: jsonEncode({
          'commerce': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Error al actualizar datos del comercio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar datos del comercio: $e');
    }
  }

  // Actualizar datos de pago móvil
  static Future<Map<String, dynamic>> updatePaymentData(Map<String, dynamic> data) async {
    try {

      // Primero obtener el perfil actual
      final profileResponse = await http.get(
        Uri.parse('$baseUrl/api/buyer/profiles'),
        headers: headers,
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Error al obtener perfil: ${profileResponse.statusCode}');
      }

      final profiles = jsonDecode(profileResponse.body);
      final userProfile = profiles.firstWhere(
        (profile) => profile['user_id'] != null,
        orElse: () => throw Exception('Perfil no encontrado'),
      );

      final profileId = userProfile['id'];
      
      // Actualizar solo los datos de pago móvil
      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/profiles/$profileId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'commerce': {
            'mobile_payment_bank': data['bank'],
            'mobile_payment_id': data['payment_id'],
            'mobile_payment_phone': data['payment_phone'],
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Error al actualizar datos de pago: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar datos de pago: $e');
    }
  }

  // Crear nuevo comercio
  static Future<Map<String, dynamic>> createCommerce(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/api/buyer/profiles/commerce'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Error al crear comercio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear comercio: $e');
    }
  }

  // Subir imagen del comercio
  static Future<String> uploadCommerceImage(String imagePath) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      // TODO: Implementar subida de imagen
      // Por ahora retornamos una URL mock
      await Future.delayed(const Duration(seconds: 1));
      return 'https://via.placeholder.com/300x300?text=Logo+Comercio';
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }
} 