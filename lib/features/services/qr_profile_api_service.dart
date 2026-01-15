import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

final logger = Logger();
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;



class QrProfileApiService {

Future<String?> sendUserIdToBackend(int userId) async {
  logger.i('User ID enviado al backend: $userId');
  logger.i('Base URL: $baseUrl');

  try {
    final headers = await AuthHelper.getAuthHeaders();
    // Verificar primero si el endpoint existe, si no, usar un endpoint alternativo
    final response = await http.get(
      Uri.parse('$baseUrl/api/profiles/$userId/qr'),
      headers: headers,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout al obtener perfil QR');
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null) {
        // Intentar diferentes formatos de respuesta
        if (data.containsKey('profileId')) {
          return data['profileId'].toString();
        } else if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('profileId')) {
          return data['data']['profileId'].toString();
        } else if (data.containsKey('id')) {
          return data['id'].toString();
        } else {
          logger.w('Respuesta inesperada del backend: ${response.body}');
          return null;
        }
      } else {
        logger.w('Respuesta vacía del backend');
        return null;
      }
    } else if (response.statusCode == 404) {
      // Endpoint no existe, retornar null sin error crítico
      logger.w('Endpoint QR profile no disponible (404)');
      return null;
    } else {
      logger.w('Error al enviar ID de usuario al backend: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    // No lanzar error crítico, solo loggear
    logger.w('Error de solicitud HTTP: $e');
    return null;
  }
}

  Future<Map<String, dynamic>> fetchProfileByQr(String qrCode) async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/api/buyer/profiles/$qrCode'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener perfil por QR');
    }
  }
}
