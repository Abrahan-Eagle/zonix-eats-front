import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class OnboardingService {
  final _storage = const FlutterSecureStorage();

  // Recuperar el token del almacenamiento seguro
  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    logger.i('Token recuperado: $token');
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
      // Por ahora marcamos completed_onboarding en true y, si se proporciona,
      // también actualizamos el rol del usuario (users / commerce).
      final Map<String, dynamic> payload = {
        'completed_onboarding': true,
      };
      if (role != null && role.isNotEmpty) {
        payload['role'] = role;
      }
      final response = await http.put(
        Uri.parse('$baseUrl/api/onboarding/$userId'),
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
        // Manejo de error
        logger.e("Error al completar el onboarding: ${response.statusCode} - ${response.body}");
        throw Exception("Error al completar el onboarding: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Excepción al hacer la solicitud de onboarding: $e");
      throw Exception("Error en la solicitud de onboarding");
    }
  }
}
