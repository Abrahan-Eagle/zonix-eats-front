import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class TestAuthService {
  static final Logger _logger = Logger();

  // GET /api/test/auth - Probar autenticación
  static Future<Map<String, dynamic>> testAuth() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/test/auth');

      _logger.d('Probando autenticación en: $url');
      _logger.d('Headers: $headers');

      final response = await http.get(url, headers: headers);

      _logger.d('Status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Autenticación exitosa: $data');
        return data;
      } else {
        _logger.w('Error de autenticación: ${response.statusCode}');
        _logger.w('Error body: ${response.body}');
        return {'error': 'Auth failed', 'status': response.statusCode, 'body': response.body};
      }
    } catch (e) {
      _logger.e('Excepción en testAuth: $e');
      return {'error': 'Exception', 'message': e.toString()};
    }
  }
} 