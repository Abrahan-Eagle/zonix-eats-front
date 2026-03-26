import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix/config/app_config.dart';

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage();

class ApiService {
  // Enviar el token al backend
  Future<http.Response> sendTokenToBackend(String? result) async {
    if (result == null) {
      logger.e('Error: el data es null');
      throw Exception('El data es null'); // Lanza una excepción
    }

    final decodedData = jsonDecode(result); // Decodificar el JSON

    try {
      final body = jsonEncode({
        'success': true,
        'token': decodedData['token'],
        'data': decodedData['profile'],
        'message': 'Datos recibidos correctamente.',
      });

      final response = await http.post(
      Uri.parse( '${AppConfig.apiUrl}/api/auth/google'), // Cambia por la URL de tu backend
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'flutter/1.0',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // No registrar token ni cuerpo completo (riesgo en logs / adb)
        
        // Handle the nested response structure: {success: true, data: {user: {...}, token: ...}}
        Map<String, dynamic> userData;
        String? token;
        
        if (responseData.containsKey('success') && responseData.containsKey('data')) {
          // New format: {success: true, data: {user: {...}, token: ...}}
          userData = responseData['data']['user'] ?? {};
          token = responseData['data']['token'] ?? responseData['token'];
        } else {
          // Fallback to old format: {user: {...}, token: ...}
          userData = responseData['user'] ?? {};
          token = responseData['token'];
        }
        
        final authToken = token;
        final role = userData['role'];
        final completedOnboarding = userData['completed_onboarding']?.toString();

        if (authToken != null) {
          await _storage.write(key: 'token', value: authToken);
          await _storage.write(key: 'role', value: role);
          await _storage.write(key: 'userCompletedOnboarding', value: completedOnboarding);

          logger.i(
            'Inicio de sesión exitoso (user id: ${userData['id']}, role: $role)',
          );

          final storedToken = await _storage.read(key: 'token');
          if (storedToken == null) {
            logger.e('No se encontró ningún token almacenado');
          }

          final storedRole = await _storage.read(key: 'role');
          if (storedRole == null) {
            logger.e('No se encontró ningún role almacenado');
          }

          final storedOnboarding =
              (await _storage.read(key: 'userCompletedOnboarding')) == '1';
          logger.i('Estado de completedOnboarding almacenado: $storedOnboarding');
        } else {
          logger.e('Respuesta inesperada: sin token (status 200)');
        }
      } else {
        logger.e('Error al iniciar sesión en Laravel: ${response.statusCode}');
      }

      return response; // Devuelve la respuesta
    } catch (error) {
      logger.e('Error: $error');
      throw Exception('Error en el envío de datos: $error'); // Lanza una excepción
    }
  }

  // Método para cerrar sesión
  Future<http.Response> logout(String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/auth/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Método para enviar una solicitud autenticada
  Future<void> sendAuthenticatedRequest() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/auth/protected-endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        logger.i('Solicitud autenticada OK (${response.statusCode})');
      } else if (response.statusCode == 401) {
        logger.e("Token expirado o inválido, redirigiendo a login");
        // Elimina el token almacenado y redirige al login
        await _storage.deleteAll();
        // Aquí puedes redirigir automáticamente al login
      } else {
        logger.e("Error en la solicitud: ${response.statusCode}");
      }
    } else {
      logger.e("No hay token almacenado");
    }
  }
}
