import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class TestAuthService {
  // GET /api/test/auth - Probar autenticación
  static Future<Map<String, dynamic>> testAuth() async {
    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('${AppConfig.apiUrl}/api/test/auth');
      
      print('🔍 Probando autenticación en: $url');
      print('🔍 Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('🔍 Status code: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Autenticación exitosa: $data');
        return data;
      } else {
        print('❌ Error de autenticación: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        return {'error': 'Auth failed', 'status': response.statusCode, 'body': response.body};
      }
    } catch (e) {
      print('❌ Excepción en testAuth: $e');
      return {'error': 'Exception', 'message': e.toString()};
    }
  }
} 