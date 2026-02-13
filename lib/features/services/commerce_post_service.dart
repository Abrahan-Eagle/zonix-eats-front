import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zonix/config/app_config.dart';
import 'package:zonix/helpers/auth_helper.dart';

/// Servicio para obtener publicaciones/posts de los comercios del usuario.
class CommercePostService {
  static String get baseUrl => AppConfig.apiUrl;

  /// GET /api/commerce/posts - Listar posts de los comercios del perfil
  static Future<List<Map<String, dynamic>>> getMyPosts() async {
    final headers = await AuthHelper.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/commerce/posts'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(
          (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    }
    throw Exception('Error al obtener publicaciones: ${response.statusCode}');
  }
}
