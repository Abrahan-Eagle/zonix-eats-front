import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final logger = Logger();
const FlutterSecureStorage _storage = FlutterSecureStorage(); // Inicializa _storage
final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;



class QrProfileApiService {

Future<String?> sendUserIdToBackend(int userId) async {
  logger.e('User ID enviado al backend: $userId');
  logger.e('Base URL: $baseUrl');

  final token = await _storage.read(key: 'token');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/qr-profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.containsKey('profileId')) {
        // Convertimos a String antes de devolver
        return data['profileId'].toString();
      } else {
        logger.e('Respuesta inesperada del backend: ${response.body}');
        return null;
      }
    } else {
      logger.e('Error al enviar ID de usuario al backend: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    logger.e('Error de solicitud HTTP: $e');
    return null;
  }
}


    
}
