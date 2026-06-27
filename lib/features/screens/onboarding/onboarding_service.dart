import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:zonix_glasses/config/app_config.dart';

final logger = Logger();

class OnboardingService {
  final _storage = const FlutterSecureStorage();

  // Recuperar el token del almacenamiento seguro
  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token != null && token.isNotEmpty) {
      logger.d('Token de sesión presente (longitud: ${token.length})');
    }
    return token;
  }

  // Completar el proceso de onboarding del usuario
  Future<void> completeOnboarding(
    int userId, {
    String? role,
  }) async {
    final token = await _getToken();
    
    if (token == null) {
      logger.e("Token no encontrado. No se puede completar el onboarding.");
      throw Exception("Token no encontrado.");
    }
    
    try {
      // Marca completed_onboarding y, si se proporciona, actualiza el rol del usuario.
      final Map<String, dynamic> payload = {
        'completed_onboarding': true,
      };
      if (role != null && role.isNotEmpty) {
        payload['role'] = role;
      }
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/api/onboarding/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Manejo de éxito
        debugPrint("Onboarding completado con éxito.");
        logger.i("Onboarding completado con éxito.");
      } else {
        logger.e("Error al completar el onboarding: ${response.statusCode} - ${response.body}");
        String backendMessage = 'Error al completar el onboarding';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            backendMessage = (decoded['message'] ?? decoded['error'] ?? backendMessage).toString();
          }
        } catch (_) {}
        throw Exception("$backendMessage (${response.statusCode})");
      }
    } catch (e) {
      logger.e("Excepción al hacer la solicitud de onboarding: $e");
      rethrow;
    }
  }
}
