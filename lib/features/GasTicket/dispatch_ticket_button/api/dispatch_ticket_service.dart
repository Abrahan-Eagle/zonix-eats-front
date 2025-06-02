import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final logger = Logger();

final String baseUrl = const bool.fromEnvironment('dart.vm.product')
    ? dotenv.env['API_URL_PROD']!
    : dotenv.env['API_URL_LOCAL']!;

class ApiService {
  final String apiUrl = '$baseUrl/api/dispatch/tickets';  // Endpoint base para despacho de tickets
  final storage = const FlutterSecureStorage();

  // Método para recuperar el token almacenado
  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }



// Escanear cilindro
Future<Map<String, dynamic>> scanCylinder(String qrCodeId) async {
  logger.i('Escaneando cilindro: $qrCodeId');
  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no encontrado. Por favor, inicia sesión.');
  }

  final response = await http.post(
    Uri.parse('$apiUrl/$qrCodeId/qr-code'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    logger.i('Respuesta del cilindro: ${response.body}');
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al procesar la respuesta del servidor: $e');
    }
  } else {
    throw Exception('Error al procesar el cilindro: ${response.statusCode} ${response.body}');
  }
}


// Escanear cilindro
Future<Map<String, dynamic>> scanCylinderAdminSale(String qrCodeId) async {
  logger.i('Escaneando cilindro: $qrCodeId');
  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no encontrado. Por favor, inicia sesión.');
  }

  final response = await http.post(
    Uri.parse('$apiUrl/$qrCodeId/qr-code-gas-cylinder-admin-sale'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    logger.i('Respuesta del cilindro: ${response.body}');
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al procesar la respuesta del servidor: $e');
    }
  } else {
    throw Exception('Error al procesar el cilindro: ${response.statusCode} ${response.body}');
  }
}


  // Despachar ticket
  Future<Map<String, dynamic>> dispatchTicket(int id) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no encontrado. Por favor, inicia sesión.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/$id/dispatch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Error al procesar la respuesta del servidor: $e');
      }
    } else {
      throw Exception('Error al despachar ticket (${response.statusCode}): ${response.body}');
    }
  }
}
