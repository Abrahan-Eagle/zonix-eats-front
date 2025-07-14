import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';

class AccountDeletionService {
  static const String baseUrl = 'http://localhost:8000/api';

  // Solicitar eliminación de cuenta
  static Future<Map<String, dynamic>> requestAccountDeletion({
    String? reason,
    String? feedback,
    bool? immediate = false,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/request-deletion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reason': reason,
          'feedback': feedback,
          'immediate': immediate,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al solicitar eliminación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Confirmar eliminación de cuenta
  static Future<Map<String, dynamic>> confirmAccountDeletion({
    required String confirmationCode,
    required String password,
  }) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/confirm-deletion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'confirmation_code': confirmationCode,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al confirmar eliminación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Cancelar solicitud de eliminación
  static Future<Map<String, dynamic>> cancelDeletionRequest() async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/user/cancel-deletion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cancelar eliminación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estado de la solicitud de eliminación
  static Future<Map<String, dynamic>> getDeletionStatus() async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/deletion-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
} 