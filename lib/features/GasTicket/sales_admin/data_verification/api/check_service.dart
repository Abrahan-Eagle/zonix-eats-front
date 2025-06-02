import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class ApiService {
  final String apiUrl = '$baseUrl/api/data-verification';
  final storage = const FlutterSecureStorage();
  final logger = Logger();

  Future<String?> _getToken() async {
    try {
      return await storage.read(key: 'token');
    } catch (e) {
      logger.e('Error al recuperar el token: $e');
      throw Exception('Error al recuperar el token: $e');
    }
  }

  Future<Map<String, dynamic>> verifyCheck(int profileId) async {
    String? token = await _getToken();
    if (token == null) {
      logger.e('Token no encontrado');
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    final uri = Uri.parse('$apiUrl/$profileId');
    logger.i('Enviando solicitud GET a $uri con token: $token');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i('Respuesta recibida: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        logger.w('Solicitud inválida: ${response.body}');
        throw Exception('Solicitud inválida: ${response.body}');
      } else if (response.statusCode == 404) {
        logger.w('Este usuario ya tiene todos sus datos actualizados. No hay información adicional para procesar.');
        throw Exception('Este usuario ya tiene todos sus datos actualizados. No hay información adicional para procesar.');
      } else if (response.statusCode >= 500) {
        logger.e('Error en el servidor: ${response.statusCode} - ${response.reasonPhrase}');
        throw Exception('Error en el servidor: ${response.statusCode} - ${response.reasonPhrase}');
      } else {
        logger.e('Error inesperado: ${response.statusCode}');
        throw Exception('Error inesperado: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error de conexión: $e');
      throw Exception('Error de conexión: $e');
    }
  }



Future<List<Map<String, dynamic>>> fetchStations(int userId) async {
   String? token = await _getToken();
   
    final response = await http.get(
      Uri.parse('$apiUrl/getGasCylinders/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load gas cylinders');
    }
  }



}
