import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../helpers/auth_helper.dart';
import '../../config/app_config.dart';

class PostService {
  // GET /api/buyer/posts - Listar posts
  Future<List<Map<String, dynamic>>> getPosts() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/posts');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener posts');
      }
    } else {
      throw Exception('Error al obtener posts: ${response.statusCode}');
    }
  }

  // GET /api/buyer/posts/{id} - Obtener detalle de post
  Future<Map<String, dynamic>> getPostById(int postId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/posts/$postId');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Error al obtener el post');
      }
    } else {
      throw Exception('Error al obtener el post: ${response.statusCode}');
    }
  }

  // POST /api/buyer/posts/{id}/favorite - Marcar/desmarcar favorito
  Future<bool> toggleFavorite(int postId) async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/posts/$postId/favorite');
    final response = await http.post(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']?['is_favorite'] ?? false;
      } else {
        throw Exception(data['message'] ?? 'Error al marcar favorito');
      }
    } else {
      throw Exception('Error al marcar favorito: ${response.statusCode}');
    }
  }

  // GET /api/buyer/favorites - Listar favoritos
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final headers = await AuthHelper.getAuthHeaders();
    final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/favorites');
    final response = await http.get(
      url,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error al obtener favoritos');
      }
    } else {
      throw Exception('Error al obtener favoritos: ${response.statusCode}');
    }
  }
} 